# Active Context: fUSI Data Management

## Current State (April 2, 2026)

**Status**: ✅ Steps 1–4 complete. Step 5 (launcher CSV) pending.

---

## What Was Done (April 2, 2026)

### Goal
Reorganise fUSI data from messy original locations (data06/data03) into a clean, unified structure on data03 so the pipeline launcher can work from a known location.

### Step 1 — Export Datapath.m  (`01_EXPORT_DATAPATH/`)
- Fixed `Datapath.m` → `Datapath_MOD.m` (manual corrections)
- Wrote `export_datapath_MOD_to_csv.m` → produces `original_Datapath_location.csv`
- CSV columns: `project, condition, subject_id, session_id, func_run_id, anatomical_path, orig_root`
- `anatomical_path` is kept as a full absolute path because anatomy may come from a different subject/session

### Step 2 — Test Data Structure  (`02_TEST_DATA_STRUCTURE/`)
- `check_subject_id_consistency.py` → verified subject/session/run IDs are consistent
- `check_functional_paths_construction.py`:
  - Check A: suffix (Data_analysis/subject/session/run) matches
  - Check B: full path reconstructable from columns  ✅ all passed
- Conclusion: `functional_path` column is redundant and can be dropped

### Step 3 — Decide destination structure
- Each project gets its own top-level folder on `/data03` with `_LC` suffix:
  - `/data06/fUSIMethodsPaper/...`       → `/data03/fUSIMethodsPaper_LC/...`
  - `/data06/fUSIEmotionalContagion/...` → `/data03/fUSIEmotionalContagion_LC/...`
  - `/data03/USS/...`                    → `/data03/USS_LC/...`
- Folder structure within each project mirrors origin: `Data_collection/`, `Data_analysis/`, etc.

### Step 4 — Copy script  (`03_CP_DATA/`)
- `cp_fUSI_orig2dest.py` — two-phase script
- **Phase 1** (first run): creates `fUSI_data_location_STORM.csv` from `original_Datapath_location.csv`
  - Drops `functional_path`, adds `TOCOPY`, `COPIED`, `dest_root`
  - `dest_root` = `/data03/{project}_LC` (per-row)
- **Phase 2** (subsequent runs): processes rows where `TOCOPY=YES` and `COPIED≠YES`
  - Copies **functional** `Data_collection`: `*.csv`, `*.xlsx`, `experiment_config.json`, `FUSI_data/fUS_block_PDI_float.bin`, `FUSI_data/*_PlaneWave_FUSI_data.mat`
  - Copies **anatomical** `Data_collection`: entire directory
  - Copies **anatomical** `Data_analysis`: `anatomic.mat`, `Transformation.mat`
  - Writes per-run log to `logs/run-XXXXXX_copy_report_YYYYMMDD_HHMMSS.txt`
  - Sets `COPIED=YES` on success
- Path translation function: `/{orig_root}/{project}/...` → `/{DEST_BASE}/{project}{PROJ_SUFFIX}/...`

---

## Next Step: Step 5 — Build launcher CSV

The `00_LAUNCHER/` module expects `fUSI_data_location_STORM.csv` with a specific schema used by `load_run_info.m`. We need to generate this from the `03_CP_DATA/fUSI_data_location_STORM.csv` once copying is done.

The launcher CSV must contain paths pointing to the NEW location (`data03`).

**Current state of `load_run_info.m`**: uses an OLD schema — needs rewriting to match the new path structure.

---

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| Keep `anatomical_path` as full path | Anatomy may be from different subject/session |
| Drop `functional_path` from launcher CSV | Fully reconstructable from other columns |
| `_LC` suffix on project folders | Distinguishes new clean copies from originals |
| Copy all `*.csv` from func collection | Covers all stimulation/behavioral/sync files |
| Copy entire anat `Data_collection` | Raw backup; no specific file filter needed |

---

## File Patterns Copied

**Functional `Data_collection/<run>/`**:
- `*.csv`, `*.xlsx`, `experiment_config.json`
- `FUSI_data/fUS_block_PDI_float.bin`
- `FUSI_data/*_PlaneWave_FUSI_data.mat`

**Anatomical `Data_analysis/<run>/`**:
- `anatomic.mat`, `Transformation.mat`

**Anatomical `Data_collection/<run>/`**:
- All files (entire directory copy)
