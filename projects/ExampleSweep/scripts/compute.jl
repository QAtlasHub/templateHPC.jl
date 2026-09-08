#==============================================================================
 compute.jl — the three-layer driver. This is the file to copy, not to invent.

   ParamIO    : config TOML   -> Vector{DataKey}   (what to compute)
   DataVault  : (study, run)  -> file storage      (where it goes)
   SweepRunner: run!(work_fn) -> parallel runtime  (do it, lock-safe, resumable)

 The work itself is `MyModule.work_fn`, in a PACKAGE rather than in this script.
 That is what lets `run!(…; load=MyModule)` hand it to the workers — no
 `@everywhere`, and nothing to forget broadcasting.

     julia --project=. scripts/compute.jl configs/smoke.toml

 Run it again and it exits in milliseconds: the manifest records what is done.
==============================================================================#

# `using X: X` brings in the MODULE and none of its exports, so every call below has to name where
# it comes from. That is a discipline the seam needs rather than a style choice: ClassicalMonteCarlo
# — a plausible work package for this slot — also exports `run!`, and a bare `using` of both would
# make `run!` ambiguous at the one call that matters. Qualifying keeps `SweepRunner.run!` the sweep's
# `run!` no matter what the work package is called or what it exports.
using DataVault: DataVault
using MyModule: MyModule
using ParamIO: ParamIO
using SweepRunner: SweepRunner

const CONFIG = get(ARGS, 1, joinpath(@__DIR__, "..", "configs", "smoke.toml"))

spec = ParamIO.load(CONFIG)
keys = ParamIO.expand(spec)
# `outdir` is NOT passed. DataVault resolves it itself — kwarg, then DATAVAULT_OUTDIR, then the
# config's [study] outdir — and a kwarg wins, so reading the environment here and handing the result
# over would silently make the config's own setting unreachable. The config decides where its
# results go; the driver only says which run.
vault = DataVault.Vault(CONFIG; run="phase1")

SweepRunner.init_workers!(; mode=:auto)

# work_fn RETURNS a Dict; the runtime saves it and writes the .done marker.
# batch/run.sh traps the wall-clock signal and touches this file, at which point
# run! stops dispatching new keys and returns cleanly instead of being killed.
opts = SweepRunner.RunOpts(; stop_flag=get(ENV, "PM_STOP_FLAG", nothing))

result = SweepRunner.run!(MyModule.work_fn, vault, keys; opts=opts, load=MyModule)
@info "phase1 complete" result

ledger = DataVault.build_ledger(vault)      # one row per completed key
@info "ledger written" ledger
