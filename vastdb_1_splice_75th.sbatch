#!/bin/bash -l
#SBATCH --job-name=vast_align_splicing_75th
#SBATCH -p IGC
#SBATCH --cpus-per-task=16
#SBATCH --mem=120gb
#SBATCH --time=144:00:00        # 6 days
#SBATCH --output=vast_splicing_75th_%j.log
#SBATCH --error=vast_splicing_75th_%j.err

set -euo pipefail

# 1. PATHS
VAST_SIF=/data/Users/.singularity_containers/ADA/vast.sif
VASTDB=/ifs/igc/folders/RRA/lucasfaria/project/vastdb

# Updated to the 75th-split results directory
OUTDIR=/ifs/igc/folders/RRA/lucasfaria/project/vast_results_splicing_75th
POOL_DIR=$OUTDIR/pooled_fastqs

# Create output subdirectories
mkdir -p $OUTDIR/align_output $OUTDIR/combine_output $OUTDIR/compare_output $OUTDIR/logs
exec > >(tee -a "$OUTDIR/logs/vast_splicing_75th_run.log") 2>&1

echo "VAST-TOOLS Alignment (75th Percentile Splicing Split) started at $(date)"

# 2. VAST-TOOLS ALIGNMENT

# --- Sample 1: High Splicing (Top 25% of Machinery Score) ---
if [ -f "$OUTDIR/align_output/to_combine/High_Splicing.eej2" ]; then
    echo "--- [SKIP] High_Splicing alignment found. Skipping. ---"
else
    echo "--- Step 1: Running vast-tools align: High_Splicing ---"
    singularity exec -B /ifs/igc:/ifs/igc $VAST_SIF vast-tools align \
        $POOL_DIR/High_Splicing_pooled_R1.fastq.gz \
        $POOL_DIR/High_Splicing_pooled_R2.fastq.gz \
        -name High_Splicing \
        -sp mm10 \
        -dbDir $VASTDB \
        -o $OUTDIR/align_output \
        -cores 16
fi

# --- Sample 2: Low Splicing (Bottom 75% of Machinery Score) ---
if [ -f "$OUTDIR/align_output/to_combine/Low_Splicing.eej2" ]; then
    echo "--- [SKIP] Low_Splicing alignment found. Skipping. ---"
else
    echo "--- Step 1: Running vast-tools align: Low_Splicing ---"
    singularity exec -B /ifs/igc:/ifs/igc $VAST_SIF vast-tools align \
        $POOL_DIR/Low_Splicing_pooled_R1.fastq.gz \
        $POOL_DIR/Low_Splicing_pooled_R2.fastq.gz \
        -name Low_Splicing \
        -sp mm10 \
        -dbDir $VASTDB \
        -o $OUTDIR/align_output \
        -cores 16
fi

echo "Alignment process for 75th split finished successfully at $(date)"