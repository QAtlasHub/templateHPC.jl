#!/bin/bash
#SBATCH --job-name=ising-sweep
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=16
#SBATCH --time=02:00:00
#SBATCH --output=out/log/%x-%j.out
#
# Site-specific lines (partition, account, module load) belong here and nowhere else.
#     sbatch batch/run.sh configs/production.toml
set -euo pipefail
CONFIG="${1:-configs/smoke.toml}"
mkdir -p out/log
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. scripts/compute.jl "$CONFIG"
