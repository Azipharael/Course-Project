#!/bin/bash
#SBATCH --job-name=tms_brie2
#SBATCH -p IGC
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=45G
#SBATCH --time=04:00:00
#SBATCH --array=1-606%50             # <--- CHANGE THIS FOR BATCH 5
#SBATCH --output=logs_align/star_%A_%a.out
#SBATCH --error=logs_align/star_%A_%a.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=lucas.faria@gimm.pt

set -euo pipefail

# --- CHUNK SETTING ---
# Change this for every batch (0, 1000, 2000, 3000, 4000)
OFFSET=4000 

# -----------------------------
# 1. PATHS
# -----------------------------
METADATA="/ifs/igc/folders/RRA/lucasfaria/project/metadata/fastq_pairs.csv"
STAR_INDEX="/ifs/igc/folders/RRA/lucasfaria/references/mouse_star_index"
OUTDIR="/ifs/igc/folders/RRA/lucasfaria/project/bam_files"

# -----------------------------
# 2. SELECT CELL DATA
# -----------------------------
# Calculate current cell index
ACTUAL_ID=$((${SLURM_ARRAY_TASK_ID} + ${OFFSET}))
TARGET_LINE=$((${ACTUAL_ID} + 1))

# Extract the line
LINE=$(sed -n "${TARGET_LINE}p" "$METADATA")

# Safety: stop if we hit an empty line at the end of the file
if [ -z "$LINE" ]; then
    echo "End of file reached. Exiting."
    exit 0
fi

SAMPLE=$(echo "$LINE" | cut -d',' -f1)
R1=$(echo "$LINE" | cut -d',' -f2)
R2=$(echo "$LINE" | cut -d',' -f3)

OUT_PREFIX="${OUTDIR}/${SAMPLE}."
FINAL_BAM="${OUT_PREFIX}Aligned.sortedByCoord.out.bam"

# -----------------------------
# 3. ENVIRONMENT
# -----------------------------
module load STAR || echo "Using STAR wrapper"
module load samtools || echo "Using samtools wrapper"

# -----------------------------
# 4. RUN ALIGNMENT (BRIE2 OPTIMIZED)
# -----------------------------
echo "Processing Cell #$ACTUAL_ID: $SAMPLE"

STAR \
  --runThreadN "$SLURM_CPUS_PER_TASK" \
  --genomeDir "$STAR_INDEX" \
  --readFilesIn "$R1" "$R2" \
  --readFilesCommand zcat \
  --outFileNamePrefix "$OUT_PREFIX" \
  --outSAMtype BAM SortedByCoordinate \
  --outSAMattributes NH HI AS nM XS MD jM jI \
  --limitBAMsortRAM 38000000000 \
  --outFilterMultimapNmax 10 \
  --outFilterMismatchNmax 10 \
  --alignSJoverhangMin 8 \
  --alignSJDBoverhangMin 1 \
  --alignIntronMin 20 \
  --alignIntronMax 1000000 \
  --alignMatesGapMax 1000000 \
  --twopassMode Basic

# -----------------------------
# 5. INDEX BAM (FOR BRIE2)
# -----------------------------
if [[ -f "$FINAL_BAM" ]]; then
    samtools index "$FINAL_BAM"
else
    echo "ERROR: BAM not found for $SAMPLE"
    exit 1
fi

