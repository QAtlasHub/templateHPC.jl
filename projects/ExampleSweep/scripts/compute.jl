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

using DataVault
using MyModule
using ParamIO
using SweepRunner

const CONFIG = get(ARGS, 1, joinpath(@__DIR__, "..", "configs", "smoke.toml"))
# outdir precedence, resolved by DataVault: kwarg > ENV > the config's [study].
const OUTDIR = get(ENV, "DATAVAULT_OUTDIR", joinpath(@__DIR__, "..", "out"))

spec  = ParamIO.load(CONFIG)
keys  = ParamIO.expand(spec)
vault = DataVault.Vault(CONFIG; run="phase1", outdir=OUTDIR)

SweepRunner.init_workers!(; mode=:auto)

# work_fn RETURNS a Dict; the runtime saves it and writes the .done marker.
# batch/run.sh traps the wall-clock signal and touches this file, at which point
# run! stops dispatching new keys and returns cleanly instead of being killed.
opts = SweepRunner.RunOpts(; stop_flag=get(ENV, "PM_STOP_FLAG", nothing))

result = SweepRunner.run!(MyModule.work_fn, vault, keys; opts=opts, load=MyModule)
@info "phase1 complete" result

ledger = DataVault.build_ledger(vault)      # one row per completed key
@info "ledger written" ledger
