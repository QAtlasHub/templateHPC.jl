# ExampleMonteCarlo

Ising on a square lattice, swept over size and temperature.

```
configs/   the sweep at three sizes — smoke / debug / production
scripts/   compute.jl (the run), collect.jl (read it back as a table)
batch/     SLURM submission; the only place site-specific lines belong
report/    a SEPARATE environment that draws from the vault
out/       DataVault writes here; gitignored
```

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. scripts/compute.jl configs/smoke.toml   # two points, seconds
julia --project=. scripts/collect.jl configs/smoke.toml
sbatch batch/run.sh configs/production.toml               # the same command, at size
```

## What this project shows that the other does not

**A real work package.** The physics is `ClassicalMonteCarlo` over a `Lattice2D` lattice, both
reached through the `LatticeCore` interface. `run!(…; load=ExampleMonteCarlo)` ships this project's
module to the workers, and everything it reaches travels with it.

**Why the compute environment has no plotting backend.** It is not hygiene. Both physics packages
carried `Plots` as a hard dependency until it was moved behind an extension; with `load=`, that
would have put a plotting stack on every worker.

**Why every call is qualified.** `ClassicalMonteCarlo` exports `run!` and so does `SweepRunner`, and
they mean different things — one advances a Markov chain, the other dispatches the sweep. Every
module here is imported as `using X: X`, so neither can be called unqualified by accident.

The grids crowd `kbT ≈ 2.269`, the exact 2D Ising transition, because a sweep earns its cost when
the interesting thing happens between two of its points.
