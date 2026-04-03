"""
cp_fUSI_orig2dest.py

Copies fUSI data from original locations (data06 / data03) to the new
per-project locations in data03 (DEST_BASE / PROJ_SUFFIX below).

Workflow
--------
  1st run  : fUSI_data_location_STORM.csv does not exist yet.
             The script creates it from original_Datapath_location.csv,
             dropping the redundant functional_path column and adding
             TOCOPY, COPIED, dest_root.
             User then opens the CSV, sets TOCOPY = YES for each row to copy,
             and re-runs the script.

  2nd run+ : Reads fUSI_data_location_STORM.csv, processes every row where
             TOCOPY == YES  and  COPIED != YES.
             For each such row it copies:
               (a) selected files from functional  Data_collection
               (b) entire      anatomical Data_collection  directory
               (c) selected files from anatomical  Data_analysis
             A per-run log is written to logs/ with COPIED and NOT COPIED sections.
             When all three operations succeed, COPIED = YES is set in the CSV.

Usage
-----
    cd 00_DATA_MANAGEMENT/03_CP_DATA
    python cp_fUSI_orig2dest.py
"""

import os
import shutil
import fnmatch
import pandas as pd
from pathlib import Path
from datetime import datetime

# ---------------------------------------------------------------------------
# Configuration  (edit here only)
# ---------------------------------------------------------------------------
DEST_BASE   = '/data03'   # base mount point
PROJ_SUFFIX = '_LC'       # appended to every project folder name

# Files to copy from functional Data_collection (patterns matched against
# relative paths; patterns WITHOUT '/' are matched against basename only,
# patterns WITH '/' are matched against the full relative path).
FUNC_COLLECTION_PATTERNS = [
    '*.csv',                                  # all CSV files (TTL, DAQ, stimulation, etc.)
    '*.xlsx',                                 # optional Excel files
    'experiment_config.json',                 # experiment configuration
    'FUSI_data/fUS_block_PDI_float.bin',      # raw binary ultrasound data
    'FUSI_data/*_PlaneWave_FUSI_data.mat',    # PlaneWave acquisition data
]

# Files to copy from anatomical Data_analysis
ANAT_ANALYSIS_PATTERNS = [
    'anatomic.mat',        # anatomical image
    'Transformation.mat',  # atlas transformation
]
# Anatomical Data_collection: copy entire directory (no pattern filter)

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
SCRIPT_DIR = Path(__file__).parent
SRC_CSV    = SCRIPT_DIR / 'original_Datapath_location.csv'
DEST_CSV   = SCRIPT_DIR / 'fUSI_data_location_STORM.csv'
LOGS_DIR   = SCRIPT_DIR / 'logs'


# ---------------------------------------------------------------------------
# Helper: translate any source path to the corresponding destination path
# ---------------------------------------------------------------------------
def to_dest_path(src_path: str) -> str:
    """
    Apply root substitution:
        /data0X/<project>/...  →  /data03/<project>_LC/...
    """
    parts   = str(src_path).rstrip('/').split('/')
    # parts = ['', 'data0X', 'fUSIMethodsPaper', 'Data_collection', ...]
    project = parts[2]
    rest    = '/'.join(parts[3:])
    return f'{DEST_BASE}/{project}{PROJ_SUFFIX}/{rest}'


# ---------------------------------------------------------------------------
# Helper: check if a relative file path matches a pattern
# ---------------------------------------------------------------------------
def matches_pattern(rel_path: str, pattern: str) -> bool:
    """
    If pattern contains '/', match against the full relative path.
    Otherwise, match against the basename only (so '*.csv' matches any CSV
    regardless of which subdirectory it lives in).
    """
    rel_path = rel_path.replace('\\', '/')
    if '/' in pattern:
        return fnmatch.fnmatch(rel_path, pattern)
    else:
        return fnmatch.fnmatch(os.path.basename(rel_path), pattern)


