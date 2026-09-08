# The reader side. `compute.jl` never called save! — the runtime persisted every
# work_fn return for us. No plotting dependency, so this runs where the compute did.
#
#     julia --project=. scripts/collect.jl configs/smoke.toml

using DataVault, ExampleSweep, ParamIO, Printf

const CONFIG = get(ARGS, 1, joinpath(@__DIR__, "..", "configs", "smoke.toml"))
const OUTDIR = get(ENV, "DATAVAULT_OUTDIR", joinpath(@__DIR__, "..", "out"))

vault = DataVault.Vault(CONFIG; run="phase1", outdir=OUTDIR)
rows = ExampleSweep.summarise(vault)          # the same reduction report/ uses

@printf("\n  %-8s %-10s %s\n", "a", "dt", "rel_error")
println("  ─────────────────────────────────────")
for r in rows
    @printf("  %-8.4g %-10.4g %.3e\n", r.a, r.dt, r.rel_error)
end
@printf("\n  %d points\n\n", length(rows))
