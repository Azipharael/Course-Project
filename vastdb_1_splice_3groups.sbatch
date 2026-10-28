#!/bin/bash -l
#SBATCH --job-name=vast_align_splicing_3way
#SBATCH -p IGC
#SBATCH --cpus-per-task=16
#SBATCH --mem=120gb
#SBATCH --time=244:00:00        # ~10 days
#SBATCH --output=vast_spl_3way_%j.log
#SBATCH --error=vast_spl_3way_%j.err

set -euo pipefail

# 1. PATHS
VAST_SIF=/data/Users/.singularity_containers/ADA/vast.sif
VASTDB=/ifs/igc/folders/RRA/lucasfaria/project/vastdb

# Updated to the new splicing-specific 3-way results directory
OUTDIR=/ifs/igc/folders/RRA/lucasfaria/project/vast_results_splicing_3way
POOL_DIR=$OUTDIR/pooled_fastqs

mkdir -p $OUTDIR/align_output $OUTDIR/combine_output $OUTDIR/compare_output $OUTDIR/logs
exec > >(tee -a "$OUTDIR/logs/vast_spl_3way_align.log") 2>&1

echo "VAST-TOOLS 3-Way Splicing Machinery Alignment started at $(date)"

# 2. VAST-TOOLS ALIGNMENT

# --- Sample 1: Impaired Splicing (Bottom 20%) ---
if [ -f "$OUTDIR/align_output/to_combine/Impaired_Splicing.eej2" ]; then
    echo "--- [SKIP] Impaired_Splicing alignment found. ---"
else
    echo "--- Running vast-tools align: Impaired Splicing ---"
    singularity exec -B /ifs/igc:/ifs/igc $VAST_SIF vast-tools align \
        $POOL_DIR/Impaired_Splicing_pooled_R1.fastq.gz \
        $POOL_DIR/Impaired_Splicing_pooled_R2.fastq.gz \
        -name Impaired_Splicing -sp mm10 -dbDir $VASTDB -o $OUTDIR/align_output -cores 16
fi

# --- Sample 2: Intermediate Splicing (Middle 60%) ---
if [ -f "$OUTDIR/align_output/to_combine/Intermediate_Splicing.eej2" ]; then
    echo "--- [SKIP] Intermediate_Splicing alignment found. ---"
else
    echo "--- Running vast-tools align: Intermediate Splicing ---"
    singularity exec -B /ifs/igc:/ifs/igc $VAST_SIF vast-tools align \
        $POOL_DIR/Intermediate_Splicing_pooled_R1.fastq.gz \
        $POOL_DIR/Intermediate_Splicing_pooled_R2.fastq.gz \
        -name Intermediate_Splicing -sp mm10 -dbDir $VASTDB -o $OUTDIR/align_output -cores 16
fi

# --- Sample 3: Healthy Splicing (Top 20%) ---
if [ -f "$OUTDIR/align_output/to_combine/Healthy_Splicing.eej2" ]; then
    echo "--- [SKIP] Healthy_Splicing alignment found. ---"
else
    echo "--- Running vast-tools align: Healthy Splicing ---"
    singularity exec -B /ifs/igc:/ifs/igc $VAST_SIF vast-tools align \
        $POOL_DIR/Healthy_Splicing_pooled_R1.fastq.gz \
        $POOL_DIR/Healthy_Splicing_pooled_R2.fastq.gz \
        -name Healthy_Splicing -sp mm10 -dbDir $VASTDB -o $OUTDIR/align_output -cores 16
fi

echo "All 3 Splicing groups finished successfully at $(date)"