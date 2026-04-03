# 02_TEST_DATA_STRUCTURE — Checking the original data structure

## Overview

Before reorganizing the data, we needed to understand the structure of the original
data locations and verify their internal consistency. This folder contains the tools
and outputs of that check.

## Files

| File | Description |
|------|-------------|
| `original_Datapath_location.csv` | Copy of the CSV from `01_FIX_DATAPATH` — original paths on data06/data03 |
| `check_subject_id_consistency.py` | Python script that checks path consistency (see below) |
| `check_subject_id_consistency.txt` | Output report from the script |

---

## What `check_subject_id_consistency.py` does

The script reads `original_Datapath_location.csv` and runs **4 consistency checks**
by comparing subject/session information extracted from the path strings against
the values stored in the CSV columns.

The script extracts `subject_id` and `session_id` from a path by finding the
directory components immediately after `Data_analysis` or `Data_collection`:

```
/data06/fUSIMethodsPaper/Data_analysis/sub-methods02/ses-231215/run-115047/
                                        ^^^^^^^^^^^^  ^^^^^^^^^^
                                         subject_id   session_id
```

### The 4 checks

| Check | Question | What it catches |
|-------|---------|-----------------|
| **[S1]** | subject in `functional_path` ≠ subject in `anatomical_path`? | Intentional cross-subject anatomy reuse |
| **[S2]** | subject in path ≠ `subject_id` column in CSV? | Typos in the CSV |
| **[T1]** | session in `functional_path` ≠ session in `anatomical_path`? | Cross-session anatomy reuse |
| **[T2]** | session in path ≠ `session_id` column in CSV? | Typos in the CSV |

### Results (206 rows total)

```
[S1] func_path subject vs anat_path subject : 11 mismatch(es)   ← intentional
[S2] path subject_id vs CSV subject_id col  :  0 mismatch(es)   ← no typos ✓
[T1] func_path session vs anat_path session : 64 mismatch(es)   ← intentional
[T2] path session_id vs CSV session_id col  :  0 mismatch(es)   ← no typos ✓
```

### Interpretation of the mismatches

**[S1] — 11 mismatches (all `SOcFOS` in `EmotionalContagion`)**  
The CFOS animals (sub-CFOS03/04/05) did not have their own anatomical MRI scans.
Instead, anatomical scans from Dyad animals (sub-Dyad01, sub-Dyad02, ...) were used
as reference. This is **intentional and expected** — the CSV records both paths
explicitly, so the pipeline knows which anatomy to use for each functional run.

**[T1] — 64 mismatches (11 from SOcFOS above + 53 from `USS`)**  
For the USS project (USStimulation and ElectrodeTest), the anatomical scan is always
taken on day 1 of the experiment and reused for all subsequent recording sessions:
```
functional_path : .../animal1/ses-240917/run-122601/   ← day 2
anatomical_path : .../animal1/ses-240916/run-163205/   ← day 1
```
Again, **intentional** — one anatomy per animal across all recording days.
Notably, `MethodsPaper` and `EmotionalContagion` (VS/SO/FR/SS/SOFC) show
**zero cross-session mismatches**: each session has its own anatomy.

**S2 and T2 are both 0** — the CSV is internally consistent, no typos anywhere.

---

## Decided data structure for the new location (`/data03/fUSI_data_LC`)

### Principle

Preserve the same `<project>/Data_collection|analysis/<subject_id>/<session_id>/<run_id>/`
hierarchy as in the original data06 location, but unified under a single new root.
The path mapping is a simple root substitution — no renaming conventions needed.

### Structure

```
/data03/fUSI_data_LC/
├── fUSIMethodsPaper/
│   ├── Data_collection/<subject_id>/<session_id>/<run_id>/   ← raw acquisition files
│   └── Data_analysis/<subject_id>/<session_id>/<run_id>/    ← processed anat files
├── fUSIEmotionalContagion/
│   ├── Data_collection/<subject_id>/<session_id>/<run_id>/
│   └── Data_analysis/<subject_id>/<session_id>/<run_id>/
└── USS/
    ├── Data_collection/<subject_id>/<session_id>/<run_id>/
    └── Data_analysis/<subject_id>/<session_id>/<run_id>/
```

### Key difference from the original structure

In the original data, the three projects are **scattered across different roots**:
- `MethodsPaper` → `/data06/fUSIMethodsPaper/`
- `EmotionalContagion` → `/data06/fUSIEmotionalContagion/`
- `USS` → `/data03/USS/`  (already on data03, different root)

In the new location they are **all unified under one root**:
- `MethodsPaper` → `/data03/fUSI_data_LC/fUSIMethodsPaper/`
- `EmotionalContagion` → `/data03/fUSI_data_LC/fUSIEmotionalContagion/`
- `USS` → `/data03/fUSI_data_LC/USS/`

### Path substitution rules for the copy script

| Original root | New root |
|---|---|
| `/data06/fUSIMethodsPaper` | `/data03/fUSI_data_LC/fUSIMethodsPaper` |
| `/data06/fUSIEmotionalContagion` | `/data03/fUSI_data_LC/fUSIEmotionalContagion` |
| `/data03/USS` | `/data03/fUSI_data_LC/USS` |

---

## Concrete examples

### Example 1 — MethodsPaper, same-session anatomy (normal case)

CSV row:
```
project     : MethodsPaper
condition   : VisualTest
subject_id  : sub-methods02
session_id  : ses-231215
run_id      : run-115047
functional_path : /data06/fUSIMethodsPaper/Data_analysis/sub-methods02/ses-231215/run-115047/
anatomical_path : /data06/fUSIMethodsPaper/Data_analysis/sub-methods02/ses-231215/run-113409/
```

**Original location (data06)**:
```
/data06/fUSIMethodsPaper/
└── Data_collection/sub-methods02/ses-231215/run-115047/   ← functional (to copy)
└── Data_collection/sub-methods02/ses-231215/run-113409/   ← anat acquisition (to copy)
└── Data_analysis/sub-methods02/ses-231215/run-113409/     ← anat results (to copy)
```

**New location (data03)**:
```
/data03/fUSI_data_LC/fUSIMethodsPaper/
└── Data_collection/sub-methods02/ses-231215/run-115047/   ← functional
└── Data_collection/sub-methods02/ses-231215/run-113409/   ← anat acquisition
└── Data_analysis/sub-methods02/ses-231215/run-113409/     ← anat results
```

---

### Example 2 — USS, cross-session anatomy (anatomy from day 1 reused)

CSV row:
```
project     : USS
condition   : USStimulation
subject_id  : animal1
session_id  : ses-240917
run_id      : run-122601
functional_path : /data03/USS/Data_analysis/animal1/ses-240917/run-122601/
anatomical_path : /data03/USS/Data_analysis/animal1/ses-240916/run-163205/
```

**Original location (data03)**:
```
/data03/USS/
└── Data_collection/animal1/ses-240917/run-122601/   ← functional (to copy)
└── Data_collection/animal1/ses-240916/run-163205/   ← anat acquisition (to copy)
└── Data_analysis/animal1/ses-240916/run-163205/     ← anat results (to copy)
```

Note: the anatomy session (`ses-240916`) is different from the functional session
(`ses-240917`). The anatomy folder is copied **once** and reused by all functional
runs across sessions ses-240917, ses-240918, ses-240920.

**New location (data03)**:
```
/data03/fUSI_data_LC/USS/
└── Data_collection/animal1/ses-240917/run-122601/   ← functional
└── Data_collection/animal1/ses-240916/run-163205/   ← anat acquisition
└── Data_analysis/animal1/ses-240916/run-163205/     ← anat results
```
