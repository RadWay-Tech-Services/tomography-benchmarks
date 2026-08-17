#!/bin/bash
#SBATCH --account=pk_tmobench
#SBATCH --job-name=trace-httomo-lprec
#SBATCH --partition=gpu
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --cpus-per-task=16
#SBATCH --mem-per-cpu=4000
#SBATCH --gres=gpu:4
#SBATCH --output=trace-httomo-lprec.log

module load singularity
export TMPDIR=/tmp
singularity exec --nv -B /opt/cray:/opt/cray -B /project/pk_tmobench/tomography-benchmarks:/tomography-benchmarks -B /scratch/pk_tmobench:/scratch/pk_tmobench tomobenchmarks.sif bash -c '. /miniconda3/bin/activate && cd /tomography-benchmarks && for i in {0..1}; do just trace-httomo pipelines/httomo/lprec.yaml /scratch/pk_tmobench/synthetic-huge.nx 4 /scratch/pk_tmobench/httomo-out httomo-lprec-trace-\$i 10; done'