def matches_any(rel_path: str, patterns: list) -> bool:
    return any(matches_pattern(rel_path, p) for p in patterns)


# ---------------------------------------------------------------------------
# Helper: enumerate all files under a directory (relative paths)
# ---------------------------------------------------------------------------
def list_all_files(directory: str) -> list:
    result = []
    for root, _dirs, files in os.walk(directory):
        for f in sorted(files):
            full = os.path.join(root, f)
            rel  = os.path.relpath(full, directory).replace('\\', '/')
            result.append(rel)
    return sorted(result)


# ---------------------------------------------------------------------------
# Core copy: selected files only
# ---------------------------------------------------------------------------
def copy_selected_files(src_dir: str, dst_dir: str, patterns: list) -> dict:
    """
    Copy files from src_dir to dst_dir that match any of *patterns*.

    Returns a dict with keys:
        all_files    : list of all relative paths found in src_dir
        copied       : list of relative paths that were copied
        not_copied   : list of relative paths that were NOT copied
        errors       : list of error strings
        src_missing  : True if src_dir does not exist
    """
    result = dict(all_files=[], copied=[], not_copied=[], errors=[], src_missing=False)

    if not os.path.isdir(src_dir):
        result['src_missing'] = True
        result['errors'].append(f"Source directory not found: {src_dir}")
        return result

    os.makedirs(dst_dir, exist_ok=True)
    all_files = list_all_files(src_dir)
    result['all_files'] = all_files

    for rel in all_files:
        if matches_any(rel, patterns):
            src_file = os.path.join(src_dir, rel)
            dst_file = os.path.join(dst_dir, rel)
            os.makedirs(os.path.dirname(dst_file), exist_ok=True)
            try:
                shutil.copy2(src_file, dst_file)
                result['copied'].append(rel)
            except Exception as e:
                result['errors'].append(f"{rel}: {e}")
                result['not_copied'].append(rel)
        else:
            result['not_copied'].append(rel)

    return result


# ---------------------------------------------------------------------------
# Core copy: entire directory
# ---------------------------------------------------------------------------
def copy_entire_dir(src_dir: str, dst_dir: str) -> dict:
    """
    Copy ALL files from src_dir to dst_dir (recursive).

    Returns same dict structure as copy_selected_files.
    """
    result = dict(all_files=[], copied=[], not_copied=[], errors=[], src_missing=False)

    if not os.path.isdir(src_dir):
        result['src_missing'] = True
        result['errors'].append(f"Source directory not found: {src_dir}")
        return result

    os.makedirs(dst_dir, exist_ok=True)
    all_files = list_all_files(src_dir)
    result['all_files'] = all_files

    for rel in all_files:
        src_file = os.path.join(src_dir, rel)
        dst_file = os.path.join(dst_dir, rel)
        os.makedirs(os.path.dirname(dst_file), exist_ok=True)
        try:
            shutil.copy2(src_file, dst_file)
            result['copied'].append(rel)
        except Exception as e:
            result['errors'].append(f"{rel}: {e}")
            result['not_copied'].append(rel)

    return result


