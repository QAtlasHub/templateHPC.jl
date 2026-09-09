# report.jl — the finished vault, rendered twice: an HTML gallery for a human and an
# `agent.json` for an LLM. `Pinax.report` discovers the `:done` keys, loads each payload and
# hands the `(DataKey, Dict)` pairs to `recipe`; only `recipe` is this project's.
#
#     julia --project=report report/report.jl configs/production.toml

using DataVault: DataVault
using ExampleSweep: ExampleSweep
using ParamIO: ParamIO   # also a PinaxDataVaultExt trigger; without it `Pinax.report` is a stub
using Pinax
using Plots

ENV["GKSwstype"] = get(ENV, "GKSwstype", "100")   # headless GR: renders with no display attached
gr()

const CONFIG = get(ARGS, 1, joinpath(@__DIR__, "..", "configs", "smoke.toml"))

vault = DataVault.Vault(CONFIG; run="phase1")

"""
    recipe(pairs)

Build the document. `summarise` is `../src/ExampleSweep.jl`'s, so this and
`scripts/collect.jl` cannot report different numbers.
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
        # one point per swept `dt`, so `total_samples > 1` averages rather than overplots
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
