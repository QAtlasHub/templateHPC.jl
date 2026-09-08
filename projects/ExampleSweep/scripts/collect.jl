# Read the finished vault and report it as text. No plotting dependency, so this
# can run on the machine that did the compute.
#
#     julia --project=. scripts/collect.jl out
using DataVault, ExampleSweep

vault = DataVault.Vault(get(ARGS, 1, "out"))
s = ExampleSweep.summarise(vault)          # the same reduction report/report.jl uses
@info "collected" s...
