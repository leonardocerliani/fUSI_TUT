# fUSI Functional Data Reconstruction Pipeline

## Overview
Modular, configurable pipeline for converting raw fUSI data to structured MAT format with per-experiment JSON configuration.

**Main Script**: `do_reconstruct_functional.m`

📖 **For a detailed step-by-step walkthrough of what the code does, see:**  
[Code Walkthrough](docs/README_reconstruction_walkthrough.md)

## Three main procedures:

## 0. Provide a json file with the experiment configuration 

A file named `experiment_config.json` must be available in the Data_collection folder.

The crucial information in this file is the channel number for different source of data. For instance:

**→ [See detailed walkthrough: Load Configuration](docs/README_reconstruction_walkthrough.md#2-load-configuration)**

```json
{
  "experiment_id": "run-115047-func",
  "date": "2023-12-15",
  "description": "Visual stimulation with running wheel and gsensor",
  
  "ttl_channels": {
    "pdi_frame": 3,
    "experiment_start": 6,
    "experiment_start_fallback": 5,
    "visual": 10
  }
}
```



### 1. Reconstructing a 3D pdi

Starting from the binary file `fUS_block_PDI_float.bin`, we use the `L22-14_PlaneWave_FUSI_data.mat` (in the script is `BFconfig`) to detect the shape of the 3D data, reshape the binary and store it in a struct.

**→ [See detailed walkthrough: Load Core Data](docs/README_reconstruction_walkthrough.md#3-load-core-data)**



### 2. Assigning time stamps

The `TTL*.csv` file contains the time stamp of many events in the experiment, including the pdi acquisition as well as other events such as stimuli. This allows to establish a common temporal reference.

**→ [See detailed walkthrough: Timeline Synchronization](docs/README_reconstruction_walkthrough.md#4-timeline-synchronization)**

We use a specific channel (usually ch3) in the TTL data to get the timing of the pdi frame acquisition.

```
TTL ch3 --> detect falling edges --> record the row of TTL --> PDITTL --> should correspond to size(pdiData,3)

reconcile number of PDITTL with number of pdfFRAMES

Extract time stamp of each frame with PDItime = ttlData(PDITTL, 1)

Remove all the frames before the first presentation, so that this occurs at time = 0. This involves:
- removing pre-experiment data from ttlData
- shift time stamps in ttlData to t=0
- remove frames with negative time stamps in pdiData
```



### 3. Assign time stamps to other events

This is to detect which stimuli were presented in the current session, and to add them as well other measurements - e.g. wheel - to the final `PDI.mat`.

**→ [See detailed walkthrough: Detect Stimulation and Behavioral Data](docs/README_reconstruction_walkthrough.md#5-detect-stimulation-and-behavioral-data)**



## Dependencies

**For detailed explanation of each step, see:** [Code Walkthrough](docs/README_reconstruction_walkthrough.md)

```
 do_reconstruct_functional.m
├─ STEP 1: Get the data path from datapath (arg to the fn or uigetdir)
├─ STEP 2: Load the experiment_config.json
│
├─ STEP 3: Load core data
│  │
│  └─ load_core_data()                    [src/io/]
│      └─ Reads: BFConfig MAT files
│                fUS_block_PDI_float.bin
│                TTL*.csv
│                DAQ.csv (or NIDAQ.csv)
│
├─ STEP 4: Timeline synchronization
│  │
│  └─ synchronize_timeline()               [src/sync/]
│      ├─ detect_ttl_edges()               [src/io/]
│      │
│      └─ LagAnalysisFusi() (optional)     [external function]
│          └─ Analyzes IQ/RF files if available
│
├─ STEP 5a: Detect and load stimulation
│  │
│  └─ detect_and_load_stimulation()        [src/events/]
│      ├─ extract_visual_events()          [src/events/]
│      │   └─ detect_ttl_edges()           [src/io/]
│      │
│      ├─ extract_shock_events()           [src/events/]
│      │   └─ detect_ttl_edges()           [src/io/]
│      │
│      └─ extract_auditory_events()        [src/events/]
│          └─ detect_ttl_edges()           [src/io/]
│
├─ STEP 5b: Detect and load behavioral
│  │
│  └─ detect_and_load_behavioral()         [src/events/]
│      └─ Reads: RunningWheel.csv
│                GSensor.csv
│                pupil_camera.csv
│
├─ STEP 6: Assemble and save
│  │
│  ├─ build_pdi_structure()                [src/io/]
│  │   └─ Assembles all data into PDI struct
│  │
│  └─ save_pdi_data()                      [src/io/]
│      └─ Saves PDI.mat file
│
└─ STEP 7: Final summary
   │
   └─ print_final_summary()                [src/utils/]
       └─ Displays processing results
```








## Key Features
- **Minimal configuration**: Only TTL channels need to be specified
- **Auto-detection**: Automatically finds available stimulation and behavioral data
- **Clear feedback**: Terminal output shows what's configured, found, or missing
- **Modular design**: Easy to modify, test, and extend individual components
- **Config travels with data**: Each experiment has its own config file



## Quick Start

### 1. Create Config File
For each experimental run, create `experiment_config.json` in the data folder:

```bash
Data_collection/run-XXXXX-func/experiment_config.json
```

**Minimal config** (visual stimulation only):
```json
{
  "experiment_id": "run-115047-func",
  "date": "2023-12-15",
  "description": "Visual stimulation experiment",
  
  "ttl_channels": {
    "pdi_frame": 3,
    "experiment_start": 6,
    "experiment_start_fallback": 5,
    "visual": 10
  }
}
```

**Standard config** (recommended for all experiments):
```json
{
  "experiment_id": "run-XXXXX-func",
  "date": "YYYY-MM-DD",
  "description": "Description of experiment",
  
  "ttl_channels": {
    "pdi_frame": 3,
    "experiment_start": 6,
    "experiment_start_fallback": 5,
    "visual": 10,
    "auditory": 11,
    "shock": [4, 5, 12]
  }
}
```

**Note:** Keep all channel fields present for consistency. Unused stimulation types are automatically ignored if their CSV files are not present. This standardized approach simplifies configuration management across different experiment types.



### 2. Run Processing

```matlab
% Navigate to 02_Functional_Reconstruction folder
cd('/path/to/02_Functional_Reconstruction')

% Run with dialog to select data folder
PDI = do_reconstruct_functional();

% Or provide path directly
func_collection_path = '/path/to/Data_collection/ses-231215/run-115047-func';
PDI = do_reconstruct_functional(func_collection_path);

% Or specify both data collection and analysis paths
func_collection_path = '/path/to/Data_collection/ses-231215/run-115047-func';
func_analysis_path = '/path/to/Data_analysis/ses-231215/run-115047-func';
PDI = do_reconstruct_functional(func_collection_path, func_analysis_path);
```

**Try with sample data:**
```matlab
cd 02_Functional_Reconstruction
PDI = do_reconstruct_functional('sample_data/Data_collection/run-115047-func');
```



## Directory Structure

```
02_Functional_Reconstruction/
├── do_reconstruct_functional.m        # Main script
├── experiment_config_template.json    # Configuration template
├── README.md                          # This file
├── memory-bank/                       # Documentation (6 markdown files)
├── legacy_code/                       # Original Rawdata2MATnew.m for reference
└── src/                              # Modular functions (15 total)
    ├── events/                       # Event extraction (5 functions)
    │   ├── detect_and_load_behavioral.m
    │   ├── detect_and_load_stimulation.m
    │   ├── extract_auditory_events.m
    │   ├── extract_shock_events.m
    │   └── extract_visual_events.m
    ├── io/                           # I/O operations (4 functions)
    │   ├── build_pdi_structure.m
    │   ├── detect_ttl_edges.m
    │   ├── load_core_data.m
    │   └── save_pdi_data.m
    ├── sync/                         # Timeline synchronization (1 function)
    │   └── synchronize_timeline.m
    └── utils/                        # Utilities (5 functions)
        ├── generate_save_path.m
        ├── load_experiment_config.m
        ├── parse_config.m
        ├── print_final_summary.m
        └── print_ttl_config.m
```

**Sample data for testing:**
```
sample_data/
├── Data_collection/
│   └── run-115047-func/
│       ├── experiment_config.json
│       ├── DAQ.csv, TTL*.csv
│       ├── VisualStimulation.csv
│       ├── RunningWheel.csv, GSensor.csv
│       └── FUSI_data/
└── Data_analysis/                    # Created during processing
    └── run-115047-func/
        └── PDI.mat
```



## Terminal Output Example

```
========================================
fUSI Data Processing Pipeline
========================================

→ Loading configuration: experiment_config.json
  Experiment: run-115047-func (2023-12-15)
  Visual stimulation with running wheel and gsensor

→ TTL Channel Configuration:
  ✓ PDI frames:        Channel 3
  ✓ Experiment start:  Channel 6 (fallback: 5)
  ✓ Visual stim:       Channel 10

→ Loading core data files:
  ✓ Scan parameters loaded: L22-14_PlaneWave_FUSI_data.mat
  ✓ PDI binary loaded: fUS_block_PDI_float.bin (128 × 256 × 1842 frames)
  ✓ TTL data loaded: TTL20231215T115044.csv (13 channels, 89420 samples)
  ✓ DAQ log loaded: DAQ.csv

→ Timeline synchronization:
  ✓ Experiment start detected at t = 0.000 s
  ✓ PDI frames aligned: 1842 frames spanning 368.4 s
  ✓ Frame rate: 5.00 Hz (200 ms intervals)

→ Detected stimulation files:
  ✓ Visual stimulation: VisualStimulation.csv
    → Found 20 visual events (channel 10)
  ✗ Shock stimulation: Not found
  ✗ Auditory stimulation: Not found

→ Detected behavioral data:
  ✓ Running wheel: RunningWheel.csv
    → 45238 time points, speed range: 0.0-12.4 cm/s
  ✓ G-sensor: GSensor.csv
    → 45238 time points, 3-axis acceleration
  ✗ Pupil camera: Not found

→ Assembling PDI structure...

→ Processing complete!
  Output saved: /path/to/Data_analysis/run-115047-func/PDI.mat

========================================
Summary:
  • PDI data: 128 × 256 pixels, 1842 frames
  • visual: 20 events
  • Behavioral: wheel + gsensor
  • Duration: 368.4 seconds
========================================
```



## Configuration Options

### Required Fields
- `experiment_id`: Unique identifier for this run
- `date`: Date of experiment (YYYY-MM-DD)
- `ttl_channels.pdi_frame`: Channel for PDI frame markers
- `ttl_channels.experiment_start`: Channel for experiment start marker



### Optional Fields

- `description`: Brief description of experiment
- `ttl_channels.experiment_start_fallback`: Fallback channel if primary fails
- `ttl_channels.shock`: Channel(s) for shock stimulation (can be array)
- `ttl_channels.visual`: Channel for visual stimulation
- `ttl_channels.auditory`: Channel for auditory stimulation



### Notes on TTL Channels

- **Keep all fields present**: Use the same config structure for all experiments (visual, auditory, shock)
- **Unused types auto-ignored**: If a stimulation CSV file is not present, that type is automatically skipped
- **Shock channels**: Specify as array `[4, 5, 12]` - code intelligently selects appropriate channels based on shock type detected in CSV:
  - Tail shock: uses channels 5 and/or 12
  - Left/Right shock: uses channels 4 and/or 12
- **Channel numbers**: Standard assignments are 10 (visual), 11 (auditory), [4,5,12] (shock) - update if your setup differs



## Auto-Detection

The pipeline automatically detects and processes:

### Stimulation Files (if config has corresponding TTL channel)
- `ShockStimulation.csv` + optional `shockIntensities_and_perceivedSqueaks.xlsx`
- `VisualStimulation.csv`
- `auditoryStimulation.csv`

### Behavioral Data (always checked)
- `RunningWheel.csv` → `PDI.wheelInfo`
- `GSensor.csv` → `PDI.gsensorInfo`
- `pupil_camera.csv` → `PDI.pupil.pupilTime`

### Core Data (required)
- `FUSI_data/fUS_block_PDI_float.bin`
- `FUSI_data/*_PlaneWave_FUSI_data.mat`
- `TTL*.csv`
- `DAQ.csv` or `NIDAQ.csv`

## Output Structure

```matlab
PDI = 
  struct with fields:
    
    Dim: [1×1 struct]
      .nx, .nz          % Spatial dimensions
      .dx, .dz          % Pixel spacing (mm)
      .nt               % Number of time points
      .dt               % Frame interval (s)
    
    PDI: [nz × nx × nt double]  % Imaging data
    
    time: [nt × 1 double]       % Frame timestamps
    
    stimInfo: [table]           % Stimulation events
      .stimCond                 % Condition labels
      .startTime                % Event start times
      .endTime                  % Event end times
    
    pupil: [1×1 struct]
      .pupilTime                % Camera timestamps
    
    wheelInfo: [table]          % Running wheel data
    gsensorInfo: [table]        % Accelerometer data
    
    savepath: [char]            % Output directory
```



## Troubleshooting

### Missing Config File
**Error**: Configuration file not found!

**Solution**: Create `experiment_config.json` in your data folder. The error message will show the expected location and provide a template.

### Wrong TTL Channels
**Symptom**: No events detected or wrong number of events

**Solution**: Check your TTL channel assignments in the config file against your experimental setup.

### Missing Data Files
**Symptom**: Script errors saying files not found

**Solution**: Ensure all required files exist:
- FUSI_data directory with PDI binary and scan parameters
- TTL CSV file
- DAQ/NIDAQ CSV file



## Differences from Original

### What Changed
1. **Configuration**: TTL channels now in JSON file, not hardcoded
2. **Modularity**: 15 focused functions instead of one monolithic function
3. **Terminal output**: Clear status messages throughout processing
4. **Error handling**: Helpful messages when config missing



### What Stayed the Same

1. **Output format**: PDI structure identical to original
2. **Processing logic**: Same algorithms (edge detection, lag correction, etc.)
3. **File locations**: Data and output paths work the same way
4. **Dependencies**: Still uses LagAnalysisFusi for lag correction



## Advanced Usage

### Batch Processing
```matlab
runs = {
    '/path/to/Data_collection/run-115047-func'
    '/path/to/Data_collection/run-120530-func'
};

for i = 1:length(runs)
    fprintf('\nProcessing run %d/%d\n', i, length(runs));
    PDI = do_reconstruct_functional(runs{i});
end
```

### Custom Output Path
```matlab
datapath = '/path/to/Data_collection/run-115047-func';
savepath = '/custom/output/location';
PDI = do_reconstruct_functional(datapath, savepath);
```



## Support

For issues or questions:
1. Check that `experiment_config.json` exists and is valid JSON
2. Verify TTL channel numbers match your setup
3. Ensure all required data files are present
4. Check MATLAB path includes `02_Functional_Reconstruction/src/` directories (auto-added by script)



## About This Pipeline

This is a **refactored version** of the original `Rawdata2MATnew.m` script (preserved in `legacy_code/` for reference). The refactored version provides:
- Modular architecture (15 focused functions)
- Per-experiment JSON configuration
- Clear terminal feedback
- Auto-detection of available data
- Easy to maintain and extend
