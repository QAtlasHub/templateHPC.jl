#==============================================================================
 report.jl — the vault → figures driver. Run with `--project=report`, never the
 compute env; that separation is the whole reason `report/` has its own manifest.

     julia --project=report report/report.jl configs/production.toml

 `Pinax.report(vault, recipe)` is the seam. It lives in `PinaxDataVaultExt`, an
 extension that loads when Pinax, DataVault and ParamIO are all present — which
 is why report/Project.toml declares ParamIO even though DataVault would drag it
 in anyway. Without the extension the core `Pinax.report` is an error stub, so a
 missing dependency shows up as a message about DataVault, not as a MethodError.

 The DRIVER is project-independent: discover the vault's `:done` keys, load each
 payload, hand the `(DataKey, Dict)` pairs to `recipe`, render the gallery (for a
 human) and agent.json (for an LLM) with the vault wired in, so the figure cache
 tracks each key's `.done` fingerprint and provenance is recorded. Only `recipe`
 below is yours.
==============================================================================#

using DataVault: DataVault
using ExampleSweep: ExampleSweep
using ParamIO: ParamIO
using Pinax
using Plots

ENV["GKSwstype"] = get(ENV, "GKSwstype", "100")   # headless GR: renders with no display attached
gr()

const CONFIG = get(ARGS, 1, joinpath(@__DIR__, "..", "configs", "smoke.toml"))

vault = DataVault.Vault(CONFIG; run="phase1")

"""
    recipe(pairs)

Build the document from `(DataKey, Dict)` pairs. This is the project-specific half;
everything around it is the same in every project.

`summarise` is `../src/ExampleSweep.jl`'s — the same function `scripts/collect.jl`
prints, so the figure and the cluster's table cannot drift apart.
"""
function recipe(pairs)
    rows = ExampleSweep.summarise(pairs)

    fig = plot(;
        xscale=:log10,
        yscale=:log10,
        xlabel="step size dt",
        ylabel="relative error at t = 1",
        legend=:bottomright,
    )
    for a in sort(unique(r.a for r in rows))
        sel = filter(r -> r.a == a, rows)
        dts = sort(unique(r.dt for r in sel))
        # `total_samples > 1` puts several samples behind one (a, dt); average within the key
        # rather than drawing each one, so the curve has one point per swept value.
        errs = [
            (v=[r.rel_error for r in sel if r.dt == d]; sum(v) / length(v)) for d in dts
        ]
        plot!(fig, dts, errs; marker=:circle, label="a = $a")
    end

    @page :convergence "ExampleSweep — explicit Euler on x' = -a x" summary = "Relative error of the placeholder kernel against its exact solution, over the swept step size." begin
        @section :rate "Error vs step size" begin
            @desc md"""
            Explicit Euler is first order, so on these log axes each curve should approach slope 1:
            halving `dt` halves the error. A curve that flattens has hit round-off rather than
            discretisation, and one that steepens is a bug — this figure is what tells them apart.
            """
            @figure fig caption = "One curve per decay rate `a`; each point is one swept `dt`."
        end
        @section :table "The points themselves" begin
            @desc md"The same rows `scripts/collect.jl` prints, so the number an LLM reads out of `agent.json` is the number on the cluster's stdout."
            @table (
                a=[r.a for r in rows],
                dt=[r.dt for r in rows],
                rel_error=[r.rel_error for r in rows],
            ) caption = "Every finished point."
        end
    end
end

res = Pinax.report(
    vault,
    recipe;
    title="ExampleSweep",
    out=joinpath(vault.outdir, "report"),
    study="phase1",
)

@info "report written" n = res.n gallery = res.gallery agent = res.agent
