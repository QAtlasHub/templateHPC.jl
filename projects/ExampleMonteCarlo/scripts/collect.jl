# The reader side. No plotting dependency, so it runs where the compute did.
#
#     julia --project=. scripts/collect.jl configs/smoke.toml

using DataVault: DataVault
using ExampleMonteCarlo: ExampleMonteCarlo
using ParamIO: ParamIO
using Printf

const CONFIG = get(ARGS, 1, joinpath(@__DIR__, "..", "configs", "smoke.toml"))

vault = DataVault.Vault(CONFIG; run="phase1")
rows = ExampleMonteCarlo.summarise(vault)

@printf("\n  %-5s %-7s %-11s %-11s %s\n", "L", "kbT", "E/N", "|M|", "Binder")
println("  ────────────────────────────────────────────────────")
for r in rows
    @printf(
        "  %-5d %-7.3f %-11.5f %-11.5f %.4f\n",
        r.L,
        r.kbT,
        r.energy,
        r.magnetization,
        r.binder
    )
end
@printf("\n  %d points\n\n", length(rows))
