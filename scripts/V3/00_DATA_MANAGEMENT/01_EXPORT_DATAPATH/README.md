# 01_FIX_DATAPATH — Exporting original data locations to CSV

## Overview

The information about experiments and the correspondence between functional and anatomical sessions was previously encoded in `Datapath.m`. This folder documents how that file was fixed and exported to a clean CSV for downstream use.

## Files

| File | Description |
|------|-------------|
| `Datapath.m` | **Original** file — contains bugs (do not use) |
| `Datapath_MOD.m` | **Hand-edited** fixed version of `Datapath.m` (see bug fix report below) |
| `export_datapath_MOD_to_csv.m` | Calls `Datapath_MOD` for all conditions and writes `original_Datapath_location.csv` |
| `original_Datapath_location.csv` | Output CSV with original data locations on `data06` / `data03` |

## How to regenerate the CSV

Run from MATLAB, from within this directory:

```matlab
cd('/data00/leonardo/fUSI_TUT/scripts/V3/00_DATA_MANAGEMENT/01_FIX_DATAPATH')
export_datapath_MOD_to_csv()
```

This will (over)write `original_Datapath_location.csv`.

## CSV schema

```
project, condition, folder, session_id, run_id, functional_path, anatomical_path, data_root
```

Paths in `functional_path` and `anatomical_path` point to the **original locations** on the server (`Data_analysis` subdirectory in `data06` or `data03`).

---

## How `Datapath_MOD.m` was created

`Datapath_MOD.m` was created by **manually editing** `Datapath.m`. The bugs found and fixed are described in detail in the Bug Fix Report below. The two files (`Datapath.m` and `Datapath_MOD.m`) are kept side-by-side for reference.

Key changes at a glance:
- All variables initialized as empty at the top of the function
- `defaultEmotionalContagionAnatPath` local variable created for shared anatomical paths
- Explicit `subAnatPath` assignments added for all conditions (VS, SO, FR, SS, SOcFOS, SOFC)
- Windows path conversion and `mkdir` calls commented out (not needed for CSV export)
- Internal function name changed from `Datapath` to `Datapath_MOD` to match the filename

---

## Bug Fix Report: Datapath.m → Datapath_MOD.m

**Date:** March 27, 2026  
**Files modified:**
- `Datapath.m` → fixed version saved as `Datapath_MOD.m`
- `export_datapath_to_csv.m` → renamed to `export_datapath_MOD_to_csv.m`

### Summary

The original `Datapath.m` had multiple issues that caused errors when trying to export its content to CSV. The primary errors included dimension mismatches, file system operation failures, and improper cell array handling.

---

### 1. Problematic Pre-initialization in Datapath.m

#### Problem
At the beginning of `Datapath.m`, `subAnatPath` was hard-coded with 12 pre-defined paths before the `switch` block:

```matlab
% Old code (PROBLEMATIC)
subAnatPath{1} = '/data06/fUSIEmotionalContagion/Data_analysis/sub-Dyad01/ses-230329/run-122938';
% ... (12 entries total)
resultPath  = ['/data06/fUSIEmotionalContagion/Data_analysis/sub-Group/' cond];
```

This caused **dimension mismatch errors** when conditions assigned their own `subAnatPath` arrays of different lengths (e.g. `VisualTestMultiSlice` has 30 entries).

#### Solution
Initialized all variables as empty at the function start; moved the 12 anatomical paths into a `defaultEmotionalContagionAnatPath` local variable:

```matlab
subAnatPath = {};
subDataPath = {};
resultPath = '';

defaultEmotionalContagionAnatPath = {
    '/data06/fUSIEmotionalContagion/Data_analysis/sub-Dyad01/ses-230329/run-122938';
    % ... (12 entries)
};
```

---

### 2. File System Operations Causing Errors

#### Problem
`Datapath.m` contained code to convert Unix paths to Windows format and to `mkdir` result directories. These caused **"Read-only file system" errors** during CSV export.

#### Solution
Both blocks commented out in `Datapath_MOD.m`:

```matlab
% Path adjustments for Windows systems - DISABLED FOR CSV EXPORT
% if ispc ... end

% Create result folder if it does not exist - DISABLED FOR CSV EXPORT
% if ~isempty(resultPath) && ~exist(resultPath, 'dir')
%     mkdir(resultPath);
% end
```

---

### 3. Missing subAnatPath Assignments

#### Problem
Conditions VS, SO, FR, SS, SOcFOS, and SOFC did not set `subAnatPath`, relying on the (now-removed) pre-initialization.

#### Solution
Added explicit assignments for all conditions:

```matlab
case 'VS'
    subDataPath = { ... };
    subAnatPath = defaultEmotionalContagionAnatPath;  % all 12
    resultPath = fullfile('/data06/fUSIEmotionalContagion/Data_analysis/sub-Group', cond);

case 'SOcFOS'
    subDataPath = { ... };  % 11 entries
    subAnatPath = defaultEmotionalContagionAnatPath(1:11);  % first 11
```

---

### 4. Cell Array Row Appending in export_datapath_to_csv.m

#### Problem
Using `rows(end+1, :) = {...}` on an empty cell array caused dimension errors.

#### Solution
Switched to an explicit row counter:

```matlab
rowCount = 0;
for i = 1:n
    rowCount = rowCount + 1;
    rows{rowCount, 1} = cond;
    rows{rowCount, 2} = project;
    % ...
end
```

---

### 5. Improved subAnatPath Handling in export_datapath_MOD_to_csv.m

Added robust checks for empty, non-cell, and row-oriented `subAnatPath`:

```matlab
if isempty(subAnatPath)
    subAnatPath = repmat({''}, n, 1);
elseif ~iscell(subAnatPath)
    subAnatPath = {subAnatPath};
end
if isrow(subAnatPath)
    subAnatPath = subAnatPath';
end
if length(subAnatPath) ~= n
    subAnatPath = repmat(subAnatPath(1), n, 1);
end
```

---

### Testing Results

After all fixes, the script successfully exports data from all 11 conditions:
- ✅ VisualTest
- ✅ ShockTest
- ✅ VS
- ✅ SO
- ✅ FR
- ✅ SS
- ✅ SOcFOS
- ✅ SOFC
- ✅ VisualTestMultiSlice
- ✅ USStimulation
- ✅ ElectrodeTest
