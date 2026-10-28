#!/bin/bash -l
#SBATCH --job-name=vast_final_3groups
#SBATCH -p IGC
#SBATCH --cpus-per-task=12
#SBATCH --mem=80gb
#SBATCH --time=48:00:00
#SBATCH --output=vast_3grp_final_%j.log

set -euo pipefail

# PATHS
VAST_SIF=/data/Users/.singularity_containers/ADA/vast.sif
VASTDB=/ifs/igc/folders/RRA/lucasfaria/project/vastdb

# Updated to point to the new 3-group results directory
OUTDIR=/ifs/igc/folders/RRA/lucasfaria/project/vast_results_3groups/align_output

echo "--- STEP 1: COMBINE (3-Groups) ---"
# This will create a table containing High, Intermediate, and Low senescence columns
singularity exec -B /ifs/igc:/ifs/igc $VAST_SIF vast-tools combine \
    -sp Mm2 \
    -dbDir $VASTDB \
    -o $OUTDIR \
    --ir_version 2

echo "--- STEP 2: COMPARE (High vs Low) ---"
# We target the specific table generated in Step 1
INPUT_TAB=$OUTDIR/INCLUSION_LEVELS_FULL-mm10-2.tab

# We compare High (-b) vs Low (-a) to calculate the primary shift.
# The 'Intermediate_Senescence' column will still be present in the table 
# for you to look at manually or plot later.
singularity exec -B /ifs/igc:/ifs/igc $VAST_SIF vast-tools compare \
    $INPUT_TAB \
    -sp Mm2 \
    -dbDir $VASTDB \
    -o $OUTDIR \
    -a Low_Senescence \
    -b High_Senescence \
    --min_dPSI 15

echo "3-Group Analysis complete at $(date)"