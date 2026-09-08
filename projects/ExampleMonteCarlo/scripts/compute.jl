#==============================================================================
 compute.jl — the three-layer driver, over an Ising sweep.

   ParamIO    : config TOML   -> Vector{DataKey}   (what to compute)
   DataVault  : (study, run)  -> file storage      (where it goes)
   SweepRunner: run!(work_fn) -> parallel runtime  (do it, lock-safe, resumable)

     julia --project=. scripts/compute.jl configs/smoke.toml

 Every module is imported as `using X: X` and every call is qualified. Here that is load-bearing
 rather than tidy: `ClassicalMonteCarlo` exports `run!` and so does `SweepRunner`, and the two mean
 different things — one advances a Markov chain, the other dispatches the sweep.
==============================================================================#

using DataVault: DataVault
using ExampleMonteCarlo: ExampleMonteCarlo
using ParamIO: ParamIO
using SweepRunner: SweepRunner

const CONFIG = get(ARGS, 1, joinpath(@__DIR__, "..", "configs", "smoke.toml"))
const OUTDIR = get(ENV, "DATAVAULT_OUTDIR", joinpath(@__DIR__, "..", "out"))

spec = ParamIO.load(CONFIG)
keys = ParamIO.expand(spec)
vault = DataVault.Vault(CONFIG; run="phase1", outdir=OUTDIR)

SweepRunner.init_workers!(; mode=:auto)
opts = SweepRunner.RunOpts(; stop_flag=get(ENV, "PM_STOP_FLAG", nothing))

result = SweepRunner.run!(
    ExampleMonteCarlo.work_fn, vault, keys; opts=opts, load=ExampleMonteCarlo
)
@info "phase1 complete" result

ledger = DataVault.build_ledger(vault)
@info "ledger written" ledger
