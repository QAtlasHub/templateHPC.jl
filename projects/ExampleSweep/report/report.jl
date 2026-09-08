# Draw from the finished vault. Run with `--project=report`, never the compute env.
#
#     julia --project=report report/report.jl out
using DataVault, ExampleSweep

vault = DataVault.Vault(get(ARGS, 1, "out"))
s = ExampleSweep.summarise(vault)          # the same reduction scripts/collect.jl uses
@info "reporting over" s...
