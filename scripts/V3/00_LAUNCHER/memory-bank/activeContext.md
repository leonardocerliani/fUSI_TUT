# Active Context: fUSI Pipeline Launcher

## Current State (April 2, 2026)

**Status**: ✅ Adapted to new data structure from `00_DATA_MANAGEMENT`

---

## What Changed (April 2, 2026)

The launcher was originally designed around a simple CSV schema:
```
experiment, project_id, session_id, func_run, anatomic_run, data_root
```
This schema assumed that anatomy and function always live in the same `project_id/session_id/` folder — which is NOT true for:
- USS: anatomy from first session reused for all subsequent sessions
- EmotionalContagion SOcFOS: anatomy from a completely different subject

### New CSV schema (copied from `00_DATA_MANAGEMENT/03_CP_DATA/fUSI_data_location_STORM.csv`)
```
TOCOPY, COPIED, project, condition, subject_id, session_id,
func_run_id, anatomical_path, orig_root, dest_root
```

Key points:
- `anatomical_path` = full ORIGINAL path to the anat Data_analysis folder (e.g. `/data06/fUSIMethodsPaper/Data_analysis/sub-methods02/ses-231215/run-113409/`)
- `dest_root` = per-row destination root (e.g. `/data03/fUSIMethodsPaper_LC`)
- TOCOPY/COPIED/orig_root are present but ignored by the launcher

### How to supply the launcher CSV
1. Copy `00_DATA_MANAGEMENT/03_CP_DATA/fUSI_data_location_STORM.csv` to `00_LAUNCHER/fUSI_data_location_STORM.csv`
2. The launcher reads it as-is — rows that haven't been copied yet are included but will fail at runtime (paths won't exist on data03)

---

## `load_run_info.m` — New Logic

**Required columns**: `func_run_id, project, subject_id, session_id, anatomical_path, dest_root`

**Row matching**: by `func_run_id` (was `func_run`)

**Anatomical path parsing**: splits `anatomical_path` on `/`, takes last 3 non-empty tokens as `anat_sub / anat_ses / anat_run` — this handles cross-session and cross-subject anatomy correctly.

**Path construction**:
```matlab
func_collection = {dest_root}/Data_collection/{subject_id}/{session_id}/{func_run_id}
func_analysis   = {dest_root}/Data_analysis/{subject_id}/{session_id}/{func_run_id}
anat_collection = {dest_root}/Data_collection/{anat_sub}/{anat_ses}/{anat_run}
anat_analysis   = {dest_root}/Data_analysis/{anat_sub}/{anat_ses}/{anat_run}
```

**runInfo fields**: `project, condition, subject_id, session_id, func_run_id, dest_root, paths.*`

---

## `fusi_pipeline_launcher.m` — Changes

| Old | New |
|-----|-----|
| `runInfo.experiment` | `runInfo.project` |
| `runInfo.anatomic_run` | removed from display |
| `runInfo.data_root` | `runInfo.dest_root` |
| experiment check: `'MethodsPaper'` | `'fUSIMethodsPaper'` |
| `runInfo.func_run` (in run_analysis) | `runInfo.func_run_id` |

---

## What Still Works (unchanged)
- `check_reconstruction_ready.m` — uses `runInfo.paths.func_collection` / `.func_analysis` ✅
- `check_preprocessing_ready.m` — uses `runInfo.paths.func_analysis` / `.anat_analysis` ✅
- `check_analysis_ready.m` — unchanged ✅
- `display_status_menu.m` — unchanged ✅
- All stage execution wrappers — unchanged ✅

---

## Usage

```matlab
% In fusi_pipeline_launcher.m, set:
CSV_FILENAME = 'fUSI_data_location_STORM.csv';

% Then run:
fusi_pipeline_launcher('run-115047')
```

---

## Important Constraints

1. The launcher CSV must be **manually copied** from `00_DATA_MANAGEMENT/03_CP_DATA/` to `00_LAUNCHER/` before use
2. Only rows with `COPIED = YES` will have actual data on disk; others will show `[⚠️]` (missing files)
3. Atlas path is always `{scriptsDir}/allen_brain_atlas` (relative to scripts root, unchanged)
4. Analysis stage only works for `project = 'fUSIMethodsPaper'`
