import scanpy as sc
import pandas as pd
import os
import shutil
from pathlib import Path
import logging

# =============================================================================
# 1. CONFIGURATION
# =============================================================================
CONFIG = {
    # Path to the binary-split file (75th percentile)
    "adata_path": "Old_Hepatocytes_Splicing_75th_split.h5ad",
    
    # Path to your barcode mapping file
    "matching_csv": "brie_to_atlas_matching_results.csv",
    
    # Source of individual cell FASTQs
    "fastq_dir": "/ifs/igc/folders/RRA/lucasfaria/project/fastq_files",
    
    # New output directory for the 75th split analysis
    "out_dir": "/ifs/igc/folders/RRA/lucasfaria/project/vast_results_splicing_75th",
    
    # The groups defined in your 75th split code
    "groups": ["High_Splicing", "Low_Splicing"],
    
    # The column name used in the h5ad
    "label_col": "splicing_group"
}

# Setup Logging
log_dir = Path(CONFIG["out_dir"]) / "logs"
log_dir.mkdir(parents=True, exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(log_dir / "fastq_pooling_75th.log"),
        logging.StreamHandler()
    ]
)

def concatenate_files(source_list, output_path):
    """Efficiently concatenates gzipped files using binary streams."""
    if not source_list:
        logging.warning(f"No files to concatenate for {output_path}")
        return
    
    logging.info(f"Creating: {output_path} (from {len(source_list)} files)")
    with open(output_path, 'wb') as outfile:
        for fname in source_list:
            with open(fname, 'rb') as infile:
                shutil.copyfileobj(infile, outfile)

def main():
    # Create directory for pooled results
    pool_dir = Path(CONFIG["out_dir"]) / "pooled_fastqs"
    pool_dir.mkdir(parents=True, exist_ok=True)

    # 1. Load Data
    logging.info(f"Loading AnnData from {CONFIG['adata_path']}...")
    adata = sc.read_h5ad(CONFIG["adata_path"])
    
    logging.info("Loading Matching CSV...")
    matching_df = pd.read_csv(CONFIG["matching_csv"]).set_index('rna_index')

    # 2. Join labels
    # Merging metadata with BRIE barcodes
    merged = adata.obs.join(matching_df[['brie_id', 'match_type']], how='inner')
    valid_matches = merged[merged['match_type'] == 'One-to-One'].copy()
    
    if valid_matches.empty:
        logging.error("No 'One-to-One' matches found. Check barcode matching.")
        return

    logging.info(f"Matched {len(valid_matches)} cells for pooling (75th Split).")

    # 3. Scan FASTQ directory
    logging.info(f"Scanning FASTQ directory: {CONFIG['fastq_dir']}")
    all_fqs = [f for f in os.listdir(CONFIG["fastq_dir"]) if f.endswith('.gz')]
    
    # Initialize storage buckets for files
    mapping_results = {grp: {'R1': [], 'R2': []} for grp in CONFIG["groups"]}

    # 4. Matching Loop: Link Cell IDs to actual Files
    logging.info("Mapping barcodes to physical FASTQ files...")
    cells_processed = 0
    for idx, row in valid_matches.iterrows():
        group = row[CONFIG['label_col']]
        
        # Verify group is valid
        if group not in CONFIG["groups"]:
            continue

        # Logic: Convert Brie IDs (hyphens) to TMS format (underscores)
        query = str(row['brie_id']).replace("-", "_")
        
        # Find matching files in the directory
        matches = [f for f in all_fqs if query in f]
        
        if matches:
            cells_processed += 1
            for f in matches:
                full_path = os.path.join(CONFIG["fastq_dir"], f)
                if "_R1" in f:
                    mapping_results[group]['R1'].append(full_path)
                elif "_R2" in f:
                    mapping_results[group]['R2'].append(full_path)

    logging.info(f"Successfully mapped {cells_processed} cells to FASTQ files.")

    # 5. Perform the physical concatenation (Pooling)
    for grp in CONFIG["groups"]:
        r1_files = sorted(mapping_results[grp]['R1'])
        r2_files = sorted(mapping_results[grp]['R2'])
        
        logging.info(f"Group {grp}: Pooling {len(r1_files)} R1 files.")

        # Save file list for reproducibility
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

    logging.info(f"75th Split pooling complete. Files in: {pool_dir}")

if __name__ == "__main__":
    main()