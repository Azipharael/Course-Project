#!/bin/bash -l
#SBATCH --job-name=brie2_quant_only
#SBATCH -p IGC
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=lucas.faria@gimm.pt
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=60gb
#SBATCH --time=12:00:00  # Reduced time since count is done
#SBATCH --output=logs_brie2/brie2_quant_%j.log
#SBATCH --error=logs_brie2/brie2_quant_%j.err

set -euo pipefail

#########################################
# PATHS & ENVIRONMENT SETUP
#########################################
BRIE2_SIF=/data/Users/.singularity_containers/ADA/brie2.sif
OUTDIR=brie2_results
CELL_ANNO="${OUTDIR}/cell_anno.tsv"

# --- FIX FOR CUDA ERRORS ---
export CUDA_VISIBLE_DEVICES=""
export TF_CPP_MIN_LOG_LEVEL=2

# --- RE-ESTABLISH PYTHON ENVIRONMENT ---
# We need this because brie-quant needs the tf-keras library you installed
export PYTHONUSERBASE="${OUTDIR}/.python_libs"
SITE_PKG=$(singularity exec "${BRIE2_SIF}" python3 -c "import site; print(site.getusersitepackages())")
export PYTHONPATH="${SITE_PKG}:${PYTHONPATH:-}"

#########################################
# STEP 2: BRIE-QUANT (Statistical Testing)
#########################################
echo "Starting Step 2: brie-quant at $(date)"

# REMOVED -f flag and FEATURE_FILE
singularity exec -B /data:/data -B /ifs:/ifs "${BRIE2_SIF}" brie-quant \
    -i "${OUTDIR}/brie_count.h5ad" \
    -c "${CELL_ANNO}" \
    -o "${OUTDIR}/brie_quant_results.h5ad" \
    --interceptMode gene \
    --LRTindex 0 \
    --batchSize 300000

echo "BRIE2 quantification finished successfully at $(date)"
