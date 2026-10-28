#!/bin/bash -l
#SBATCH --job-name=vast_final_75th
#SBATCH -p IGC
#SBATCH --cpus-per-task=4
#SBATCH --mem=30gb
#SBATCH --time=48:00:00
#SBATCH --output=vast_75th_final_%j.log

set -euo pipefail

# PATHS
VAST_SIF=/data/Users/.singularity_containers/ADA/vast.sif
VASTDB=/ifs/igc/folders/RRA/lucasfaria/project/vastdb

# Point to the 75th split results directory
OUTDIR=/ifs/igc/folders/RRA/lucasfaria/project/vast_results_splicing_75th/align_output

echo "--- STEP 1: COMBINE (75th Percentile Split) ---"
# This merges High_Splicing and Low_Splicing into the inclusion table
singularity exec -B /ifs/igc:/ifs/igc $VAST_SIF vast-tools combine \
    -sp Mm2 \
    -dbDir $VASTDB \
    -o $OUTDIR \
    --ir_version 2

echo "--- STEP 2: COMPARE (High vs Low Machinery) ---"
# Locating the table generated in Step 1
INPUT_TAB=$(ls $OUTDIR/INCLUSION_LEVELS_FULL-mm10-*.tab | head -n 1)

if [ -z "$INPUT_TAB" ]; then
    echo "Error: Inclusion table not found in $OUTDIR"
    exit 1
fi

echo "Using input table: $INPUT_TAB"

# -a: High_Splicing (Reference / Control)
# -b: Low_Splicing (Test / Impaired)
# Resulting dPSI = Low - High (Positive = Increased Retention in the Low group)
singularity exec -B /ifs/igc:/ifs/igc $VAST_SIF vast-tools compare \
    $INPUT_TAB \
    -sp Mm2 \
    -dbDir $VASTDB \
    -o $OUTDIR \
    -a High_Splicing \
    -b Low_Splicing \
    --min_dPSI 15

echo "VAST-TOOLS final processing for 75th split complete at $(date)"