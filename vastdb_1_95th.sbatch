#!/bin/bash -l
#SBATCH --job-name=vast_align_95th
#SBATCH -p IGC
#SBATCH --cpus-per-task=16
#SBATCH --mem=120gb
#SBATCH --time=244:00:00        # 6 days
#SBATCH --output=vast_95th_%j.log
#SBATCH --error=vast_95th_%j.err

set -euo pipefail

# 1. PATHS
VAST_SIF=/data/Users/.singularity_containers/ADA/vast.sif
VASTDB=/ifs/igc/folders/RRA/lucasfaria/project/vastdb

# Updated to the 95th-split specific results directory
OUTDIR=/ifs/igc/folders/RRA/lucasfaria/project/vast_results_95th_split
POOL_DIR=$OUTDIR/pooled_fastqs

mkdir -p $OUTDIR/align_output $OUTDIR/combine_output $OUTDIR/compare_output $OUTDIR/logs
exec > >(tee -a "$OUTDIR/logs/vast_95th_align_run.log") 2>&1

echo "VAST-TOOLS Analysis (95th Percentile Split) started at $(date)"

# 2. VAST-TOOLS ALIGNMENT

# --- Sample 1: High Senescence ---
if [ -f "$OUTDIR/align_output/to_combine/High_Senescence.eej2" ]; then
    echo "--- [SKIP] High_Senescence alignment found. Skipping. ---"
else
    echo "--- Running vast-tools align: High Senescence ---"
    singularity exec -B /ifs/igc:/ifs/igc $VAST_SIF vast-tools align \
        $POOL_DIR/High_Senescence_pooled_R1.fastq.gz \
        $POOL_DIR/High_Senescence_pooled_R2.fastq.gz \
        -name High_Senescence \
        -sp mm10 \
        -dbDir $VASTDB \
        -o $OUTDIR/align_output \
        -cores 16
fi

# --- Sample 2: Low Senescence ---
if [ -f "$OUTDIR/align_output/to_combine/Low_Senescence.eej2" ]; then
    echo "--- [SKIP] Low_Senescence alignment found. Skipping. ---"
else
    echo "--- Running vast-tools align: Low Senescence ---"
    singularity exec -B /ifs/igc:/ifs/igc $VAST_SIF vast-tools align \
        $POOL_DIR/Low_Senescence_pooled_R1.fastq.gz \
        $POOL_DIR/Low_Senescence_pooled_R2.fastq.gz \
        -name Low_Senescence \
        -sp mm10 \
        -dbDir $VASTDB \
        -o $OUTDIR/align_output \
        -cores 16
fi

echo "Alignment process for 95th split finished successfully at $(date)"