# fUSI Pipeline Launcher

## Overview

The **fUSI Pipeline Launcher** is a unified command-line interface for the complete fUSI data processing pipeline. It orchestrates three main stages:

1. **Stage 02: Reconstruction** - Convert raw data to PDI.mat
2. **Stage 03: Preprocessing** - Process PDI.mat to prepPDI.mat  
3. **Stage 04: Analysis** - Run GLM analysis on prepPDI.mat

**👉 NB: The anatomical reconstruction** is a process that is carrid out at experiment time, therefore it is assumed that at the moment of starting the functional reconstruction / preprocessing / analysis, the correct anatomical acquisition has been already reconstructed (inlcuding the choice of the slice for functional acquisition) and placed in the corresponding subfolder of the `Data_analysis` tree.

The launcher automatically:
- ✅ Checks which stages are ready to run
- ✅ Validates all required input files
- ✅ Manages paths across stages
- ✅ Provides clear status feedback
- ✅ Prevents accidental overwrites

## Getting Started

### Prerequisites

Before using the launcher, ensure you have:
- MATLAB installed (tested on R2020b+)
- Your data organized in the expected directory structure (see below)
- A CSV file with run information (`fUSI_data_location_LOCAL.csv` or `fUSI_data_location_STORM.csv`)

### Directory Structure

Your data should be organized as follows:
```
data_root/
├── Data_collection/
│   └── ses-YYMMDD/
│       ├── run-XXXXXX-anat/
│       └── run-XXXXXX-func/
│           ├── experiment_config.json
│           ├── TTL*.csv
│           ├── DAQ.csv (or NIDAQ.csv)
│           └── FUSI_data/
│               ├── fUS_block_PDI_float.bin
│               └── *_PlaneWave_FUSI_data.mat
└── Data_analysis/
    └── ses-YYMMDD/
        ├── run-XXXXXX-anat/
        │   ├── anatomic.mat
        │   └── Transformation.mat
        └── run-XXXXXX-func/
            ├── PDI.mat (created by reconstruction)
            └── prepPDI.mat (created by preprocessing)
```

## Quick Start Tutorial

### Step 1: Configure Your CSV File

The launcher uses a CSV file to locate your data. You can have different CSV files for different environments.

**Edit** `CSV_FILENAME` at the top of `fusi_pipeline_launcher.m`:

```matlab
% For remote server (STORM)
CSV_FILENAME = 'fUSI_data_location_STORM.csv';

% For local machine
CSV_FILENAME = 'fUSI_data_location_local.csv';
```

**CSV Format**:
```csv
experiment,session_id,func_run,anatomic_run,data_root
MethodsPaper,ses-231215,run-115047,run-113409,/path/to/data
```

### Step 2: Launch the Pipeline

```matlab
cd 000_LAUNCHER
fusi_pipeline_launcher('run-115047')
```

**From MATLAB command window**:
```matlab
cd /path/to/scripts/V3
fusi_pipeline_launcher('run-115047')
```

The launcher will:
1. Load run information from CSV
2. Check file availability for each stage
3. Display an interactive status menu
4. Execute your selected stage

### Step 3: Understand the Status Display

The launcher shows clear status for each stage:

```
[✅] Functional Reconstruction
    ✅ Reconstruction already completed

[ ] Functional Preprocessing  
    👍 Ready to run

[⚠️] Analysis: MethodPaper
    Missing 1 required file(s) ⚠️
```

**Status Icons**:
- `[✅]` = Stage completed (output file exists)
- `[ ]` = Ready to run (all input files present)
- `[⚠️]` = Cannot run (missing required files)

### Step 4: Select and Run a Stage

Enter the number corresponding to the stage you want to run (1, 2, or 3).

The launcher will:
- Verify all requirements are met
- Warn if output already exists (prevents accidental overwrites)
- Execute the pipeline stage
- Display progress and results

## Complete Workflow Example

Here's a typical workflow for processing a new run:

