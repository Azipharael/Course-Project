import scanpy as sc
import pandas as pd
import os
import shutil
import sys
import traceback
from pathlib import Path
import logging

# =============================================================================
# 1. CONFIGURATION
# =============================================================================
CONFIG = {
    "adata_path": "Old_Hepatocytes_95th_Senescence_Groups_for_VastTools.h5ad",
    "matching_csv": "brie_to_atlas_matching_results.csv",
    "fastq_dir": "/ifs/igc/folders/RRA/lucasfaria/project/fastq_files",
    "out_dir": "/ifs/igc/folders/RRA/lucasfaria/project/vast_results_95th_split",
    "groups": ["High_Senescence", "Low_Senescence"]
}

# =============================================================================
# 2. LOGGING SETUP (Log and Err files)
# =============================================================================
log_dir = Path(CONFIG["out_dir"]) / "logs"
log_dir.mkdir(parents=True, exist_ok=True)

# Define file paths
log_file = log_dir / "fastq_pooling_95th.log"
err_file = log_dir / "fastq_pooling_95th.err"

# Create a logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)
formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')

# 1. Handler for General Log (INFO and above)
info_handler = logging.FileHandler(log_file, mode='a')
info_handler.setLevel(logging.INFO)
info_handler.setFormatter(formatter)

# 2. Handler for Error File (ERROR and above only)
error_handler = logging.FileHandler(err_file, mode='a')
error_handler.setLevel(logging.ERROR)
error_handler.setFormatter(formatter)

# 3. Handler for Console output
console_handler = logging.StreamHandler()
console_handler.setFormatter(formatter)

logger.addHandler(info_handler)
logger.addHandler(error_handler)
logger.addHandler(console_handler)

# =============================================================================
# 3. FUNCTIONS
# =============================================================================

def concatenate_files(source_list, output_path):
    """Efficiently concatenates gzipped files using binary streams."""
    if not source_list:
        logging.warning(f"No files to concatenate for {output_path}")
        return
    
    logging.info(f"Creating: {output_path} (from {len(source_list)} files)")
    try:
        with open(output_path, 'wb') as outfile:
            for fname in source_list:
                with open(fname, 'rb') as infile:
                    shutil.copyfileobj(infile, outfile)
    except Exception as e:
        logging.error(f"Failed to create {output_path}: {str(e)}")
        raise

def main():
    # Create directory for pooled results
    pool_dir = Path(CONFIG["out_dir"]) / "pooled_fastqs"
    pool_dir.mkdir(parents=True, exist_ok=True)

    # 1. Load Data
    if not os.path.exists(CONFIG['adata_path']):
        logging.error(f"AnnData file not found at {CONFIG['adata_path']}")
        return

    logging.info(f"Loading AnnData from {CONFIG['adata_path']}...")
    adata = sc.read_h5ad(CONFIG["adata_path"])
    
    logging.info("Loading Matching CSV...")
    matching_df = pd.read_csv(CONFIG["matching_csv"]).set_index('rna_index')

    # 2. Join labels
    merged = adata.obs.join(matching_df[['brie_id', 'match_type']], how='inner')
    valid_matches = merged[merged['match_type'] == 'One-to-One'].copy()
    
    if valid_matches.empty:
        logging.error("No 'One-to-One' matches found. Check barcode matching CSV and AnnData indices.")
        return

    logging.info(f"Matched {len(valid_matches)} cells for pooling.")

    # 3. Scan FASTQ directory
    if not os.path.exists(CONFIG['fastq_dir']):
        logging.error(f"Fastq directory not found: {CONFIG['fastq_dir']}")
        return

    logging.info(f"Scanning FASTQ directory: {CONFIG['fastq_dir']}")
    all_fqs = [f for f in os.listdir(CONFIG["fastq_dir"]) if f.endswith('.gz')]
    
    mapping_results = {grp: {'R1': [], 'R2': []} for grp in CONFIG["groups"]}

    # 4. Matching Loop
    logging.info("Mapping cell barcodes to physical FASTQ files...")
    for idx, row in valid_matches.iterrows():
        query = str(row['brie_id']).replace("-", "_")
        group = row['senescence_group']
        
        if group not in mapping_results:
            continue

        matches = [f for f in all_fqs if query in f]
        
        for f in matches:
            full_path = os.path.join(CONFIG["fastq_dir"], f)
            if "_R1" in f:
                mapping_results[group]['R1'].append(full_path)
            elif "_R2" in f:
                mapping_results[group]['R2'].append(full_path)

    # 5. Perform the physical concatenation
    for grp in CONFIG["groups"]:
        r1_files = sorted(mapping_results[grp]['R1'])
        r2_files = sorted(mapping_results[grp]['R2'])
        
        logging.info(f"Group {grp}: Found {len(r1_files)} R1 files.")

        with open(pool_dir / f"{grp}_source_file_list.txt", "w") as f:
            f.write("\n".join(r1_files + r2_files))

        if r1_files:
            concatenate_files(r1_files, pool_dir / f"{grp}_pooled_R1.fastq.gz")
        else:
            logging.error(f"No R1 files found for {grp}!")

        if r2_files:
            concatenate_files(r2_files, pool_dir / f"{grp}_pooled_R2.fastq.gz")
        else:
            logging.error(f"No R2 files found for {grp}!")

    logging.info(f"Pooling complete. Results in: {pool_dir}")

# =============================================================================
# 4. EXECUTION WITH CRASH REPORTING
# =============================================================================
if __name__ == "__main__":
    try:
        main()
    except Exception:
        # This captures any unexpected crash and writes the full traceback to the .err file
        logging.critical("FATAL ERROR: Script crashed unexpectedly.")
        logging.error(traceback.format_exc())
        sys.exit(1)

if __name__ == "__main__":
    main()