# report.jl — the finished vault, rendered twice: an HTML gallery for a human and an
# `agent.json` for an LLM. `Pinax.report` discovers the `:done` keys, loads each payload and
# hands the `(DataKey, Dict)` pairs to `recipe`; only `recipe` is this project's.
#
#     julia --project=report report/report.jl configs/production.toml

using DataVault: DataVault
using ExampleMonteCarlo: ExampleMonteCarlo
using ParamIO: ParamIO   # also a PinaxDataVaultExt trigger; without it `Pinax.report` is a stub
using Pinax
using Plots

ENV["GKSwstype"] = get(ENV, "GKSwstype", "100")   # headless GR: renders with no display attached
gr()

const CONFIG = get(ARGS, 1, joinpath(@__DIR__, "..", "configs", "smoke.toml"))
const TC = 2 / log(1 + sqrt(2))                   # the exact 2D Ising transition, kbT/J ≈ 2.269

vault = DataVault.Vault(CONFIG; run="phase1")

"""
    recipe(pairs)

Build the document. `summarise` is `../src/ExampleMonteCarlo.jl`'s, so this and
`scripts/collect.jl` cannot report different numbers.
"""
function recipe(pairs)
    rows = ExampleMonteCarlo.summarise(pairs)

    binder = plot(; xlabel="kbT / J", ylabel="Binder cumulant U₄", legend=:bottomleft)
    mag = plot(; xlabel="kbT / J", ylabel="|magnetization| per spin", legend=:topright)
    for L in sort(unique(r.L for r in rows))
        sel = filter(r -> r.L == L, rows)
        Ts = sort(unique(r.kbT for r in sel))
        # one point per swept `kbT`, so `total_samples > 1` averages the chains rather than overplots
        avg(f) = [(v=[f(r) for r in sel if r.kbT == T]; sum(v) / length(v)) for T in Ts]
        plot!(binder, Ts, avg(r -> r.binder); marker=:circle, label="L = $L")
        plot!(mag, Ts, avg(r -> r.magnetization); marker=:circle, label="L = $L")
    end
    # both labelled: an unlabelled series reaches `agent.json` as a nameless row
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
