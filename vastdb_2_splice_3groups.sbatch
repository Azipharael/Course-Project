#!/bin/bash -l
#SBATCH --job-name=vast_spl_3way_final
#SBATCH -p IGC
#SBATCH --cpus-per-task=12
#SBATCH --mem=80gb
#SBATCH --time=48:00:00
#SBATCH --output=vast_spl_3way_final_%j.log

set -euo pipefail

# PATHS
VAST_SIF=/data/Users/.singularity_containers/ADA/vast.sif
VASTDB=/ifs/igc/folders/RRA/lucasfaria/project/vastdb

# Updated to the new 3-way splicing results directory
OUTDIR=/ifs/igc/folders/RRA/lucasfaria/project/vast_results_splicing_3way/align_output

echo "--- STEP 1: COMBINE (Splicing Machinery 3-Groups) ---"
# This merges Healthy, Intermediate, and Impaired into one inclusion table
singularity exec -B /ifs/igc:/ifs/igc $VAST_SIF vast-tools combine \
    -sp Mm2 \
    -dbDir $VASTDB \
    -o $OUTDIR \
    --ir_version 2

echo "--- STEP 2: COMPARE (Healthy vs Impaired Machinery) ---"
# Locating the table generated in Step 1
INPUT_TAB=$OUTDIR/INCLUSION_LEVELS_FULL-mm10-2.tab

if [ ! -f "$INPUT_TAB" ]; then
    echo "Error: Inclusion table not found at $INPUT_TAB"
    exit 1
fi

# -a: Healthy Reference (Top 20% Machinery)
# -b: Impaired Test (Bottom 20% Machinery)
# Resulting dPSI = Impaired - Healthy (Positive means more IR in impaired cells)
singularity exec -B /ifs/igc:/ifs/igc $VAST_SIF vast-tools compare \
    $INPUT_TAB \
    -sp Mm2 \
    -dbDir $VASTDB \
    -o $OUTDIR \
    -a Healthy_Splicing \
    -b Impaired_Splicing \
    --min_dPSI 15

echo "Splicing Machinery 3-Group Analysis complete at $(date)"