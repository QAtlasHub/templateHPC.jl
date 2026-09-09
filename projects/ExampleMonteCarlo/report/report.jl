#==============================================================================
 report.jl — the vault → figures driver. Run with `--project=report`, never the compute env.

     julia --project=report report/report.jl configs/production.toml

 `Pinax.report(vault, recipe)` is the seam, and it lives in `PinaxDataVaultExt` — an extension that
 loads only when Pinax, DataVault and ParamIO are all present. That is why report/Project.toml
 declares ParamIO even though DataVault would pull it in regardless; without the extension the core
 `Pinax.report` is an error stub, so a missing dependency surfaces as a message about DataVault
 rather than as a MethodError.

 The driver is project-independent — discover the `:done` keys, load each payload, hand the
 `(DataKey, Dict)` pairs to `recipe`, render the human gallery and agent.json with the vault wired
 in. Only `recipe` is this project's.
==============================================================================#

using DataVault: DataVault
using ExampleMonteCarlo: ExampleMonteCarlo
using ParamIO: ParamIO
using Pinax
using Plots

ENV["GKSwstype"] = get(ENV, "GKSwstype", "100")   # headless GR: renders with no display attached
gr()

const CONFIG = get(ARGS, 1, joinpath(@__DIR__, "..", "configs", "smoke.toml"))
const TC = 2 / log(1 + sqrt(2))                   # the exact 2D Ising transition, kbT/J ≈ 2.269

vault = DataVault.Vault(CONFIG; run="phase1")

"""
    recipe(pairs)

Build the document from `(DataKey, Dict)` pairs. `summarise` is `../src/ExampleMonteCarlo.jl`'s —
the same reduction `scripts/collect.jl` prints as a table.
"""
function recipe(pairs)
    rows = ExampleMonteCarlo.summarise(pairs)

    binder = plot(; xlabel="kbT / J", ylabel="Binder cumulant U₄", legend=:bottomleft)
    mag = plot(; xlabel="kbT / J", ylabel="|magnetization| per spin", legend=:topright)
    for L in sort(unique(r.L for r in rows))
        sel = filter(r -> r.L == L, rows)
        Ts = sort(unique(r.kbT for r in sel))
        # `total_samples > 1` puts several independent chains behind one (L, kbT); average them.
        avg(f) = [(v=[f(r) for r in sel if r.kbT == T]; sum(v) / length(v)) for T in Ts]
        plot!(binder, Ts, avg(r -> r.binder); marker=:circle, label="L = $L")
        plot!(mag, Ts, avg(r -> r.magnetization); marker=:circle, label="L = $L")
    end
    # Both get the label, not just the first: an unlabelled series reaches `agent.json` as a
    # nameless row, and the machine-readable face is half of what Pinax is for.
    vline!(binder, [TC]; ls=:dash, c=:red, label="exact Tc")
    vline!(mag, [TC]; ls=:dash, c=:red, label="exact Tc")

    @page :ising "ExampleMonteCarlo — 2D Ising on a square lattice" summary = "A Metropolis sweep over lattice size and temperature, read back out of the vault." begin
        @section :binder "Binder cumulant" begin
            @desc md"""
            $U_4$ is dimensionless at the critical point, so the curves for different $L$ cross
            there and the crossing locates $T_c$ without an extrapolation. The dashed line is the
            exact $k_BT/J = 2/\ln(1+\sqrt{2}) \approx 2.269$ — it is a check on the sweep, not an
            output of it. A single $L$ draws one curve and no crossing; that needs `production.toml`.
            """
            @figure binder caption = "One curve per lattice size; they should meet at the dashed line."
        end
        @section :mag "Order parameter" begin
            @desc md"The magnetisation falls through the transition, and the fall sharpens with $L$ — the finite-size rounding is the thing the sweep is measuring."
            @figure mag caption = "|m| per spin against temperature."
        end
        @section :table "The points themselves" begin
            @desc md"The same rows `scripts/collect.jl` prints, so what an LLM reads out of `agent.json` is what the cluster printed."
            @table (
                L=[r.L for r in rows],
                kbT=[r.kbT for r in rows],
                energy=[r.energy for r in rows],
                magnetization=[r.magnetization for r in rows],
                binder=[r.binder for r in rows],
            ) caption = "Every finished point."
        end
    end
end

res = Pinax.report(
    vault,
    recipe;
    title="ExampleMonteCarlo",
    out=joinpath(vault.outdir, "report"),
    study="phase1",
)

@info "report written" n = res.n gallery = res.gallery agent = res.agent
