#!/bin/bash -l
#SBATCH --job-name=vast_final_95th
#SBATCH -p IGC
#SBATCH --cpus-per-task=12
#SBATCH --mem=80gb
#SBATCH --time=48:00:00
#SBATCH --output=vast_95th_final_%j.log

set -euo pipefail

# 1. PATHS
VAST_SIF=/data/Users/.singularity_containers/ADA/vast.sif
VASTDB=/ifs/igc/folders/RRA/lucasfaria/project/vastdb

# Updated to the 95th-split results directory
OUTDIR=/ifs/igc/folders/RRA/lucasfaria/project/vast_results_95th_split/align_output

echo "--- STEP 1: COMBINE (95th Percentile Split) ---"
# -sp Mm2 ensures supplemental tables (IR, ALT, etc.) are generated
singularity exec -B /ifs/igc:/ifs/igc $VAST_SIF vast-tools combine \
    -sp Mm2 \
    -dbDir $VASTDB \
    -o $OUTDIR \
    --ir_version 2

echo "--- STEP 2: COMPARE (95th Percentile Split) ---"
# Target the inclusion table generated in Step 1
INPUT_TAB=$OUTDIR/INCLUSION_LEVELS_FULL-mm10-2.tab

if [ ! -f "$INPUT_TAB" ]; then
    echo "Error: Inclusion table not found at $INPUT_TAB"
    exit 1
fi

# -a: Reference/Control (Low_Senescence)
# -b: Target (High_Senescence)
# This calculates dPSI = High - Low
singularity exec -B /ifs/igc:/ifs/igc $VAST_SIF vast-tools compare \
    $INPUT_TAB \
    -sp Mm2 \
    -dbDir $VASTDB \
    -o $OUTDIR \
    -a Low_Senescence \
    -b High_Senescence \
    --min_dPSI 15

echo "Final VAST-TOOLS analysis for 95th split complete at $(date)"