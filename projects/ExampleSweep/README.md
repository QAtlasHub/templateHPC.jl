# ExampleSweep

One project. Copy this directory to start another.

```
configs/   the sweep, at three sizes — smoke / debug / production
scripts/   compute.jl (the run), collect.jl (read it back)
batch/     SLURM submission; the only place site-specific lines belong
report/    a SEPARATE environment that draws from the vault
out/       DataVault writes here; gitignored
note/      working notes
```

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. scripts/compute.jl configs/smoke.toml   # seconds, on a laptop
sbatch batch/run.sh configs/production.toml               # the same command, at size
```

Re-running is cheap and safe: a finished point is skipped after one manifest
read, and a killed run is continued by the next one.
