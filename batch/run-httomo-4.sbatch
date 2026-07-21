#!/bin/bash
#SBATCH --account=pk_tmobench
#SBATCH --job-name=run-httomo-4
#SBATCH --partition=gpu
#SBATCH --time=00:10:00
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --mem-per-cpu=4000
#SBATCH --gres=gpu:4
#SBATCH --exclusive
#SBATCH --output=run-httomo-4.log

module load singularity
export TMPDIR=/tmp
singularity exec --nv -B /opt/cray:/opt/cray -B /project/pk_tmobench/tomography-benchmarks:/tomography-benchmarks tomobenchmarks.sif bash -c '. /miniconda3/bin/activate && cd /tomography-benchmarks && just run-httomo pipelines/httomo/fbp-preproc.yaml synthetic.nx 4'
