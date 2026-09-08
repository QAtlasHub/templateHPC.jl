#!/bin/bash
#SBATCH --job-name=example-sweep-debug
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4
#SBATCH --time=00:10:00
#SBATCH --output=out/log/%x-%j.out
set -euo pipefail
mkdir -p out/log
julia --project=. scripts/compute.jl configs/debug.toml
