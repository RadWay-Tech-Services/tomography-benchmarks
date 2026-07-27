#!/bin/bash
#SBATCH --account=pk_tmobench
#SBATCH --job-name=run-nabu-fbp-preproc
#SBATCH --partition=gpu
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --mem-per-cpu=4000
#SBATCH --gres=gpu:4
#SBATCH --output=run-nabu-fbp-preproc.log

module load singularity
export TMPDIR=/tmp
singularity exec --nv -B /opt/cray:/opt/cray -B /project/pk_tmobench/tomography-benchmarks:/tomography-benchmarks tomobenchmarks.sif bash -c '. /miniconda3/bin/activate && cd /tomography-benchmarks && just run-nabu pipelines/nabu/fbp-preproc.conf synthetic-huge.nx 4'
