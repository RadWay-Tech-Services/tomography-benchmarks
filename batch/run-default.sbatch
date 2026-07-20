#!/bin/bash
#SBATCH --account=pk_tmobench
#SBATCH --job-name=run-default
#SBATCH --partition=gpu
#SBATCH --time=00:10:00
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=4000
#SBATCH --gres=gpu:1
#SBATCH --output=run-default.log

module load singularity
export TMPDIR=/tmp
singularity exec --nv -B /opt/cray:/opt/cray -B /project/pk_tmobench/tomography-benchmarks:/tomography-benchmarks tomobenchmarks.sif bash -c '. /miniconda3/bin/activate && cd /tomography-benchmarks && just run-all'