```matlab
% 1. Start with a new run
fusi_pipeline_launcher('run-115047')

% Expected first-time status:
% [ ] Reconstruction - Ready to run
% [⚠️] Preprocessing - Missing files  
% [⚠️] Analysis - Missing files

% 2. Select option 1 (Reconstruction)
% → Creates PDI.mat

% 3. Run launcher again
fusi_pipeline_launcher('run-115047')

% Expected status after reconstruction:
% [✅] Reconstruction - Completed
% [ ] Preprocessing - Ready to run
% [⚠️] Analysis - Missing files

% 4. Select option 2 (Preprocessing)
% → Creates prepPDI.mat

% 5. Run launcher again  
fusi_pipeline_launcher('run-115047')

% Expected status after preprocessing:
% [✅] Reconstruction - Completed
% [✅] Preprocessing - Completed
% [ ] Analysis - Ready to run

% 6. Select option 3 (Analysis)
% → Creates analysis results in prepPDI.mat
```

## Running Stages Standalone (Advanced)

While the **launcher is recommended** for most users, individual pipeline functions can also be called directly if you prefer manual control:

### Reconstruction (Standalone)
```matlab
cd 02_Func_Reconstruction
func_collection_path = '/path/to/Data_collection/ses-XXX/run-XXX';
func_analysis_path = '/path/to/Data_analysis/ses-XXX/run-XXX';
do_reconstruct_functional(func_collection_path, func_analysis_path);
```

### Preprocessing (Standalone)
```matlab
cd 03_Func_Preprocessing
anat_analysis_path = '/path/to/Data_analysis/ses-XXX/run-XXX-anat';
func_analysis_path = '/path/to/Data_analysis/ses-XXX/run-XXX-func';
atlasPath = '/path/to/allen_brain_atlas';
do_preprocessing(anat_analysis_path, func_analysis_path, atlasPath);
```

### Analysis (Standalone)
```matlab
cd 04_Analysis_MethodPaper
func_analysis_path = '/path/to/Data_analysis/ses-XXX/run-XXX';
do_analysis_methods_paper(func_analysis_path);
```

**Note**: When running standalone, you must:
- Manually manage all paths
- Ensure required files exist
- Track which stages have been completed
- Handle errors yourself

**The launcher automates all of this** and provides better error messages!

## Understanding Each Stage

### Stage 02: Functional Reconstruction

**Purpose**: Convert raw fUSI data to PDI.mat format

**Required Input Files** (in Data_collection):
- `experiment_config.json` - Experiment configuration
- `TTL*.csv` - TTL synchronization data
- `DAQ.csv` or `NIDAQ.csv` - Data acquisition log
- `FUSI_data/fUS_block_PDI_float.bin` - Raw fUSI binary
- `FUSI_data/*_PlaneWave_FUSI_data.mat` - Scan parameters

**Output**: 
- `PDI.mat` in Data_analysis directory

**What it does**:
- Loads raw binary fUSI data
- Synchronizes with TTL signals
- Processes experiment events
- Saves structured PDI data

### Stage 03: Functional Preprocessing

**Purpose**: Preprocess PDI data for analysis

**Required Input Files**:
- `PDI.mat` (from reconstruction)
- `anatomic.mat` (from anatomical registration)
- `Transformation.mat` (from anatomical registration)
- `allen_brain_atlas.mat` (atlas)

**Output**:
- `prepPDI.mat` in Data_analysis directory

**What it does**:
- Applies spatial filtering
- Performs motion correction
- Registers to atlas
- Creates brain mask
- Temporal filtering

### Stage 04: Analysis (MethodPaper)

**Purpose**: Run GLM analysis on preprocessed data

**Required Input Files**:
- `prepPDI.mat` (from preprocessing)

**Output**:
- Analysis results saved back into `prepPDI.mat` (as `data.glm_results`)

**What it does**:
- Creates predictors from stimuli and behavior
- Fits three GLM models:
  - M1: Stimuli while stationary
  - M2: All stimuli
  - M3: Stimuli + running + interaction
- Visualizes results
- Saves beta maps and statistics