# ---------------------------------------------------------------------------
# Write copy report
# ---------------------------------------------------------------------------
def write_copy_report(log_path: Path, run_id: str, row: dict, sections: list):
    """
    Write a per-run copy report.

    sections : list of dicts, each with keys:
        label     : section title (e.g. 'FUNCTIONAL Data_collection')
        src       : source path string
        dst       : destination path string
        result    : dict returned by copy_selected_files / copy_entire_dir
    """
    log_path.parent.mkdir(parents=True, exist_ok=True)
    ts = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

    with open(log_path, 'w') as f:
        f.write("=" * 70 + "\n")
        f.write("fUSI Data Copy Report\n")
        f.write("=" * 70 + "\n\n")
        f.write(f"Timestamp  : {ts}\n")
        f.write(f"func_run_id: {run_id}\n")
        f.write(f"project    : {row.get('project','')}\n")
        f.write(f"condition  : {row.get('condition','')}\n")
        f.write(f"subject_id : {row.get('subject_id','')}\n")
        f.write(f"session_id : {row.get('session_id','')}\n\n")

        for i, sec in enumerate(sections, 1):
            res = sec['result']
            n_all    = len(res['all_files'])
            n_copied = len(res['copied'])
            n_miss   = len(res['not_copied'])
            n_err    = len(res['errors'])

            f.write("-" * 70 + "\n")
            f.write(f"[{i}] {sec['label']}\n")
            if res['src_missing']:
                f.write(f"    SOURCE NOT FOUND: {sec['src']}\n\n")
                continue
            f.write(f"    Source : {sec['src']}\n")
            f.write(f"    Dest   : {sec['dst']}\n")
            f.write(f"    Total  : {n_all} file(s) | Copied: {n_copied} | Not copied: {n_miss}\n")
            if n_err:
                f.write(f"    Errors : {n_err}\n")
            f.write("\n")

            f.write(f"  COPIED ({n_copied} file(s))\n")
            if res['copied']:
                for fn in res['copied']:
                    f.write(f"    + {fn}\n")
            else:
                f.write("    (none)\n")
            f.write("\n")

            f.write(f"  NOT COPIED ({n_miss} file(s))\n")
            if res['not_copied']:
                for fn in res['not_copied']:
                    f.write(f"    - {fn}\n")
            else:
                f.write("    (none)\n")
            f.write("\n")

            if res['errors']:
                f.write(f"  ERRORS\n")
                for e in res['errors']:
                    f.write(f"    ! {e}\n")
                f.write("\n")


# ---------------------------------------------------------------------------
# Mode 1 — create fUSI_data_location_STORM.csv
# ---------------------------------------------------------------------------
def create_storm_csv():
    if not SRC_CSV.exists():
        raise FileNotFoundError(f"Source CSV not found: {SRC_CSV}")

    df = pd.read_csv(SRC_CSV, dtype=str).fillna('')

    # Drop the redundant functional_path column
    if 'functional_path' in df.columns:
        df = df.drop(columns=['functional_path'])

    # Prepend workflow columns
    df.insert(0, 'TOCOPY', '')
    df.insert(1, 'COPIED', '')

    # Compute per-row dest_root:  DEST_BASE/{project}{PROJ_SUFFIX}
    df['dest_root'] = df['project'].apply(
        lambda p: f'{DEST_BASE}/{p.strip()}{PROJ_SUFFIX}'
    )

    df.to_csv(DEST_CSV, index=False)

    print(f"\nCreated : {DEST_CSV}")
    print(f"Rows    : {len(df)}")
    print("\nNext step:")
    print("  Open fUSI_data_location_STORM.csv and set  TOCOPY = YES")
    print("  for every row you want to copy, then re-run this script.")


