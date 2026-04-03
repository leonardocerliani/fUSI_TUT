"""
check_functional_paths_construction.py

Two checks on the CSV:

[A] Suffix check (original check):
    Verifies that the last part of functional_path starting from 'Data_analysis'
    matches Data_analysis/<subject_id>/<session_id>/<func_run_id>

[B] Full path reconstruction check:
    Verifies that the full path can be reconstructed from CSV columns alone:
        /{orig_root}/{project}/Data_analysis/{subject_id}/{session_id}/{func_run_id}
    and that this matches functional_path exactly.

A 0-mismatch result for [B] means functional_path is fully redundant and can be
dropped from the CSV — it can always be rebuilt from the other columns.

Usage:
    python check_functional_paths_construction.py

Output:
    check_functional_paths_construction.txt  (written next to this script)
"""

import pandas as pd
from pathlib import Path


# ---------------------------------------------------------------------------
# Load CSV
# ---------------------------------------------------------------------------
csv_path = Path(__file__).parent / 'original_Datapath_location.csv'
df = pd.read_csv(csv_path)

# Handle column name variants
run_col  = 'func_run_id' if 'func_run_id' in df.columns else 'run_id'
root_col = 'orig_root'   if 'orig_root'   in df.columns else 'data_root'

# ---------------------------------------------------------------------------
# Check A: suffix check (Data_analysis/subject/session/run)
# ---------------------------------------------------------------------------
mismatches_A = []

for idx, row in df.iterrows():
    func_path  = str(row['functional_path']).strip().rstrip('/')
    subject_id = str(row['subject_id']).strip()
    session_id = str(row['session_id']).strip()
    run_id     = str(row[run_col]).strip()

    expected_suffix = f'Data_analysis/{subject_id}/{session_id}/{run_id}'

    parts = Path(func_path).parts
    try:
        da_idx = next(i for i, p in enumerate(parts) if p == 'Data_analysis')
        actual_suffix = '/'.join(parts[da_idx:])
    except StopIteration:
        mismatches_A.append({
            'row':      idx + 2,
            'issue':    'No Data_analysis component found in functional_path',
            'expected': expected_suffix,
            'actual':   func_path,
            'project':  row['project'],
            'condition': row['condition'],
        })
        continue

    if actual_suffix != expected_suffix:
        mismatches_A.append({
            'row':      idx + 2,
            'issue':    'Suffix mismatch',
            'expected': expected_suffix,
            'actual':   actual_suffix,
            'project':  row['project'],
            'condition': row['condition'],
        })

# ---------------------------------------------------------------------------
# Check B: full path reconstruction
#   /{orig_root}/{project}/Data_analysis/{subject_id}/{session_id}/{func_run_id}
# ---------------------------------------------------------------------------
mismatches_B = []

for idx, row in df.iterrows():
    func_path  = str(row['functional_path']).strip().rstrip('/')
    subject_id = str(row['subject_id']).strip()
    session_id = str(row['session_id']).strip()
    run_id     = str(row[run_col]).strip()
    project    = str(row['project']).strip()
    orig_root  = str(row[root_col]).strip()

    reconstructed = f'/{orig_root}/{project}/Data_analysis/{subject_id}/{session_id}/{run_id}'

    if reconstructed != func_path:
        mismatches_B.append({
            'row':          idx + 2,
            'reconstructed': reconstructed,
            'actual':       func_path,
            'project':      project,
            'condition':    row['condition'],
        })

# ---------------------------------------------------------------------------
# Write report
# ---------------------------------------------------------------------------
output_path = Path(__file__).parent / 'check_functional_paths_construction.txt'

with open(output_path, 'w') as f:

    f.write("=" * 70 + "\n")
    f.write("Functional Path Construction Check\n")
    f.write("=" * 70 + "\n\n")
    f.write(f"CSV file     : {csv_path.name}\n")
    f.write(f"Run column   : {run_col}\n")
    f.write(f"Root column  : {root_col}\n")
    f.write(f"Total rows   : {len(df)}\n\n")

    # --- Check A ---
    f.write("-" * 70 + "\n")
    f.write("[A] Suffix check: Data_analysis/<subject>/<session>/<run>\n")
    f.write(f"    Mismatches : {len(mismatches_A)}\n")
    f.write("-" * 70 + "\n\n")
    if len(mismatches_A) == 0:
        f.write("    OK: All functional_path suffixes match.\n\n")
    else:
        for m in mismatches_A:
            f.write(f"  Row {m['row']:>3}  |  {m.get('project','')}  /  {m.get('condition','')}\n")
            f.write(f"           issue    : {m['issue']}\n")
            f.write(f"           expected : {m['expected']}\n")
            f.write(f"           actual   : {m['actual']}\n\n")

    # --- Check B ---
    f.write("-" * 70 + "\n")
    f.write("[B] Full path reconstruction check:\n")
    f.write(f"    /{{{root_col}}}/{{project}}/Data_analysis/{{subject_id}}/{{session_id}}/{{func_run_id}}\n")
    f.write(f"    Mismatches : {len(mismatches_B)}\n")
    f.write("-" * 70 + "\n\n")
    if len(mismatches_B) == 0:
        f.write("    OK: functional_path is fully redundant — can be built from columns.\n\n")
    else:
        for m in mismatches_B:
            f.write(f"  Row {m['row']:>3}  |  {m.get('project','')}  /  {m.get('condition','')}\n")
            f.write(f"           reconstructed : {m['reconstructed']}\n")
            f.write(f"           actual        : {m['actual']}\n\n")

print(f"Done. Results written to: {output_path}")
