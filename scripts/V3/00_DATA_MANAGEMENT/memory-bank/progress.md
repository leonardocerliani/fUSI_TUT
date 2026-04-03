# Progress: fUSI Data Management

## Current Status

**Status**: Steps 1–4 complete ✅ | Step 5 pending
**Last Updated**: April 2, 2026

---

## Completed

### ✅ Step 1 — Export Datapath.m  (`01_EXPORT_DATAPATH/`)
- `Datapath.m` inspected and fixed → `Datapath_MOD.m`
- `export_datapath_MOD_to_csv.m` written and tested
- Outputs `original_Datapath_location.csv` with columns:
  `project, condition, subject_id, session_id, func_run_id, anatomical_path, orig_root`

### ✅ Step 2 — Test Data Structure  (`02_TEST_DATA_STRUCTURE/`)
- `check_subject_id_consistency.py` — all IDs consistent ✅
- `check_functional_paths_construction.py`:
  - Check A (suffix): 0 mismatches ✅
  - Check B (full path reconstruction from columns): 0 mismatches ✅
- Result: `functional_path` column is redundant and is dropped downstream

### ✅ Step 3 — Destination structure decided
- `/data03/{project}_LC/` per project (mirrors source folder hierarchy)
- Config in script: `DEST_BASE = '/data03'`, `PROJ_SUFFIX = '_LC'`

### ✅ Step 4 — Copy script  (`03_CP_DATA/`)
- `cp_fUSI_orig2dest.py` functional and tested
- `fUSI_data_location_STORM.csv` generated with `TOCOPY/COPIED/dest_root` columns
- Selective file copy with pattern matching
- Per-run logs written to `logs/`
- `COPIED=YES` set only on full success

---

## Pending

### ⏳ Step 5 — Build launcher CSV  (`00_LAUNCHER/`)
Once data is copied to data03, produce the `fUSI_data_location_STORM.csv` used by the pipeline launcher.

Requirements:
- Contains only COPIED=YES rows (or all rows with dest paths)
- Paths point to the new `/data03/{project}_LC/` location
- Schema must match what `load_run_info.m` expects
- `load_run_info.m` itself may need rewriting (currently uses old schema)

---

## Known Issues / Notes

- `01_FIX_DATAPATH/` was renamed to `01_EXPORT_DATAPATH/` during the session
- The `fUSI_data_location_STORM.csv` in `03_CP_DATA/` is the **copy tracking CSV**, not the launcher CSV — they serve different purposes
- The `00_LAUNCHER/memory-bank/` still contains docs for the OLD launcher project; will be updated in Step 5
- For USS experiments, anatomy comes from first session only; all functional runs reference the same anatomical run
- For EmotionalContagion SOcFOS condition, anatomy comes from a different subject (sub-Dyad instead of sub-CFOS)

---

## File Reference

| File | Purpose |
|------|---------|
| `01_EXPORT_DATAPATH/original_Datapath_location.csv` | Master map of all original file locations |
| `02_TEST_DATA_STRUCTURE/check_*.txt` | Consistency check reports |
| `03_CP_DATA/fUSI_data_location_STORM.csv` | Copy tracking CSV (TOCOPY/COPIED workflow) |
| `03_CP_DATA/logs/*.txt` | Per-run copy reports |
| `00_LAUNCHER/fUSI_data_location_STORM.csv` | Launcher CSV (Step 5 — to be built) |
