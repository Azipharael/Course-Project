#!/bin/bash -l
#SBATCH --job-name=mouse_star_index
#SBATCH -p IGC
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=lucas.faria@gimm.pt
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=60gb
#SBATCH --time=12:00:00
#SBATCH --output=logs_bam/idx_%j.log
#SBATCH --error=logs_bam/idx_%j.err

# Exit on error
set -euo pipefail

# Mandatory logging
pwd; hostname; date
export SINGULARITY_BIND="/ifs"

# -----------------------------
# 1. DEFINE PATHS
# -----------------------------
REFDIR="/ifs/igc/folders/RRA/lucasfaria/references/mouse_star_index"
RAW_DIR="${REFDIR}/raw_source"

mkdir -p "$RAW_DIR"

# -----------------------------
# 2. DOWNLOAD GENOME
# -----------------------------
cd "$RAW_DIR"

echo "Downloading GENCODE M25 files..."

if [[ ! -f "GRCm38.primary_assembly.genome.fa" ]]; then
    wget -q -c https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_mouse/release_M25/GRCm38.primary_assembly.genome.fa.gz
    gunzip GRCm38.primary_assembly.genome.fa.gz
fi

if [[ ! -f "gencode.vM25.annotation.gtf" ]]; then
    wget -q -c https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_mouse/release_M25/gencode.vM25.annotation.gtf.gz
    gunzip gencode.vM25.annotation.gtf.gz
fi

# -----------------------------
# 3. BUILD STAR INDEX
# -----------------------------
# The -l in the first line should make 'module' work.
# We load STAR and wget.
module load wget || echo "wget already in path"

echo "Starting STAR genomeGenerate..."

STAR --runThreadN "${SLURM_CPUS_PER_TASK}" \
     --runMode genomeGenerate \
     --genomeDir "$REFDIR" \
     --genomeFastaFiles "${RAW_DIR}/GRCm38.primary_assembly.genome.fa" \
     --sjdbGTFfile "${RAW_DIR}/gencode.vM25.annotation.gtf" \
     --sjdbOverhang 99 \
     --limitGenomeGenerateRAM 58000000000

echo "Process complete at $(date)"
