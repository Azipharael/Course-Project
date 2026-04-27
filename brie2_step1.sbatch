#!/bin/bash -l
#SBATCH --job-name=brie2_liver_final
#SBATCH -p IGC
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=lucas.faria@gimm.pt
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=60gb
#SBATCH --time=24:00:00
#SBATCH --output=logs_brie2/brie2_%j.log
#SBATCH --error=logs_brie2/brie2_%j.err

set -euo pipefail

#########################################
# PATHS & ENVIRONMENT SETUP
#########################################
BRIE2_SIF=/data/Users/.singularity_containers/ADA/brie2.sif
ANNO_FILE=/ifs/igc/folders/RRA/lucasfaria/project/brie2_annotations/SE.filtered.gtf.gz
FEATURE_FILE=/ifs/igc/folders/RRA/lucasfaria/project/brie2_annotations/mouse_features.filtered.csv.gz
BAM_DIR=/ifs/igc/folders/RRA/lucasfaria/project/bam_files
RAW_METADATA=/ifs/igc/folders/RRA/lucasfaria/project/metadata/liver_facs_metadata_all_timepoints.csv
OUTDIR=brie2_results

# --- FIX FOR CUDA ERRORS ---
# Force TensorFlow to ignore GPUs and suppress low-level driver warnings
export CUDA_VISIBLE_DEVICES=""
export TF_CPP_MIN_LOG_LEVEL=2
# ---------------------------

mkdir -p logs_brie2
mkdir -p "${OUTDIR}"

#########################################
# STEP 0: PREPROCESS METADATA
#########################################
SAM_LIST="${OUTDIR}/cell_bams.tsv"
CELL_ANNO="${OUTDIR}/cell_anno.tsv"

echo "Preparing input tables from CSV..."
> "${SAM_LIST}"
> "${CELL_ANNO}"

# Remove carriage returns and process metadata
# Clean_id is col 13, age is col 3
tr -d '\r' < "${RAW_METADATA}" | awk -F',' 'NR>1 {print $13, $3}' | while read -r clean_id age; do
    BAM_NAME="${clean_id}.Aligned.sortedByCoord.out.bam"
    FULL_BAM_PATH="${BAM_DIR}/${BAM_NAME}"
    if [[ -f "${FULL_BAM_PATH}" ]]; then
        echo -e "${FULL_BAM_PATH}\t${clean_id}" >> "${SAM_LIST}"
        # Group 0: 3m (Young) | Group 1: Others (Aging)
        if [[ "$age" == "3m" ]]; then 
            echo -e "${clean_id}\t0" >> "${CELL_ANNO}"
        else 
            echo -e "${clean_id}\t1" >> "${CELL_ANNO}"
        fi
    fi
done

#########################################
# STEP 0.5: HOTFIX FOR TF-KERAS ERROR
#########################################
export PYTHONUSERBASE="${OUTDIR}/.python_libs"
mkdir -p "${PYTHONUSERBASE}"

echo "Injecting missing dependency: tf-keras"
singularity exec -B /data:/data -B /ifs:/ifs "${BRIE2_SIF}" \
    pip install --user --no-cache-dir tf-keras

# Find where the container's python puts --user installs
SITE_PKG=$(singularity exec "${BRIE2_SIF}" python3 -c "import site; print(site.getusersitepackages())")
export PYTHONPATH="${SITE_PKG}:${PYTHONPATH:-}"

#########################################
# STEP 1: BRIE-COUNT (Quantify reads)
#########################################
echo "Starting Step 1: brie-count at $(date)"

singularity exec -B /data:/data -B /ifs:/ifs "${BRIE2_SIF}" brie-count \
    -a "${ANNO_FILE}" \
    -S "${SAM_LIST}" \
    -o "${OUTDIR}" \
    -p "${SLURM_CPUS_PER_TASK}"

#########################################
# STEP 2: BRIE-QUANT (Statistical Testing)
#########################################
echo "Starting Step 2: brie-quant at $(date)"

# Added -f flag to use sequence features (priors)
singularity exec -B /data:/data -B /ifs:/ifs "${BRIE2_SIF}" brie-quant \
    -i "${OUTDIR}/brie_count.h5ad" \
    -c "${CELL_ANNO}" \
    -f "${FEATURE_FILE}" \
    -o "${OUTDIR}/brie_quant_results.h5ad" \
    --interceptMode gene \
    --LRTindex 0 \
    --batchSize 300000

echo "BRIE2 analysis finished successfully at $(date)"
