"""
check_subject_id_consistency.py

Verifies that the subject_id AND session_id embedded in functional_path
and anatomical_path are consistent with each other AND with the
corresponding columns in the CSV.

The expected path structure is:
    .../Data_analysis/<subject_id>/<session_id>/<run_id>/

Usage:
    python check_subject_id_consistency.py

Output:
    check_subject_id_consistency.txt  (written next to this script)
"""

import pandas as pd
from pathlib import Path


def extract_from_path(path, offset):
    """
    Return the directory component at position `offset` after
    'Data_analysis' or 'Data_collection' in the given path string.

    offset=1 → subject_id   (1 step after the marker)
    offset=2 → session_id   (2 steps after the marker)

    Example (offset=1):
        /data06/fUSIMethodsPaper/Data_analysis/sub-methods02/ses-231215/run-115047/
        → 'sub-methods02'

    Example (offset=2):
        /data06/fUSIMethodsPaper/Data_analysis/sub-methods02/ses-231215/run-115047/
        → 'ses-231215'

    Returns None if the marker directory is not found or index is out of range.
    """
    parts = Path(str(path).strip()).parts
    for i, part in enumerate(parts):
        if part in ('Data_analysis', 'Data_collection') and i + offset < len(parts):
            return parts[i + offset]
    return None


def extract_subject_from_path(path):
    return extract_from_path(path, offset=1)


def extract_session_from_path(path):
    return extract_from_path(path, offset=2)


# ---------------------------------------------------------------------------
# Load CSV
# ---------------------------------------------------------------------------
csv_path = Path(__file__).parent / 'original_Datapath_location.csv'
df = pd.read_csv(csv_path)

# ---------------------------------------------------------------------------
# Extract subject_id and session_id from the actual path strings
# ---------------------------------------------------------------------------
df['func_subject'] = df['functional_path'].apply(extract_subject_from_path)
df['anat_subject'] = df['anatomical_path'].apply(extract_subject_from_path)
df['func_session'] = df['functional_path'].apply(extract_session_from_path)
df['anat_session'] = df['anatomical_path'].apply(extract_session_from_path)

# ---------------------------------------------------------------------------
# Identify mismatches — subject_id
# ---------------------------------------------------------------------------
# S1. func path subject != anat path subject
mask_subj_path = df['func_subject'] != df['anat_subject']
# S2. path subject (where func==anat) != CSV subject_id column
mask_subj_csv  = (~mask_subj_path) & (df['func_subject'] != df['subject_id'])

# ---------------------------------------------------------------------------
# Identify mismatches — session_id
# ---------------------------------------------------------------------------
# T1. func path session != anat path session
mask_sess_path = df['func_session'] != df['anat_session']
# T2. path session (where func==anat) != CSV session_id column
mask_sess_csv  = (~mask_sess_path) & (df['func_session'] != df['session_id'])

mismatches_subj_path = df[mask_subj_path]
mismatches_subj_csv  = df[mask_subj_csv]
mismatches_sess_path = df[mask_sess_path]
mismatches_sess_csv  = df[mask_sess_csv]

# ---------------------------------------------------------------------------
# Write results to txt
# ---------------------------------------------------------------------------
output_path = Path(__file__).parent / 'check_subject_id_consistency.txt'

with open(output_path, 'w') as f:

    f.write("=" * 70 + "\n")
    f.write("Subject ID & Session ID Consistency Check\n")
    f.write("=" * 70 + "\n\n")
    f.write(f"CSV file     : {csv_path.name}\n")
    f.write(f"Total rows   : {len(df)}\n\n")

    f.write("--- subject_id ---\n")
    f.write(f"[S1] func_path subject vs anat_path subject : {len(mismatches_subj_path)} mismatch(es)\n")
    f.write(f"[S2] path subject_id vs CSV subject_id col  : {len(mismatches_subj_csv)} mismatch(es)\n\n")

    f.write("--- session_id ---\n")
    f.write(f"[T1] func_path session vs anat_path session : {len(mismatches_sess_path)} mismatch(es)\n")
    f.write(f"[T2] path session_id vs CSV session_id col  : {len(mismatches_sess_csv)} mismatch(es)\n\n")

    all_ok = all(len(m) == 0 for m in [
        mismatches_subj_path, mismatches_subj_csv,
        mismatches_sess_path, mismatches_sess_csv
    ])
    if all_ok:
        f.write("OK: subject_id and session_id are fully consistent in all rows.\n")

    # --- S1: func path subject != anat path subject ---
    if len(mismatches_subj_path) > 0:
        f.write("-" * 70 + "\n")
        f.write("[S1] Functional path subject ≠ Anatomical path subject\n")
        f.write("-" * 70 + "\n\n")
        for _, row in mismatches_subj_path.iterrows():
            f.write(f"  Row {row.name + 2:>3}  |  condition={row['condition']}  project={row['project']}\n")
            f.write(f"           func subject : {row['func_subject']}\n")
            f.write(f"           anat subject : {row['anat_subject']}\n")
            f.write(f"           functional_path : {row['functional_path']}\n")
            f.write(f"           anatomical_path : {row['anatomical_path']}\n\n")

    # --- S2: path subject != CSV subject_id column ---
    if len(mismatches_subj_csv) > 0:
        f.write("-" * 70 + "\n")
        f.write("[S2] Path subject_id ≠ CSV subject_id column\n")
        f.write("-" * 70 + "\n\n")
        for _, row in mismatches_subj_csv.iterrows():
            f.write(f"  Row {row.name + 2:>3}  |  condition={row['condition']}  project={row['project']}\n")
            f.write(f"           path subject_id : {row['func_subject']}\n")
            f.write(f"           CSV  folder     : {row['folder']}\n\n")

    # --- T1: func path session != anat path session ---
    if len(mismatches_sess_path) > 0:
        f.write("-" * 70 + "\n")
        f.write("[T1] Functional path session ≠ Anatomical path session\n")
        f.write("-" * 70 + "\n\n")
        for _, row in mismatches_sess_path.iterrows():
            f.write(f"  Row {row.name + 2:>3}  |  condition={row['condition']}  project={row['project']}\n")
            f.write(f"           func session : {row['func_session']}\n")
            f.write(f"           anat session : {row['anat_session']}\n")
            f.write(f"           functional_path : {row['functional_path']}\n")
            f.write(f"           anatomical_path : {row['anatomical_path']}\n\n")

    # --- T2: path session != CSV session_id column ---
    if len(mismatches_sess_csv) > 0:
        f.write("-" * 70 + "\n")
        f.write("[T2] Path session_id ≠ CSV session_id column\n")
        f.write("-" * 70 + "\n\n")
        for _, row in mismatches_sess_csv.iterrows():
            f.write(f"  Row {row.name + 2:>3}  |  condition={row['condition']}  project={row['project']}\n")
            f.write(f"           path session_id : {row['func_session']}\n")
            f.write(f"           CSV  session_id : {row['session_id']}\n\n")

print(f"Done. Results written to: {output_path}")
