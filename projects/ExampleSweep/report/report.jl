# Draw from the finished vault. Run with `--project=report`, never the compute env —
# that is the whole reason the two environments are separate.
#
#     julia --project=report report/report.jl configs/smoke.toml

using DataVault, ExampleSweep, ParamIO

const CONFIG = get(ARGS, 1, joinpath(@__DIR__, "..", "configs", "smoke.toml"))
const OUTDIR = get(ENV, "DATAVAULT_OUTDIR", joinpath(@__DIR__, "..", "out"))

vault = DataVault.Vault(CONFIG; run="phase1", outdir=OUTDIR)
rows = ExampleSweep.summarise(vault)          # the same reduction scripts/collect.jl uses

@info "reporting over" n = length(rows)
# Draw here — Pinax and a plotting backend are dependencies of THIS environment.