# ---------------------------------------------------------------------------
# Mode 2 — process rows marked TOCOPY = YES
# ---------------------------------------------------------------------------
def process_copy():
    df = pd.read_csv(DEST_CSV, dtype=str).fillna('')

    # Resolve run-id column name (handles both variants)
    run_col = 'func_run_id' if 'func_run_id' in df.columns else 'run_id'

    to_process = df[
        (df['TOCOPY'].str.strip().str.upper() == 'YES') &
        (df['COPIED'].str.strip().str.upper() != 'YES')
    ]

    if to_process.empty:
        print("Nothing to do — no rows with  TOCOPY = YES  and  COPIED ≠ YES.")
        return

    print(f"Rows to process : {len(to_process)}\n")

    for idx, row in to_process.iterrows():
        project    = row['project'].strip()
        condition  = row['condition'].strip()
        subject_id = row['subject_id'].strip()
        session_id = row['session_id'].strip()
        func_run   = row[run_col].strip()
        orig_root  = row['orig_root'].strip()
        anat_path  = row['anatomical_path'].strip().rstrip('/')

        print(f"  Row {idx + 2:>3}  |  {project} / {condition} / {subject_id} / {session_id} / {func_run}")

        # ----------------------------------------------------------------
        # Build source and destination paths
        # ----------------------------------------------------------------
        func_coll_src = f'/{orig_root}/{project}/Data_collection/{subject_id}/{session_id}/{func_run}'
        func_coll_dst = to_dest_path(func_coll_src)

        anat_parts    = Path(anat_path).parts   # (..., subject, session, run)
        anat_sub      = anat_parts[-3]
        anat_ses      = anat_parts[-2]
        anat_run      = anat_parts[-1]

        anat_coll_src = anat_path.replace('/Data_analysis/', '/Data_collection/')
        anat_coll_dst = to_dest_path(anat_coll_src)

        anat_anal_src = anat_path
        anat_anal_dst = to_dest_path(anat_path)

        # ----------------------------------------------------------------
        # Run the three copy operations
        # ----------------------------------------------------------------
        res_func_coll = copy_selected_files(func_coll_src, func_coll_dst, FUNC_COLLECTION_PATTERNS)
        res_anat_coll = copy_entire_dir(anat_coll_src, anat_coll_dst)
        res_anat_anal = copy_selected_files(anat_anal_src, anat_anal_dst, ANAT_ANALYSIS_PATTERNS)

        # ----------------------------------------------------------------
        # Print summary
        # ----------------------------------------------------------------
        for label, res in [
            (f'func  Data_collection  {subject_id}/{session_id}/{func_run}', res_func_coll),
            (f'anat  Data_collection  {anat_sub}/{anat_ses}/{anat_run}',     res_anat_coll),
            (f'anat  Data_analysis    {anat_sub}/{anat_ses}/{anat_run}',     res_anat_anal),
        ]:
            if res['src_missing']:
                print(f"    [ERROR]  {label}  — source not found")
            else:
                n_c = len(res['copied'])
                n_n = len(res['not_copied'])
                print(f"    [ok]     {label}  ({n_c} copied, {n_n} not copied)")

        # ----------------------------------------------------------------
        # Write log
        # ----------------------------------------------------------------
        ts_str   = datetime.now().strftime('%Y%m%d_%H%M%S')
        log_name = f'{func_run}_copy_report_{ts_str}.txt'
        log_path = LOGS_DIR / log_name

        sections = [
            dict(label='FUNCTIONAL Data_collection',
                 src=func_coll_src, dst=func_coll_dst, result=res_func_coll),
            dict(label='ANATOMICAL Data_collection (full copy)',
                 src=anat_coll_src, dst=anat_coll_dst, result=res_anat_coll),
            dict(label='ANATOMICAL Data_analysis',
                 src=anat_anal_src, dst=anat_anal_dst, result=res_anat_anal),
        ]
        write_copy_report(log_path, func_run, dict(row), sections)
        print(f"    [log]    {log_path.name}")

        # ----------------------------------------------------------------
        # Mark as copied only if no source-missing errors occurred
        # ----------------------------------------------------------------
        all_ok = not any(r['src_missing'] for r in [res_func_coll, res_anat_coll, res_anat_anal])
        if all_ok:
            df.at[idx, 'COPIED'] = 'YES'

    df.to_csv(DEST_CSV, index=False)
    n_done = (df['COPIED'].str.strip().str.upper() == 'YES').sum()
    print(f"\nDone. {DEST_CSV.name} updated  ({n_done} row(s) marked COPIED = YES)")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
if __name__ == '__main__':
    if not DEST_CSV.exists():
        print(f"'{DEST_CSV.name}' not found — creating it ...")
        create_storm_csv()
    else:
        print(f"Found '{DEST_CSV.name}' — processing TOCOPY = YES rows ...")
        process_copy()
