#!/bin/bash -l
#SBATCH --job-name=vast_align_3groups
#SBATCH -p IGC
#SBATCH --cpus-per-task=16
#SBATCH --mem=120gb
#SBATCH --time=244:00:00        # 6 days
#SBATCH --output=vast_3groups_%j.log
#SBATCH --error=vast_3groups_%j.err

set -euo pipefail

# 1. PATHS
VAST_SIF=/data/Users/.singularity_containers/ADA/vast.sif
VASTDB=/ifs/igc/folders/RRA/lucasfaria/project/vastdb

# Updated to the new 3-group results directory
OUTDIR=/ifs/igc/folders/RRA/lucasfaria/project/vast_results_3groups
POOL_DIR=$OUTDIR/pooled_fastqs

mkdir -p $OUTDIR/align_output $OUTDIR/combine_output $OUTDIR/compare_output $OUTDIR/logs
exec > >(tee -a "$OUTDIR/logs/vast_3groups_align.log") 2>&1

echo "VAST-TOOLS 3-Group Alignment started at $(date)"

# 2. VAST-TOOLS ALIGNMENT

# --- Sample 1: High Senescence ---
if [ -f "$OUTDIR/align_output/to_combine/High_Senescence.eej2" ]; then
    echo "--- [SKIP] High_Senescence alignment found. ---"
else
    echo "--- Running vast-tools align: High Senescence ---"
    singularity exec -B /ifs/igc:/ifs/igc $VAST_SIF vast-tools align \
        $POOL_DIR/High_Senescence_pooled_R1.fastq.gz \
        $POOL_DIR/High_Senescence_pooled_R2.fastq.gz \
        -name High_Senescence -sp mm10 -dbDir $VASTDB -o $OUTDIR/align_output -cores 16
fi

# --- Sample 2: Intermediate Senescence (NEW) ---
if [ -f "$OUTDIR/align_output/to_combine/Intermediate_Senescence.eej2" ]; then
    echo "--- [SKIP] Intermediate_Senescence alignment found. ---"
else
    echo "--- Running vast-tools align: Intermediate Senescence ---"
    singularity exec -B /ifs/igc:/ifs/igc $VAST_SIF vast-tools align \
        $POOL_DIR/Intermediate_Senescence_pooled_R1.fastq.gz \
        $POOL_DIR/Intermediate_Senescence_pooled_R2.fastq.gz \
        -name Intermediate_Senescence -sp mm10 -dbDir $VASTDB -o $OUTDIR/align_output -cores 16
fi

# --- Sample 3: Low Senescence ---
if [ -f "$OUTDIR/align_output/to_combine/Low_Senescence.eej2" ]; then
    echo "--- [SKIP] Low_Senescence alignment found. ---"
else
    echo "--- Running vast-tools align: Low Senescence ---"
    singularity exec -B /ifs/igc:/ifs/igc $VAST_SIF vast-tools align \
        $POOL_DIR/Low_Senescence_pooled_R1.fastq.gz \
        $POOL_DIR/Low_Senescence_pooled_R2.fastq.gz \
        -name Low_Senescence -sp mm10 -dbDir $VASTDB -o $OUTDIR/align_output -cores 16
fi

echo "All 3 alignments finished successfully at $(date)"