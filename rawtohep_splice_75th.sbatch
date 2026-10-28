#!/bin/bash -l
#SBATCH --job-name=vast_ir_hep
#SBATCH -p IGC
#SBATCH --cpus-per-task=16
#SBATCH --mem=120gb
#SBATCH --time=48:00:00
#SBATCH --output=vast_ir_%j.log
#SBATCH --error=vast_ir_%j.err

export SINGULARITY_BIND="/ifs"

singularity exec /Users/.singularity_containers/ADA/env.sif python /ifs/igc/folders/RRA/lucasfaria/project/rawtohep_splice_75th.py
