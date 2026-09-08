# One entry point for every size of run. `julia --project=. scripts/compute.jl configs/smoke.toml`
#
# What SweepRunner adds over a `for` loop: a point already finished is skipped
# after one manifest read, two processes pointed at the same vault never compute
# the same point twice, and a killed run is continued rather than restarted.

using DataVault
using MyModule
using ParamIO
using SweepRunner

config = get(ARGS, 1, "configs/smoke.toml")
spec   = ParamIO.load(config)
vault  = DataVault.Vault(spec["run"]["out"])
keys   = ParamIO.enumerate_keys(spec["sweep"])

work_fn(key) = MyModule.solve(; ParamIO.params(key)...)

result = SweepRunner.run!(work_fn, vault, keys; load = MyModule)
SweepRunner.launchable(result) || exit(1)
