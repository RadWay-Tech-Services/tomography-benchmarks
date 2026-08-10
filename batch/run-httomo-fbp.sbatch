#!/bin/bash
#SBATCH --account=pk_tmobench
#SBATCH --job-name=run-httomo-fbp
#SBATCH --partition=gpu
#SBATCH --time=00:10:00
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --cpus-per-task=16
#SBATCH --mem-per-cpu=4000
#SBATCH --gres=gpu:4
#SBATCH --output=run-httomo-fbp.log

module load singularity
export TMPDIR=/tmp
singularity exec --nv -B /opt/cray:/opt/cray -B /project/pk_tmobench/tomography-benchmarks:/tomography-benchmarks tomobenchmarks.sif bash -c '. /miniconda3/bin/activate && cd /tomography-benchmarks && for i in {0..1}; do just run-httomo pipelines/httomo/fbp.yaml synthetic-huge.nx 4; done'
