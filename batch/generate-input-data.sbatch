#!/bin/bash
#SBATCH --account=pk_tmobench
#SBATCH --job-name=run-default
#SBATCH --partition=cpu
#SBATCH --time=00:30:00
#SBATCH --cpus-per-task=16
#SBATCH --mem-per-cpu=2000
#SBATCH --output=generate-input-data.log

module load singularity
export TMPDIR=/tmp
singularity exec -B /opt/cray:/opt/cray -B /project/pk_tmobench/tomography-benchmarks:/tomography-benchmarks tomobenchmarks.sif bash -c '. /miniconda3/bin/activate && cd /tomography-benchmarks && just generate-all'