**Note**: This analysis only works with `experiment = 'MethodsPaper'` runs.

## Troubleshooting

### "Run ID not found in CSV"
- Check that your CSV file has the correct run ID
- Verify CSV_FILENAME is set correctly in the launcher
- Ensure the CSV file is in the 000_LAUNCHER directory

### "Missing required files"
- Check the detailed missing files list
- Verify your directory structure matches the expected format
- For preprocessing: ensure anatomical registration was run first
- For analysis: ensure preprocessing was completed

### "This analysis cannot be carried out on run-XXX"
- The MethodPaper analysis only works on MethodsPaper experiment types
- Check the `experiment` column in your CSV file
- Use a different analysis for other experiment types

### Path warnings
- Always run the launcher from the V3 directory
- Use absolute paths in your CSV file
- Verify the Data_collection and Data_analysis directories exist

## Current Implementation Status

✅ **Fully Implemented**:
- CSV-based run management
- Complete file checking for all stages
- Interactive status display with icons
- Overwrite protection
- Experiment type validation
- All three pipeline stages functional

## Advanced: Adding New Runs to CSV

When you have a new run to process:

1. Open your CSV file (e.g., `fUSI_data_location_LOCAL.csv`)
2. Add a new row with:
   - `experiment`: Experiment name (e.g., 'MethodsPaper')
   - `session_id`: Session ID (e.g., 'ses-231215')
   - `func_run`: Functional run ID (e.g., 'run-115047')
   - `anatomic_run`: Anatomical run ID (e.g., 'run-113409')
   - `data_root`: Root data directory path

3. Save the CSV
4. Run the launcher with your new run ID

Example CSV entry:
```csv
MethodsPaper,ses-231215,run-115047,run-113409,/Users/username/data
```

## Tips for Best Results

1. **Always use the launcher** instead of running stages manually
2. **Check the status** before running each stage
3. **Read warning messages** carefully before overwriting
4. **Keep your CSV file updated** with all your runs
5. **Use absolute paths** in your CSV file
6. **Process stages in order**: Reconstruction → Preprocessing → Analysis

## Support

For issues or questions:
- Check the memory-bank/ directory for detailed documentation
- Review individual stage README files (in 02_Func_Reconstruction/, etc.)
- Check MATLAB console output for error messages

## File Structure

```
000_LAUNCHER/
├── fusi_pipeline_launcher.m          # Main entry point
├── fUSI_data_location.csv            # Run database (example data)
├── README.md                          # This file
├── lib/                               # Helper functions
│   ├── load_run_info.m               # CSV reading (placeholder)
│   ├── check_reconstruction_ready.m   # File checking (placeholder)
│   ├── check_preprocessing_ready.m    # File checking (placeholder)
│   ├── check_analysis_ready.m         # File checking (placeholder)
│   └── display_status_menu.m          # Menu display (working)
└── memory-bank/                       # Project documentation
    ├── projectbrief.md
    ├── productContext.md
    ├── activeContext.md
    ├── systemPatterns.md
    ├── techContext.md
    └── progress.md
```

## CSV Database Format

The launcher uses a CSV file to look up run information. You can have multiple CSV files for different environments.

**CSV File Names**:
- `fUSI_data_location_STORM.csv` - For remote server with paths like `/data03/...`
- `fUSI_data_location_local.csv` - For local machine with paths like `/Users/...`
- `fUSI_data_location.csv` - Default/generic file

**CSV Structure**:
```csv
experiment,session_id,func_run,anatomic_run,data_root
MethodsPaper,ses-231215,run-115047,run-113409,/data03/fUSIMethodsPaper
```

**Columns** (in hierarchical order):
- `experiment`: Experiment name
- `session_id`: Session ID (e.g., ses-231215)
- `func_run`: Functional run ID (e.g., run-115047)
- `anatomic_run`: Anatomical run ID (e.g., run-113409)
- `data_root`: Root directory for all data (different per environment)

**Note**: Configure which CSV file to use by editing `CSV_FILENAME` at the top of `fusi_pipeline_launcher.m`.


