#!/bin/bash
#SBATCH --account=pk_tmobench
#SBATCH --job-name=build-container
#SBATCH --partition=cpu
#SBATCH --time=00:30:00
#SBATCH --cpus-per-task=16
#SBATCH --mem-per-cpu=2000
#SBATCH --output=build-container.log

module load singularity
cd /project/pk_tmobench/tomography-benchmarks
rm tomobenchmarks.sif || true
singularity --verbose build --fakeroot --fix-perms tomobenchmarks.sif tomobenchmarks.def
