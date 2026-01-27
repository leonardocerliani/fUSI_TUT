# Technical Context: fUSI Reconstruction Pipeline

> **Note**: This documentation reflects the refactoring work completed in `02_Functional_Reconstruction/` with sample data located in `sample_data/`. Paths and examples have been updated to match the current organization.

## Technology Stack

### Primary Language & Environment
- **MATLAB**: Core processing environment for fUSI data
  - Used for numerical array operations
  - Native support for binary file I/O
  - MAT file format for structured data storage
  - Built-in table data structures

### Data Formats

#### Input Formats
1. **Binary Files**:
   - `fUS_block_PDI_float.bin`: Raw PDI data (single precision floats)
   - Format: Sequential 32-bit float values
   - Dimensions implicit, must be reshaped using BFConfig parameters

2. **MAT Files** (MATLAB proprietary):
   - `L22-14_PlaneWave_FUSI_data.mat`: Scan parameters
   - `post_L22-14_PlaneWave_FUSI_data.mat`: Post-processing parameters
   - Contains `BFConfig` structure with:
     - `Nx`, `Nz`: Spatial dimensions (x, z axes)
     - `ScaleX`, `ScaleZ`: Pixel spacing in mm
     - Other beamforming/acquisition parameters

3. **CSV Files** (comma-separated):
   - `TTL*.csv`: Hardware timing signals (13 channels)
     - Column 1: Timestamp (seconds)
     - Columns 2-13: Digital TTL channel states (0/1)
     - Sample rate: ~5000 Hz (0.0002s intervals)
   
   - `DAQ.csv` or `NIDAQ.csv`: Data acquisition log
     - Headers: time, visual, audio, shock signals, etc.
     - Unix timestamps (epoch time)
   
   - `VisualStimulation.csv`: Visual stimulus timing
     - Columns: time, stim, event, duration
   
   - `auditoryStimulation.csv`: Audio stimulus timing (if present)
   
   - `ShockStimulation.csv`: Shock stimulus metadata (if present)
   
   - `GSensor.csv`: Accelerometer data
     - Columns: time, samplenum, x, y, z
     - ~60 Hz sampling rate
   
   - `RunningWheel.csv` or `WheelEncoder.csv`: Locomotion data
     - Columns: time, wheelspeed
     - ~60 Hz sampling rate
   
   - `flir_camera_time.csv`: Pupil camera timestamps (if present)

4. **JSON Files**:
   - `experiment_config.json`: Per-run TTL channel configuration
     - TTL channel assignments (the main variable between experiments)
     - Experiment metadata
   - `settings.json`: Experiment settings
     - Sensor configurations
     - Stimulation parameters
     - Experimental metadata

#### Output Format
- **PDI.mat**: Structured MATLAB file containing:
  ```matlab
  PDI struct with fields:
    .PDI           % 3D array [nz × nx × nt]
    .Dim           % Dimension metadata
    .time          % Frame timestamps (aligned)
    .stimInfo      % Stimulation events table
    .pupil         % Pupil camera info
    .wheelInfo     % Running wheel data
    .gsensorInfo   % Accelerometer data
    .savepath      % Output directory path
  ```

## Key Technical Concepts

### 1. TTL Synchronization
**Purpose**: Hardware timing signals synchronize multiple acquisition systems

**Channel Mapping** (from sample data):
- Channel 1: Time (timestamp column)
- Channel 3: Events (PDI frame markers)
- Channel 4: ShockOBSCTL stimulation
- Channel 5: ShockTail stimulation
- Channel 6: AdjustPDItime marker
- Channel 10: Visual stimulation
- Channel 11: Auditory stimulation
- Channel 12: Shock (general)

**Critical Operations**:
- Detect edges: `diff(TTLinfo(:,channel)) < 0` (falling) or `> 0` (rising)
- Extract events: Find indices where edges occur
- Align timestamps: Use first event as t=0 reference

### 2. Lag Correction
**Problem**: PDI frames may be acquired with timing irregularities

**Solution**: `LagAnalysisFusi` function analyzes IQ data to determine:
- `T_pdi_intended`: Expected frame times
- `timeTagsSec`: Actual frame times
- Frame intervals and block consistency

**Process**:
1. Calculate frame interval mode: `mode(diff(timeTagsSec))`
2. Validate block intervals (tolerance: 0.01s range)
3. Filter frames with irregular timing: `acceptIndex`
4. Align corrected times with TTL: `TTLinfo(PDITTL(1), 1) + timeTagsSec`

### 3. Timeline Alignment and Synchronization
All data streams must share a common time reference:

