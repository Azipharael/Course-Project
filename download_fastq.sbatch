#!/bin/bash
#SBATCH --job-name=tm_liver_fastq_dl         # Job name
#SBATCH --mail-type=END,FAIL          # Mail events (END, FAIL)
#SBATCH --mail-user=lucas.faria@gimm.pt # Your email
#SBATCH --ntasks=1                    # Run on a single CPU
#SBATCH --cpus-per-task=1             # Run on a single CPU
#SBATCH --mem=2gb                     # Job memory request
#SBATCH --time=1-00:00:00             # Time limit: 1 day (Days-Hrs:Min:Sec)
#SBATCH --output=download_%j.log      # Standard output log
#SBATCH --error=download_%j.err       # Standard error log

# Exit on error
set -euo pipefail

# Mandatory logging and environment setup from your example
pwd; hostname; date
export SINGULARITY_BIND="/ifs"

# --- DEFINE PATHS ---
TARGET_DIR="/ifs/igc/folders/RRA/lucasfaria/project/fastq_files"
URL_LIST="liver_facs_metadata_all_timepoints_fastq_urls.txt"

# Check if the URL list exists (in the current directory where you run sbatch)
if [ -f "$URL_LIST" ]; then
    echo "Starting download from $URL_LIST into $TARGET_DIR..."
    
    # -nc: No-clobber (skips download if file already exists in target)
    # -i:  Input file (the list of URLs)
    # -P:  Prefix (the target directory for downloads)
    wget -nc -i "$URL_LIST" -P "$TARGET_DIR"
    
else
    echo "Error: URL list '$URL_LIST' not found in $(pwd)"
    exit 1
fi

echo "Download process completed at:"
date
