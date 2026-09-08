# Draw the sweep. Run with `--project=report`, never the compute env.
#
#     julia --project=report report/report.jl configs/production.toml

using DataVault: DataVault
using ExampleMonteCarlo: ExampleMonteCarlo
using ParamIO: ParamIO

const CONFIG = get(ARGS, 1, joinpath(@__DIR__, "..", "configs", "smoke.toml"))
const OUTDIR = get(ENV, "DATAVAULT_OUTDIR", joinpath(@__DIR__, "..", "out"))

vault = DataVault.Vault(CONFIG; run="phase1", outdir=OUTDIR)
rows = ExampleMonteCarlo.summarise(vault)      # the same reduction scripts/collect.jl uses

@info "reporting over" n = length(rows)
# The Binder cumulant's crossing in L is where the transition shows up — draw it here, with Plots,
# which is a dependency of THIS environment and of nothing that runs on a compute node.