**Steps**:
1. Find first acquisition event (channel 6 or 5 rising edge)
2. Remove pre-acquisition TTL entries
3. Shift all timestamps so first acquisition = t=0
4. Shift PDI times forward by mean frame interval (accounts for acquisition duration)
5. Remove negative-time frames from PDI data

**Critical Synchronization Note**:
- The DAQ recording (DAQ.csv) is started at the experiment start marker
- `NIDAQInfo.time(1)` is synchronized to the TTL experiment start marker
- This makes `NIDAQInfo.time(1)` a valid proxy for experiment start when:
  - TTL stimulus channel information is missing
  - CSV fallback is needed for event timing
- Both TTL-based and CSV-based event extraction produce times relative to the same reference point
- No additional alignment correction is needed between TTL and CSV paths

### 4. Data Reshaping
Binary PDI data is 1D but represents 3D spatiotemporal data:

```matlab
% Calculate number of time points
nt = numel(rawPDI) / (BFConfig.Nx * BFConfig.Nz)

% Reshape to 3D: depth × width × time
pdi = reshape(rawPDI, [nz, nx, nt])
```

## Dependencies

### Required External Functions
- **LagAnalysisFusi**: Analyzes IQ data for frame timing correction
  - Input: Path to FUSI_data directory
  - Output: Intended times, actual time tags
  - Handles: Frame lag detection and correction

### MATLAB Toolboxes Required
- Core MATLAB (for basic operations)
- No special toolboxes explicitly required
- Standard functions: `readmatrix`, `readtable`, `fread`, `reshape`, `diff`, `find`, `mode`

## Development Setup

### Directory Structure

**Sample data location:**
```
02_Functional_Reconstruction/
├── do_reconstruct_functional.m
├── experiment_config_template.json
├── README.md
├── src/
│   ├── assembly/ (2 functions)
│   ├── events/ (4 functions)
│   ├── io/ (2 functions)
│   ├── processing/ (1 function)
│   ├── sync/ (1 function)
│   └── utils/ (5 functions)
└── sample_data/
    ├── Data_collection/
    │   └── run-115047-func/
    │       ├── experiment_config.json  ← Required config
    │       ├── TTL20231215T115044.csv
    │       ├── DAQ.csv
    │       ├── VisualStimulation.csv
    │       ├── RunningWheel.csv
    │       ├── GSensor.csv
    │       ├── settings.json
    │       └── FUSI_data/
    │           ├── fUS_block_PDI_float.bin
    │           ├── L22-14_PlaneWave_FUSI_data.mat
    │           └── post_L22-14_PlaneWave_FUSI_data.mat
    └── Data_analysis/
        └── run-115047-func/
            └── PDI.mat  (created after processing)
```

**Generic data structure (for any experiment):**
```
Data_collection/
└── run-[number]-func/
    ├── experiment_config.json ← Required
    ├── TTL*.csv
    ├── DAQ.csv or NIDAQ.csv
    ├── VisualStimulation.csv (optional)
    ├── auditoryStimulation.csv (optional)
    ├── ShockStimulation.csv (optional)
    ├── GSensor.csv (optional)
    ├── RunningWheel.csv (optional)
    ├── flir_camera_time.csv (optional)
    └── FUSI_data/
        ├── fUS_block_PDI_float.bin
        ├── L22-14_PlaneWave_FUSI_data.mat
        └── post_L22-14_PlaneWave_FUSI_data.mat

Data_analysis/
└── run-[number]-func/
    └── PDI.mat  (output)
```

### Path Generation Logic
The script automatically creates analysis path from collection path:
```matlab
% Find 'Data_collection' in path
tmpInd1 = strfind(datapath, 'Data_collection');
tmpInd2 = tmpInd1 + length('Data_collection');

% Replace with 'Data_analysis'
savepath = fullfile(datapath(1:tmpInd1-1), 'Data_analysis', ...
                    datapath(tmpInd2:end));
```

## Technical Constraints

1. **Binary file size**: PDI files can be several GB, too large for text display
2. **Memory requirements**: Must load entire PDI array into memory for reshaping
3. **Timestamp precision**: Unix epoch timestamps vs relative timing alignment
4. **Hardware sampling rates vary**: TTL (~5kHz), sensors (~60Hz), PDI (~5Hz)
5. **Channel mapping variability**: TTL channel assignments may change between experiments

## Best Practices

1. **Always validate file existence** before reading
2. **Handle missing optional files** gracefully (e.g., pupil camera, wheel)
3. **Verify TTL synchronization** by checking expected vs actual frame counts
4. **Document channel mapping** per experiment (future improvement needed)
5. **Preserve original timestamps** alongside aligned timestamps for debugging
