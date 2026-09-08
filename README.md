# templateHPC.jl

A starting point for a parameter-sweep study on a cluster, wired to
[ParamIO.jl](https://github.com/QAtlasHub/ParamIO.jl),
[DataVault.jl](https://github.com/QAtlasHub/DataVault.jl) and
[SweepRunner.jl](https://github.com/QAtlasHub/SweepRunner.jl).

Press **Use this template**, then:

```bash
./setup.sh MyStudy FirstSweep
```

That renames the module, renames the example project, and — the part that is easy
to forget — issues fresh UUIDs. The template ships placeholders, and every copy
that keeps them declares itself to be the same package as every other copy; Pkg
resolves one into the other's place without reporting anything wrong.

## The shape

```
src/, test/            the shared library — physics, models, anything more than
                       one project needs. No HPC dependency.
projects/<name>/       one study. Copy the directory to start another.
  configs/             the sweep, at three sizes: smoke / debug / production
  scripts/compute.jl   the run. Same command on a laptop and on 1000 cores.
  batch/               SLURM submission — the ONLY place site-specific lines go
  report/              a SEPARATE environment that draws from the finished vault
  out/                 DataVault writes here; gitignored
  note/                working notes
docs/, notes are per-project; docs/ is for the shared library.
```

## Why it is split this way

**The compute environment stays lean.** `projects/<name>/Project.toml` has no
plotting backend and no Pinax. Those are in `report/`, which reads the same vault
off disk. A figure dependency can then never find its way onto a compute node.

**The library is separate from the run.** Projects depend on the root by
`[sources] {path = "../.."}`, so the same `solve` runs in a smoke test and in the
production sweep, and neither can drift from the other.

**The config is the only thing that changes with size.** `smoke.toml` and
`production.toml` have the same shape; a config that works small is the config
that runs big.

## Getting started

`setup.sh` instantiates the library and every project, so after it there is one
thing to run (`report/` is instantiated the first time you draw — it carries the
plotting backend and is slow to install):

```bash
julia --project=projects/FirstSweep projects/FirstSweep/scripts/compute.jl \
      projects/FirstSweep/configs/smoke.toml
```

Two points, seconds on a laptop. Then write `MyStudy.solve` — it is the one
function the sweep calls — and grow `configs/` until `sbatch batch/run.sh
configs/production.toml` is worth submitting.

Re-running is cheap and safe: a finished point is skipped after a single manifest
read, two processes pointed at the same vault never compute the same point twice,
and a run that is killed is continued by the next one rather than restarted.
