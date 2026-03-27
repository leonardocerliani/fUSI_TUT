# do_reconstruct_functional.m - Technical Documentation

## Table of Contents

### Overview & Setup
- [Overview](#overview)
- [Dependencies](#dependencies)
- [Expected Input Structure](#expected-input-structure)
- [Output Structure](#output-structure)

### Processing Steps
- [1. Load Configuration](#1-load-configuration)
  - [Configuration Structure](#configuration-structure)
  - [Error Handling](#error-handling)
  - [Configuration Display](#configuration-display)
- [2. Load Core Data Files](#2-load-core-data-files)
  - [Locate FUSI Data Directory](#2a-locate-fusi-data-directory)
  - [Load Scan Parameters](#2b-load-scan-parameters)
  - [Read Raw PDI Data](#2c-read-raw-pdi-data)
  - [Load TTL Timing Data](#2d-load-ttl-timing-data)
  - [Load NIDAQ/DAQ Log](#2e-load-nidaqdaq-log)
- [3. Timeline Synchronization](#3-timeline-synchronization)
  - [Detect PDI Frame Markers](#3a-detect-pdi-frame-markers)
  - [Reconcile Frame Counts](#3b-reconcile-frame-counts)
  - [Lag Correction](#3c-lag-correction-optional-iqrf-data)
  - [Adjust PDI Timeline](#3d-adjust-pdi-timeline-establish-t0)
- [4. Extract Stimulation Events](#4-extract-stimulation-events)
  - [Visual Stimulation](#4a-visual-stimulation)
  - [Shock Stimulation](#4b-shock-stimulation)
  - [Auditory Stimulation](#4c-auditory-stimulation)
- [5. Load Behavioral Data](#5-load-behavioral-data)
  - [Running Wheel Data](#5a-running-wheel-data)
  - [G-Sensor](#5b-g-sensor-head-motion)
  - [Pupil Camera Timestamps](#5c-pupil-camera-timestamps)
- [6. Assemble and Save PDI Structure](#6-assemble-and-save-pdi-structure)
  - [Build PDI Structure](#6a-build-pdi-structure)
  - [Save PDI Data](#6b-save-pdi-data)
- [Summary](#summary)

---

# Overview

`do_reconstruct_functional.m` is the primary reconstruction script for functional ultrasound imaging (fUSI) data. It converts raw ultrasound data, hardware timing signals, and experimental event logs into a single, synchronized, analysis-ready MATLAB structure saved as `PDI.mat`.

**Purpose**: Synchronize and align multiple data streams from a functional ultrasound imaging experiment:
- Raw Power Doppler Imaging (PDI) binary data
- Hardware timing signals (TTL)
- Experimental stimulation events (shock, visual, auditory)
- Behavioral measurements (running wheel, head motion, pupil tracking)

**Key Functionality**:
1. Loads configuration from `experiment_config.json`
2. Loads and reshapes raw ultrasound data
3. Synchronizes imaging frames with hardware timing signals
4. Corrects for timing irregularities (lag correction)
5. Aligns all data streams to a common timeline (t=0)
6. Extracts and categorizes stimulation events
7. Integrates behavioral data
8. Produces structured output for downstream analysis

**Key Features**:
- **Configuration-based**: TTL channel mappings in JSON file (no code changes needed)
- **Modular architecture**: Organized into functional modules (io/, sync/, events/, assembly/)
- **Enhanced error handling**: Helpful diagnostics when configuration is incorrect
- **Clean code**: Single responsibility per function, easier to maintain
- **Flexible detection**: Auto-detects available data files

## Dependencies

### Required External Functions
- **LagAnalysisFusi**: Analyzes IQ data for precise frame timing correction (optional - graceful fallback if unavailable)

### Required Configuration Files
- **experiment_config.json**: Defines TTL channel mappings for each experiment

### MATLAB Requirements
- Core MATLAB (no special toolboxes required)
- Standard functions: `readmatrix`, `readtable`, `fread`, `fopen`, `reshape`, `diff`, `find`

### Source Code Organization
```
src/
├── events/                  % Event extraction & behavioral data (5 functions)
│   ├── detect_and_load_behavioral.m
│   ├── detect_and_load_stimulation.m
│   ├── extract_auditory_events.m
│   ├── extract_shock_events.m
│   └── extract_visual_events.m
├── io/                      % I/O operations (4 functions)
│   ├── build_pdi_structure.m
│   ├── detect_ttl_edges.m
│   ├── load_core_data.m
│   └── save_pdi_data.m
├── sync/                    % Timeline synchronization (1 function)
│   └── synchronize_timeline.m
└── utils/                   % Utility functions (5 functions)
    ├── generate_save_path.m
    ├── load_experiment_config.m
    ├── parse_config.m
    ├── print_final_summary.m
    └── print_ttl_config.m
```

**Total: 15 modular functions organized by functionality**

## Expected Input Structure

### Directory Organization
```
Data_collection/
└── [subject]/
    └── [session]/
        └── run-[number]-func/
            ├── experiment_config.json      [REQUIRED]
            ├── TTL*.csv                    [REQUIRED]
            ├── NIDAQ.csv or DAQ.csv        [REQUIRED]
            ├── VisualStimulation.csv       [optional]
            ├── auditoryStimulation.csv     [optional]
            ├── ShockStimulation.csv        [optional]
            ├── GSensor.csv                 [optional]
            ├── RunningWheel.csv            [optional]
            ├── pupil_camera.csv            [optional]
            └── FUSI_data/                  [REQUIRED]
                ├── fUS_block_PDI_float.bin [REQUIRED]
                ├── L22-14_PlaneWave_FUSI_data.mat [REQUIRED]
                └── post_L22-14_PlaneWave_FUSI_data.mat [optional, preferred]
```

### Required Files
1. **experiment_config.json**: TTL channel configuration
2. **fUS_block_PDI_float.bin**: Raw PDI data (32-bit floats, single precision)
3. **L22-14_PlaneWave_FUSI_data.mat**: Scan parameters (BFConfig structure)
4. **TTL*.csv**: Hardware timing signals (13 channels)
5. **NIDAQ.csv or DAQ.csv**: Data acquisition log with event markers

### Optional Files
- **Stimulation CSVs**: Metadata for experimental events
- **Behavioral CSVs**: Running wheel, accelerometer, pupil tracking data
- **post_***.mat**: Post-processed scan parameters (preferred over regular version)

### Configuration File Format

**experiment_config.json** - NEW in refactored version:
```json
{
  "experiment_id": "run-115047-func",
  "date": "2023-12-15",
  "description": "Visual stimulation experiment",
  
  "ttl_channels": {
    "pdi_frame": 3,
    "experiment_start": 6,
    "experiment_start_fallback": 5,
    "shock": [4, 5, 12],
    "visual": 10,
    "auditory": 11
  }
}
```

**Why this approach?**
- Different experiments may use different TTL channel assignments
- Hardware variations across setups
- No code modification needed for different configurations
- Self-documenting: each experiment folder contains its own channel map
- Easy to review and validate channel assignments

## Output Structure

### PDI.mat File Contents
```matlab
PDI (struct)
├── PDI [nz × nx × nt double]       % Power Doppler Imaging data
├── Dim (struct)
│   ├── nx, nz                      % Spatial dimensions (pixels)
│   ├── dx, dz                      % Pixel spacing (mm)
│   ├── nt                          % Number of time points
│   └── dt                          % Frame interval (seconds)
├── time [nt × 1 double]            % Aligned frame timestamps
├── stimInfo (table)                % Stimulation events
│   ├── stimCond                    % Event type (visual, shock, etc.)
│   ├── startTime                   % Event start (seconds)
│   └── endTime                     % Event end (seconds)
├── pupil (struct)
│   └── pupilTime                   % Camera timestamps
├── wheelInfo (table)               % Running wheel data
│   ├── time                        % Timestamps
│   └── wheelspeed                  % Speed values
├── gsensorInfo (table)             % Head motion (accelerometer)
│   ├── time                        % Timestamps
│   └── x, y, z                     % Acceleration axes
└── savepath [char]                 % Output directory path
```

### Output Location
Automatically generated in `Data_analysis/` directory mirroring the input path structure:
```
Data_analysis/
└── [subject]/
    └── [session]/
        └── run-[number]-func/
            └── PDI.mat
```

---

# Processing Steps

## 1. Load Configuration

### What Happens
This section loads the experiment configuration file that defines TTL channel mappings and other experimental metadata. This enables flexible configuration without code changes.

### Scripts Used
- **load_experiment_config.m**: Checks for config file and provides helpful error if missing
- **parse_config.m**: Parses JSON and validates structure
- **print_ttl_config.m**: Displays loaded configuration for verification

### Configuration Structure

**Required fields in experiment_config.json**:
```json
{
  "experiment_id": "run-115047-func",
  "date": "2023-12-15",
  "description": "Visual stimulation experiment",
  
  "ttl_channels": {
    "pdi_frame": 3,
    "experiment_start": 6,
    "experiment_start_fallback": 5,
    "shock": [4, 5, 12],
    "visual": 10,
    "auditory": 11
  }
}
```

**TTL Channel Definitions**:

| Config Field | Type | Purpose |
|--------------|------|---------|
| `pdi_frame` | integer | Channel containing PDI frame completion markers (falling edges) |
| `experiment_start` | integer | Channel marking experiment start (rising edge = t=0) |
| `experiment_start_fallback` | integer | Alternative start marker if primary channel inactive |
| `shock` | array | Channel(s) for shock stimulation (can be single value or array) |
| `visual` | integer | Channel for visual stimulation events |
| `auditory` | integer | Channel for auditory stimulation events |

### Why Configuration-Based Approach?

**Benefits:**
- Each experiment folder contains its configuration
- Self-documenting: years later you can see which channels were used
- Easy to adapt to hardware changes
- No code modifications needed
- Different setups can coexist without conflicts

**Example use case:**
```
Setup A (Mouse #1):  PDI frame on channel 3
Setup B (Mouse #2):  PDI frame on channel 4 (different hardware)

→ Solution: Different config files per experiment, same code
→ No need to edit scripts between different hardware setups
```

### Error Handling

**Enhanced diagnostics when config missing:**

If `experiment_config.json` not found, the script:
1. Shows expected file location
2. Prints example configuration template
3. Explains what each field means
4. Provides clear instructions to create the file

**Sample error output:**
```
========================================
ERROR: Configuration file not found!
========================================

Expected location:
  /path/to/data/experiment_config.json

Please create experiment_config.json with the following format:

{
  "experiment_id": "run-115047-func",
  "date": "2023-12-15",
  ...
}

Notes:
  • Update channel numbers to match your setup
  • Remove lines for unused stimulation types
  • Save as experiment_config.json in the data folder
========================================
```

### Configuration Display

After successful loading, the script displays the configuration for verification:

```
→ Loading configuration: experiment_config.json

TTL Channel Configuration:
  PDI Frame Marker:        Channel 3
  Experiment Start:        Channel 6 (fallback: 5)
  Shock Stimulation:       Channels 4, 5, 12
  Visual Stimulation:      Channel 10
  Auditory Stimulation:    Channel 11
```

This allows quick visual verification that channels are correct before processing.

### Success Criteria

Configuration successfully loaded when:
- `experiment_config.json` exists in data directory
- JSON is valid and parseable
- Required `ttl_channels` field present
- At minimum `pdi_frame` and `experiment_start` defined
- Config structure returned for use in subsequent steps

---

## 2. Load Core Data Files

### What Happens
This section loads all required data files: scan parameters, raw PDI binary, TTL timing signals, and NIDAQ log. This combines what were previously separate loading steps into a single, coordinated function.

### Scripts Used
**Primary script**: `load_core_data.m`

This function performs:
1. Locate FUSI_data directory
2. Load scan parameters (BFConfig)
3. Read and reshape PDI binary
4. Load TTL timing data
5. Load NIDAQ/DAQ log

### 2a. Locate FUSI Data Directory

**Pattern matching**: Searches for directories matching `FUSI_data*` in the data path.

**Why flexible pattern?**
- Different acquisition systems may append timestamps or identifiers
- Example: `FUSI_data`, `FUSI_data_20231215`, `FUSI_data_backup`
- Uses first match found

**Error handling**: Fatal error if no matching directory found - cannot proceed without raw data.

### 2b. Load Scan Parameters

**Purpose**: Load critical ultrasound imaging configuration parameters from MAT files. These parameters define the spatial dimensions and physical scaling of the imaging data.

**Priority list of parameter files**:
1. `post_L22-14_PlaneWave_FUSI_data.mat` (preferred - post-processed)
2. `L22-14_PlaneWave_FUSI_data.mat` (fallback - original acquisition)

**Search logic**:
- Iterates through file list in priority order
- Checks if each file exists
- Loads **only** the `BFConfig` variable (efficient partial loading)
- Stops immediately after first successful load

**Validation**: Fatal error if no parameter file found - cannot proceed without imaging geometry.

### What is BFConfig?

`BFConfig` is a structure containing **beamforming configuration parameters** - the settings that define how ultrasound signals were converted into images.

#### Critical Fields Used in Reconstruction

**Spatial Dimensions**:
```matlab
BFConfig.Nx          % Width in pixels (e.g., 128)
BFConfig.Nz          % Depth in pixels (e.g., 256)
BFConfig.ScaleX      % Pixel width in mm (e.g., 0.1 mm)
BFConfig.ScaleZ      % Pixel height in mm (e.g., 0.05 mm)
```

**Imaging Geometry**:
```matlab
BFConfig.Xmin, Xmax  % Field of view boundaries in x (mm)
BFConfig.Zmin, Zmax  % Field of view boundaries in z (mm)
BFConfig.probe       % Probe specifications
BFConfig.angles      % Plane wave steering angles
```

**Signal Processing**:
```matlab
BFConfig.fc          % Center frequency (MHz)
BFConfig.fs          % Sampling frequency (MHz)
BFConfig.c           % Speed of sound (m/s, typically 1540)
BFConfig.PRF         % Pulse repetition frequency (Hz)
```

### Origin of Parameter Files

#### Filename Anatomy: `L22-14_PlaneWave_FUSI_data.mat`

**L22-14**: Linear array probe model
- High-frequency ultrasound transducer (15-22 MHz range)
- Designed for small animal imaging (mice, rats)
- 128 individual transducer elements

**PlaneWave**: Acquisition technique
- Transmits unfocused ultrasound waves across entire field
- Enables very high frame rates (1-10 Hz for functional imaging)
- Faster than traditional focused scanning

**FUSI_data**: Functional ultrasound imaging dataset identifier

#### Two File Versions

**1. Regular Version: `L22-14_PlaneWave_FUSI_data.mat`**
- Created **during acquisition** by ultrasound scanner
- Contains intended beamforming parameters
- Automatically saved when starting functional scan

**2. Post-processed Version: `post_L22-14_PlaneWave_FUSI_data.mat`**
- Created **after acquisition** during offline processing
- May contain corrected or optimized parameters
- **Preferred** because it reflects actual processing used to generate PDI data
- Only present if IQ data was reprocessed offline

### Why These Parameters Matter

#### 1. Binary Data Reshaping
The PDI binary file contains a 1D stream of float values. Without `Nx` and `Nz`, we cannot reconstruct the 2D images.

**Example**:
- Binary file: `[val1, val2, val3, ..., val32768000]`
- With `Nx=128`, `Nz=256`, `nt=1000`:
- Reshape to: `[256 × 128 × 1000]` array
- Each time slice is a 256×128 ultrasound image

#### 2. Spatial Calibration
`ScaleX` and `ScaleZ` convert pixel coordinates to physical distances (millimeters).

**Example**:
- Pixel (50, 100) with `ScaleX=0.1`, `ScaleZ=0.05`
- Physical position: `(5.0 mm, 5.0 mm)` from probe surface
- Enables quantitative spatial analysis

#### 3. Metadata Preservation
Storing these parameters in output ensures processed data retains acquisition context.

### 2c. Read Raw PDI Data

**Purpose**: Read the binary PDI (Power Doppler Imaging) data file - the core imaging data containing blood flow information.

**File format**: `fUS_block_PDI_float.bin`
- Binary file containing single-precision (32-bit) floating point numbers
- No header, no structure - just raw sequential values
- Represents flattened 3D data: [depth × width × time]

**Reading process**:
1. Open file in binary read mode
2. Read entire file as 32-bit floats (`'single'` precision)
3. Close file handle
4. Result: 1D vector of all PDI values

**Automatic reshaping**:
- Calculate number of time points: `nt = total_values / (Nx × Nz)`
- Reshape 1D vector → 3D array: `[Nz × Nx × nt]`
- **Order matters**: `[nz, nx, nt]` matches how data was written to binary file
- Clear 1D vector to free memory

**From 1D to 3D**:
- **Before**: `rawPDI` = `[val1, val2, val3, ..., val32768000]` (flat array)
- **After**: `pdiData` = 3D array where `pdiData(:,:,t)` is a 2D ultrasound image at time t

**Example**:
- `Nx=128`, `Nz=256`, calculated `nt=1000`
- Input: 32,768,000 sequential float values
- Output: `pdiData(256, 128, 1000)` - 1000 frames of 256×128 images
- Each frame shows blood flow in a 2D brain slice

**Error handling**: Fatal error if file not found - indicates IQ-to-PDI conversion needed first.

### 2d. Load TTL Timing Data

**Purpose**: Load hardware timing signals (TTL - Transistor-Transistor Logic) that synchronize all data acquisition systems.

**File discovery**:
- Searches for files matching pattern `TTL*.csv`
- Uses first matching file if multiple exist
- Typical filename: `TTL20231215T115044.csv` (with timestamp)

**File loading**:
- `readmatrix()` reads entire CSV as numeric matrix
- No headers in file - pure numeric data
- Result: Matrix with dimensions [nSamples × 13]

### TTL Data Structure

**Matrix Dimensions**: [nSamples × 13 channels]

**Sampling Rate**: ~5000 Hz (0.0002 second intervals)
- High temporal resolution for precise event detection
- Typical recording duration: Several minutes
- Example: 10-minute recording = ~3,000,000 samples

**Data Format**: 
- Column 1: Time (seconds, starting from 0)
- Columns 2-13: Digital signal states (0 or 1)
- Each row represents one time sample

### TTL Channel Configuration

**Configuration-based approach** (NEW in refactored version):

Channel assignments are now defined in `experiment_config.json` rather than hard-coded:

```json
{
  "ttl_channels": {
    "pdi_frame": 3,
    "experiment_start": 6,
    "experiment_start_fallback": 5,
    "shock": [4, 5, 12],
    "visual": 10,
    "auditory": 11
  }
}
```

This flexible configuration enables:
- Different experimental setups without code changes
- Easy adaptation to hardware variations
- Self-documenting channel assignments per experiment

### Traditional Channel Assignments

While channels are now configurable, typical assignments are:

| Channel | Config Name | Purpose |
|---------|-------------|---------|
| 1 | (time) | Timestamp in seconds |
| 2 | (unused) | - |
| 3 | pdi_frame | **PDI frame markers** - falling edge indicates new frame acquired |
| 4 | shock[0] | Shock stimulation (observed/control paradigms) |
| 5 | shock[1] | Tail shock stimulation (or experiment_start_fallback) |
| 6 | experiment_start | **Experiment start marker** - first rising edge = t=0 reference |
| 7-9 | (unused) | - |
| 10 | visual | Visual stimulation events |
| 11 | auditory | Auditory stimulation events |
| 12 | shock[2] | General shock signal |
| 13 | (unused) | - |

### Why TTL Synchronization is Critical

**Problem**: Multiple data acquisition systems with independent clocks
- Ultrasound scanner records PDI frames
- Stimulation computer logs events
- Behavioral sensors sample continuously
- Each has its own timestamp system

**Solution**: TTL hardware signals
- Single timing source distributed to all systems
- Provides common reference for synchronization
- Allows precise alignment of all data streams in post-processing

**Without TTL**: Cannot reliably align imaging frames with stimulation events - temporal precision would be ~100-1000ms

**With TTL**: Temporal alignment precision ~0.2ms (limited by TTL sampling rate)

### 2e. Load NIDAQ/DAQ Log

**Purpose**: Load the NIDAQ (National Instruments Data Acquisition) log file, which records experimental events from the stimulation control computer.

**File discovery**:
- Tries two possible filenames: `NIDAQ.csv` or `DAQ.csv`
- Different naming conventions across acquisition systems
- Uses first file found

**File loading**:
- `readtable()` reads CSV with automatic header parsing
- Returns MATLAB table structure with named columns
- Preserves column names for easy access

### What is the NIDAQ/DAQ File?

The NIDAQ file is a **high-level event log** created by the experiment control software (typically running on a separate computer from the ultrasound scanner).

**Event Markers**: State changes for experimental events
- Visual stimulation on/off
- Auditory stimulation on/off
- Shock delivery events
- Recording session start/stop
- Camera triggers

**Timing Information**: Unix timestamps (seconds since epoch)
- Absolute time reference
- Independent from TTL timestamps
- Used for cross-validation and behavioral data alignment

### File Structure

**Example DAQ.csv structure**:

| time | visual | audio | shock_left | shock_right | shock_tail | recording_start | stim_start | camera_ttl_trigger |
|------|--------|-------|------------|-------------|------------|-----------------|------------|--------------------|
| 1702637451.576 | 0 | 0 | 1 | 1 | 1 | 0 | 0 | 0 |
| 1702637583.217 | 1 | 0 | 1 | 1 | 1 | 0 | 0 | 1 |
| 1702637598.200 | 0 | 0 | 1 | 1 | 1 | 0 | 0 | 1 |

**Column Descriptions**:

| Column | Type | Description |
|--------|------|-------------|
| `time` | float | Unix timestamp (seconds since Jan 1, 1970) |
| `visual` | binary | Visual stimulation state (1=on, 0=off) |
| `audio` | binary | Auditory stimulation state (1=on, 0=off) |
| `shock_left/right/tail` | binary | Shock channel states (inverted: 1=off, 0=on) |
| `recording_start` | binary | Recording session marker (1=start) |
| `stim_start` | binary | Stimulation protocol start marker (1=start) |
| `camera_ttl_trigger` | binary | Camera synchronization trigger (1=active) |

**Key Observations**:
- **Sparse sampling**: Events logged only when state changes occur (not continuous)
- **Unix timestamps**: Absolute time reference
- **State transitions**: Each row represents a change in system state

### Why This File is Necessary

#### 1. Behavioral Data Alignment
**Critical for synchronizing behavioral sensors** (wheel, accelerometer, pupil camera):

Behavioral data has its own timestamp system (Unix timestamps from the DAQ computer). NIDAQ provides common time reference by subtracting the first NIDAQ timestamp to convert to experiment-relative time.

**Why**: Behavioral sensors and DAQ share the same computer clock, enabling precise alignment.

#### 2. Fallback Event Timing
**When TTL signals are unavailable or incomplete**:

The script uses NIDAQ timestamps as fallback for stimulation events when TTL channels are not connected or faulty. This provides redundancy in the timing system.

#### 3. Cross-Validation
**Verifies TTL timing accuracy**:
- Compare NIDAQ event times with TTL-derived times
- Detect timing drift or synchronization issues
- Quality control for temporal alignment

#### 4. Absolute Time Reference
**Preserves real-world timing**:
- Links experiment to wall-clock time
- Enables correlation with external events
- Important for multi-session studies

### Relationship to TTL Signals

**NIDAQ vs TTL - Complementary Systems**:

| Aspect | TTL Signals | NIDAQ Log |
|--------|-------------|-----------|
| **Temporal Resolution** | ~0.2 ms (5 kHz sampling) | Variable (~1-100 ms) |
| **Coverage** | Hardware-level, all systems | Software-level, control computer only |
| **Primary Use** | Frame synchronization, precise timing | Event logging, behavioral alignment |
| **Timestamp Format** | Relative (seconds from 0) | Absolute (Unix epoch) |
| **Sampling** | Continuous | Event-triggered |

**Typical Workflow**:
1. **TTL**: Primary timing source for PDI frame synchronization
2. **NIDAQ**: 
   - Provides offset for behavioral data alignment
   - Fallback for stimulus timing if TTL unavailable
   - Cross-validation of timing accuracy

### Console Output Example

After successful loading, the script displays:

```
→ Loading core data files:
  ✓ Scan parameters loaded: post_L22-14_PlaneWave_FUSI_data.mat
  ✓ PDI binary loaded: fUS_block_PDI_float.bin (128 × 256 × 1200 frames)
  ✓ TTL data loaded: TTL20231215T115044.csv (13 channels, 2954789 samples)
  ✓ DAQ log loaded: DAQ.csv
```

### Success Criteria

All core data successfully loaded when:
- ✅ FUSI_data directory found
- ✅ Scan parameters (BFConfig) loaded
- ✅ PDI data read and reshaped to 3D
- ✅ TTL timing matrix loaded
- ✅ NIDAQ/DAQ log table loaded

These data structures are now ready for timeline synchronization.

---

## 3. Timeline Synchronization

### What Happens

This section performs the **critical temporal alignment** that synchronizes PDI frames with TTL timing signals and establishes a common timeline (t=0 = experiment start) for all data streams. This is the most complex processing step, combining frame-event reconciliation, optional lag correction, and timeline alignment.

### Scripts Used
**Primary script**: `synchronize_timeline.m`

This function orchestrates:
1. PDI frame marker detection
2. Frame count reconciliation
3. Lag correction (if IQ/RF data available)
4. Timestamp adjustment for frame duration
5. Experiment start detection
6. Timeline alignment to t=0
7. Pre-experiment frame removal

**Utility script**: `detect_ttl_edges.m` - Centralized edge detection

### 3a. Detect PDI Frame Markers

**Purpose**: Find all PDI frame completion events in TTL data.

**Edge detection**: 
```matlab
PDITTL = detect_ttl_edges(ttlData, config.ttl_channels.pdi_frame, 'falling');
```

**What it does:**
- Reads channel specified in config (typically channel 3)
- Detects **falling edges** (1→0 transitions)
- Each falling edge marks when ultrasound scanner completed a frame
- Returns row indices in TTL data where edges occur

**Why falling edges?**
The scanner sends a TTL pulse that:
- Goes HIGH (1) when starting frame acquisition
- Goes LOW (0) when frame is complete and saved
- The falling edge (1→0) is the reliable "frame done" marker

**Enhanced error handling** (NEW in refactored version):

If no frame markers found, the script:
1. Checks all TTL channels for falling edges
2. Reports which channels have activity
3. Suggests updating experiment_config.json
4. Provides clear error with actionable guidance

**Example error output**:
```
========================================
ERROR: No PDI frame markers found on channel 3!
========================================

This usually means the TTL channel assignment is incorrect.
Checking which channels have falling edges...

  Channel 2: 1198 falling edges
  Channel 3: 0 falling edges
  Channel 4: 45 falling edges

Please update experiment_config.json with the correct channel:
  "pdi_frame": <correct_channel_number>
========================================
```

This helps users quickly identify configuration issues.

### 3b. Reconcile Frame Counts

**Purpose**: Ensure one-to-one correspondence between TTL timing markers and actual PDI frames.

**Count comparison**:
```matlab
numPDITTL = numel(PDITTL);      % Number of TTL frame markers
numPDIframes = size(pdiData, 3); % Number of actual frames in data
```

**Why might these differ?**

Common causes of mismatch:
1. **Recording stopped slightly early/late**: Data acquisition and TTL recording might stop at slightly different times
2. **Race conditions**: Final frame might be incomplete when recording stopped
3. **System lag**: Brief delays between frame completion and TTL logging
4. **Buffer flushing**: Final frames in memory might not be written to disk
5. **Acquisition timing**: Scanner and TTL system have independent stop mechanisms

**Reconciliation logic**:

**Scenario A: More frames than TTL markers** (`numPDITTL < numPDIframes`)
- **Problem**: Extra frames at end without corresponding TTL timing
- **Solution**: Delete excess frames from PDI array
- **Example**: 1000 TTL markers but 1003 frames → delete frames 1001-1003
- **Why**: Cannot assign timestamps to frames without TTL markers

**Scenario B: More TTL markers than frames** (`numPDITTL > numPDIframes`)
- **Problem**: Extra TTL events recorded after data acquisition stopped
- **Solution**: Delete excess TTL markers
- **Example**: 1003 TTL markers but 1000 frames → delete markers 1001-1003
- **Why**: No corresponding imaging data for these timing events

**Result**: Guaranteed `length(PDITTL) == size(pdiData, 3)`
- Each frame has exactly one TTL timing marker
- Foundation established for subsequent timestamp assignment
- Data integrity maintained

### 3c. Lag Correction (Optional IQ/RF Data)

**Purpose**: Validate and correct frame timing irregularities using raw IQ/RF acquisition timestamps.

### Overview

Ultrasound acquisition systems can experience subtle timing irregularities (typically 5-20ms jitter) due to:
- Hard drive write delays
- Buffer management in acquisition
- Computer load variations
- USB bus contention

When raw IQ/RF data is available, the script can detect and filter frames with problematic timing. When unavailable (the standard case), TTL-based timing provides excellent precision without filtering.

### Two Processing Paths

#### Path 1: WITH IQ/RF Data (Try Block)

**Attempts to use LagAnalysisFusi function:**

The function reads timestamps directly from raw IQ/RF binary files and validates timing consistency.

**Processing steps:**
1. Calculate frame interval (typical: 0.5s for 2 Hz imaging)
2. Scan through data in ~1-second windows
3. Identify frames with timing variation >10ms
4. Mark irregular frames as invalid (~5-10% typically)
5. Filter PDI data to keep only validated frames
6. Align timeline using TTL start + validated IQ timestamps

**What LagAnalysisFusi does:**
- Reads timestamps directly from raw IQ/RF binary files (`fUS_block_rf_*.bin` or `fUS_block_tt_*.bin`)
- Extracts actual acquisition time for each frame
- Compares recorded timeline vs intended regular sampling
- Returns precise frame timestamps

**Result:** Most precise timing possible, irregular frames removed

#### Path 2: WITHOUT IQ/RF Data (Catch Block - Standard Path)

**Fallback when IQ/RF files unavailable:**

Uses TTL-based frame timing directly.

**Why this path is typically used:**
- Raw IQ/RF files are **very large** (10-100 GB per session)
- Typically **removed after PDI processing** to save disk space
- Only retained for special timing analysis or reprocessing
- PDI data (already processed) is what's kept long-term

**Processing steps:**
1. Extract frame timestamps directly from TTL falling edges
2. Calculate average frame interval from TTL timing
3. Keep all frames (no filtering)

**Result:** Excellent timing precision (~0.2ms), all frames retained

### Why Both Paths Are Valid

| Aspect | With IQ Data | Without IQ Data (Standard) |
|--------|--------------|---------------------------|
| **Timing Source** | Raw acquisition timestamps | TTL hardware signals |
| **Precision** | Most precise (~0.1ms) | Excellent (~0.2ms) |
| **Frame Filtering** | Yes (~5-10% removed) | No (all frames kept) |
| **Data Requirements** | IQ/RF binaries (10-100 GB) | PDI only (manageable size) |
| **Typical Use** | Special timing analysis | Standard functional imaging |
| **Availability** | Rare (files removed) | Common (expected path) |

### Important Notes

**The catch block is NOT an error condition:**
- This is the **expected processing path** for most datasets
- IQ/RF data deletion is standard practice after PDI conversion
- TTL timing provides adequate precision for virtually all functional imaging analyses
- No data quality concerns with TTL-based timing

**When to worry:**
- If BOTH IQ data is available AND the try block fails unexpectedly
- If TTL timing shows irregular patterns
- If neither timing source provides consistent frame intervals

### Console Output

**Standard case (IQ data unavailable):**
```
  Note: IQ/RF binary files not found in FUSI_data directory.
        These files are typically deleted after PDI conversion.
        
  ✓ Using TTL-based frame timing instead:
      - Timing precision: ~0.2ms (excellent)
      - All frames retained (no filtering)
      - Suitable for standard functional imaging analysis
        
  This is the expected processing path for most datasets.
```

**Special case (IQ data available):**
```
  ✓ Using precise timing from IQ/RF data (1142 of 1200 frames validated)
```

### 3d. Adjust PDI Timeline (Establish t=0)

**Purpose**: Transform frame timestamps from arbitrary TTL recording time into experiment-aligned time (t=0 = experiment start).

### The Processing Steps

#### Step 1: Shift Timestamps Forward by Frame Duration

**What happens**: Add mean frame interval to all timestamps

**Why this matters:**
- TTL falling edge marks when frame acquisition **starts**
- The frame is not **complete** until ~0.5 seconds later (for 2 Hz imaging)
- Adding mean frame interval shifts timestamps to frame **completion** time
- Ensures stimulation events align with the correct imaging frame

**Example transformation:**
```
Before: [0.0, 0.5, 1.0, 1.5, 2.0] - marks acquisition START
After:  [0.5, 1.0, 1.5, 2.0, 2.5] - marks frame COMPLETION
```

#### Step 2: Find Experiment Start Marker

**Purpose**: Identify the official experiment start point

**Edge detection**:
```matlab
initTTL = detect_ttl_edges(ttlData, config.ttl_channels.experiment_start, 'rising');
```

**What it does:**
- Searches for **first rising edge** (0→1 transition) in configured channel (typically 6)
- This marks the operator's "start experiment" signal
- Falls back to alternative channel if primary is inactive
- Uses only the FIRST rising edge found (critical!)

**Why this matters:**
- TTL recording often starts before the experiment begins
- Pre-experiment period includes setup, calibration, or waiting
- This marker establishes the reference point for t=0
- All data before this point is excluded

#### Step 3: Delete Pre-Experiment TTL Data

**Purpose**: Remove pre-experiment TTL recordings

**Effect:**
- Deletes all TTL rows before the experiment start marker
- Cleans up pre-experiment noise and activity
- TTL array now begins at the moment the experiment starts

#### Step 4: Align Everything to t=0

**Purpose**: Create zero-based timeline where experiment start = 0 seconds

**This is the critical alignment step:**
- Takes the first timestamp in TTL (experiment start)
- Subtracts it from ALL timestamps (both PDI and TTL)
- Result: First acquisition occurs at t=0
- Both PDItime and TTLinfo now share the same t=0 reference

**Example transformation:**
```
Before alignment:
  TTLinfo(1,1) = 125.3 seconds (absolute TTL time)
  PDItime = [125.8, 126.3, 126.8, 127.3, ...]

After alignment:
  TTLinfo(1,1) = 0.0 seconds
  PDItime = [0.5, 1.0, 1.5, 2.0, ...]
```

#### Step 5: Remove Frames with Negative Time

**Purpose**: Remove frames acquired before experiment started

**Why frames might have negative time:**
- Remember: Step 1 shifted all timestamps forward by frame interval
- Some frames were acquired **before** the experiment start marker
- After t=0 alignment (Step 4), these appear as negative times
- These pre-experiment frames must be removed

**Example scenario:**
```
Timeline:
  Acquisition starts: t = -0.5s (relative to experiment start)
  Experiment marker:  t = 0.0s (rising edge in channel 6)
  
Frames:
  Frame at t = -0.5s → removed (pre-experiment)
  Frame at t = 0.0s  → removed (pre-experiment)
  Frame at t = 0.5s  → kept (first valid frame)
  Frame at t = 1.0s  → kept
```

#### Step 6: Store Final Aligned Data

**Purpose**: Save cleaned, aligned timestamps in structure

**Stored variables:**
- `pdiTime`: Vector of frame timestamps (all ≥ 0, aligned to experiment start)
- `scanParams.dt`: Average frame interval (e.g., 0.5s for 2 Hz imaging)

### Complete Timeline Transformation Example

```
INITIAL STATE (from lag correction):
  Raw TTL times:     [100.0, 100.5, 101.0, 101.5, 102.0, 102.5, 103.0, ...]
  Experiment marker at: 101.2s (somewhere in the recording)

STEP 1 - Shift forward by frame interval (~0.5s):
  PDItime:           [100.5, 101.0, 101.5, 102.0, 102.5, 103.0, 103.5, ...]

STEP 2 - Find experiment start:
  initTTL index identified at t = 101.2s

STEP 3 - Remove pre-experiment TTL:
  TTL array trimmed, now starts at 101.2s

STEP 4 - Align to t=0 (subtract 101.2s):
  TTLinfo(:,1):      [0.0, 0.3, 0.8, 1.3, 1.8, ...]
  PDItime:           [-0.2, 0.3, 0.8, 1.3, 1.8, ...]

STEP 5 - Remove negative times:
  PDItime:           [0.3, 0.8, 1.3, 1.8, ...]
  Corresponding frames kept in pdi array

FINAL RESULT:
  First frame timestamp: t = 0.3s
  All frames have t ≥ 0
  Ready for event synchronization
```

### Why This Section is Critical

**Before this section:**
- Frame timestamps in arbitrary TTL recording time
- Experiment start buried somewhere in the middle of recording
- Pre-experiment calibration data still present
- No common temporal reference between data streams

**After this section:**
- All timestamps aligned to t=0 (experiment start)
- Pre-experiment data cleanly removed
- Common timeline established for all data streams
- Ready for stimulation event extraction and behavioral data alignment

### Console Output

```
→ Timeline synchronization:
  ✓ Using TTL-based frame timing instead:
      - Timing precision: ~0.2ms (excellent)
      - All frames retained (no filtering)
      - Suitable for standard functional imaging analysis
      
  This is the expected processing path for most datasets.

  ✓ Experiment start detected at t = 0.000 s
  ✓ PDI frames aligned: 1198 frames spanning 599.0 s
  ✓ Frame rate: 2.00 Hz (500 ms intervals)
```

### Success Criteria

Timeline successfully synchronized when:
- ✅ All PDI frames have TTL timestamps
- ✅ Experiment start marker found and processed
- ✅ All timestamps aligned to t=0
- ✅ Pre-experiment frames removed
- ✅ Frame rate consistent and reasonable
- ✅ Ready for event extraction

---

## 4. Extract Stimulation Events

### What Happens

This section auto-detects available stimulation files and extracts event timing using configured TTL channels. This is a major improvement over the old version - stimulation types are now detected automatically rather than requiring specific code paths.

### Scripts Used
**Primary script**: `detect_and_load_stimulation.m`

This orchestrator:
1. Checks for each stimulation file type
2. Calls appropriate extraction function if file exists
3. Uses TTL channels from configuration
4. Combines all events into single table
5. Sorts by start time

**Event extraction scripts**:
- `extract_shock_events.m` - Shock stimulation
- `extract_visual_events.m` - Visual stimulation
- `extract_auditory_events.m` - Auditory stimulation

**Utility script**: `detect_ttl_edges.m` - Edge detection

### 4a. Visual Stimulation

**File checked**: `VisualStimulation.csv`

**TTL channel**: From `config.ttl_channels.visual` (typically channel 10)

**Processing**:

**Primary method (TTL-based)**:
1. Detect rising edge (0→1) = stimulus **ON**
2. Detect falling edge (1→0) = stimulus **OFF**
3. Calculate duration for each event
4. Remove events shorter than 10ms (electrical noise)
5. Label all events as "visual"

**Fallback method (CSV-based)**:
- Used when TTL channel has no activity
- Reads timestamps from VisualStimulation.csv
- Aligns to experiment timeline using NIDAQ offset
- Provides redundancy in timing system

**Why dual-source pattern?**
- **Hardware first** (TTL): Most precise (~0.2ms)
- **Software fallback** (CSV): Adequate precision (~1-10ms)
- Automatic fallback if TTL empty

**Noise filtering:**
- 10ms threshold (vs 100ms for shock)
- Visual stimuli typically brief (10-1000ms)
- Lower threshold catches rapid flashes while removing artifacts

### 4b. Shock Stimulation

**File checked**: `ShockStimulation.csv`

**TTL channels**: From `config.ttl_channels.shock` (can be array: [4, 5, 12])

**Processing**:

**Reads shock metadata** from ShockStimulation.csv to determine paradigm type:

**Paradigm 1: Tail Shock**
- Edge detection: Falling edge (1→0) = shock START, Rising edge (0→1) = shock END
- Noise filtering: Removes events shorter than 0.1s
- Optional metadata: Integrates shockIntensities_and_perceivedSqueaks.xlsx if present
  - Shock intensities (mA)
  - Behavioral ratings (perceived squeaks/vocalizations)
- Condition label: "shock_tail"

**Paradigm 2: Left/Right Shock**
- Same edge detection as tail shock
- Condition labeling:
  - "left" → "shockOBS" (observed shock - for social learning paradigms)
  - "right" → "shockCTL" (control shock)

**Peculiarities:**

**1. Inverted TTL Logic**
- Unlike visual/auditory, shock uses **falling edge** for onset
- Reflects hardware implementation of shock delivery system

**2. Multiple Channel Support**
- Config can specify array of channels: `"shock": [4, 5, 12]`
- Checks all channels with OR logic
- Ensures detection even if specific channel fails

**3. Duration Filtering**
- Aggressive noise removal (0.1s threshold vs 10ms for visual)
- Prevents brief electrical artifacts from being logged as events

### 4c. Auditory Stimulation

**File checked**: `auditoryStimulation.csv`

**TTL channel**: From `config.ttl_channels.auditory` (typically channel 11)

**Processing**:

Identical to visual stimulation processing, but:
- Uses different TTL channel
- Labels events as "CS" (Conditioned Stimulus) rather than "auditory"
- CSV fallback uses "audio_start" and "audio_stop" markers

**CS Labeling Convention:**
- "CS" = Conditioned Stimulus (learning paradigm terminology)
- Distinguishes from unconditioned stimuli (US, typically shocks)
- Reflects common use in fear conditioning or associative learning studies

### Event Storage Structure

All stimulation events combined into single `stimInfo` table with columns:

| Column | Type | Description |
|--------|------|-------------|
| `stimCond` | cell array | "visual", "shock_tail", "shockOBS", "shockCTL", or "CS" |
| `startTime` | double | Event onset (seconds, aligned to PDI.time) |
| `endTime` | double | Event offset (seconds, aligned to PDI.time) |
| `shockIntensity` | double | Current in mA (tail shock only, if Excel present) |
| `perceivedSqueaks` | double | Behavioral rating (tail shock only, if Excel present) |

**Final processing:**
- Events sorted by start time
- Ready for integration into PDI structure

### Console Output Example

```
→ Detected stimulation files:
  ✓ Visual stimulation: VisualStimulation.csv
    → Found 60 visual events (channel 10)
  ✗ Shock stimulation: Not found
  ✓ Auditory stimulation: auditoryStimulation.csv
    → Found 30 auditory events (channel 11)
```

### Key Improvements Over Old Version

**1. Auto-detection:**
- No need to comment/uncomment code sections
- Script automatically processes whatever files exist
- Cleaner console output showing what was found

**2. Configuration-based:**
- TTL channels specified in config file
- Easy to adapt to different hardware setups
- Self-documenting

**3. Modular extraction:**
- Each stimulus type has dedicated function
- Easy to add new stimulation types
- Better code organization and maintainability

---

## 5. Load Behavioral Data

### What Happens

This section auto-detects and loads three types of behavioral measurements: running wheel, head motion (g-sensor), and pupil camera timestamps. All are optional - warnings issued if missing, but processing continues.

### Scripts Used
**Primary script**: `detect_and_load_behavioral.m`

This function checks for and loads:
1. Running wheel data
2. G-sensor (accelerometer) data  
3. Pupil camera timestamps

### 5a. Running Wheel Data

**File checked**: `RunningWheel.csv`

**Processing:**
1. Read CSV as table
2. **Align timestamps**: Subtract first NIDAQ timestamp
3. Converts Unix timestamps → experiment-relative time
4. Preserve all columns (time, wheelspeed, etc.)

**Behavioral sensor alignment:**
- Wheel encoder and NIDAQ share same computer clock
- Simple offset subtraction achieves alignment
- More straightforward than TTL-based alignment

**High temporal resolution:**
- Wheel sampled at ~1000 Hz typically
- Much higher than PDI frame rate (2 Hz)
- Enables detailed behavioral analysis

**Storage**: Table with columns:
- `time`: Aligned timestamps (seconds)
- `wheelspeed`: Rotation speed
- Additional sensor-specific columns

### 5b. G-Sensor (Head Motion)

**File checked**: `GSensor.csv`

**Processing:**
1. Read CSV as table
2. **Align timestamps**: Subtract first NIDAQ timestamp
3. Remove `samplenum` column (redundant with time)

**Three-axis measurements:**
- Typically contains x, y, z acceleration components
- Enables detection of motion artifacts
- Critical for quality control of imaging data

**Motion artifact detection:**
- Large accelerations indicate head movement
- Can correlate with signal quality issues
- Used to exclude or correct corrupted frames

**Storage**: Table with columns:
- `time`: Aligned timestamps (seconds)
- `x`: Lateral acceleration
- `y`: Anterior-posterior acceleration
- `z`: Vertical acceleration

### 5c. Pupil Camera Timestamps

**File checked**: `pupil_camera.csv`

**Processing:**
- Simple file read - no processing or alignment performed
- Raw timestamps preserved
- Alignment deferred to analysis stage

**Timestamps only:**
- Contains only frame acquisition times
- Actual pupil video/images stored separately
- User must load and align video data in post-processing

**Storage**: Vector of camera frame timestamps

### Common Pattern Across Behavioral Data

All behavioral sensors follow similar workflow:
1. **Optional loading**: Warnings, not errors if missing
2. **NIDAQ alignment**: Subtract first timestamp (wheel and g-sensor)
3. **Table preservation**: Keep all original columns
4. **High sampling rate**: Typically 100-1000 Hz vs PDI's 1-10 Hz

This enables:
- Behavioral state analysis
- Quality control
- Correlation with brain activity
- Motion correction

### Console Output Example

```
→ Detected behavioral data:
  ✓ Running wheel: RunningWheel.csv
    → 598450 time points, speed range: 0.0-45.3 cm/s
  ✓ G-sensor: GSensor.csv
    → 598450 time points, 3-axis acceleration
  ✓ Pupil camera: pupil_camera.csv
    → 35880 time points
```

---

## 6. Assemble and Save PDI Structure

### What Happens

Final assembly of all processed data into the PDI structure and saving to disk. This creates the complete, analysis-ready output file.

### Scripts Used
- **build_pdi_structure.m**: Assembles final PDI structure
- **save_pdi_data.m**: Creates output directory and saves to disk

### 6a. Build PDI Structure

**Dimensions and metadata:**
- Stores spatial dimensions (nx, nz) and pixel spacing (dx, dz) from BFConfig
- Stores temporal dimensions (nt) and frame interval (dt)

**Imaging data:**
- Transfers [nz × nx × nt] imaging array into PDI structure

**Timestamps:**
- Stores aligned frame times (all relative to t=0)

**Stimulation events:**
- Adds stimInfo table (may be empty if no stimulation)

**Behavioral data:**
- Adds pupil, wheel, and g-sensor data (may be empty if unavailable)

**Metadata:**
- Stores save path for future reference

### Complete PDI Structure

The final `PDI.mat` file contains:

```matlab
PDI
├── PDI [nz × nx × nt]          % Imaging data
├── Dim                          % Dimensions & spacing
│   ├── nx, nz, nt              % Array dimensions
│   ├── dx, dz                  % Pixel spacing (mm)
│   └── dt                      % Frame interval (s)
├── time [nt × 1]               % Frame timestamps
├── stimInfo [table]            % All experimental events
│   ├── stimCond               % Event type
│   ├── startTime              % Onset times
│   └── endTime                % Offset times
├── pupil                       % Pupil tracking
│   └── pupilTime              % Camera timestamps
├── wheelInfo [table]           % Running wheel
│   ├── time                   % Aligned timestamps
│   └── wheelspeed             % Rotation speed
├── gsensorInfo [table]         % Head motion
│   ├── time                   % Aligned timestamps
│   └── x, y, z                % Acceleration
└── savepath                    % Output location
```

### 6b. Save PDI Data

**Output directory creation:**
- Automatically generates path in Data_analysis/ directory
- Mirrors input directory structure
- Creates directories if they don't exist

**Output location:**
```
Input:  Data_collection/subject/session/run-123-func/
Output: Data_analysis/subject/session/run-123-func/PDI.mat
```

**Advantages:**
- Separates raw data from processed results
- Consistent organization across experiments
- Easy to find processed data for a given experiment

**Single file output:**
- All data in one MAT file
- Simplifies data management
- Self-contained for sharing/archiving

### Console Output

```
→ Assembling PDI structure...

→ Saving data:
  ✓ Output directory created: /path/to/Data_analysis/.../run-123-func
  ✓ PDI.mat saved successfully (342.5 MB)
```

### Final Summary

After successful completion, the script displays a comprehensive summary:

```
Processing Complete!

Output location:
  /path/to/Data_analysis/.../run-123-func/PDI.mat

Data summary:
  • PDI dimensions: 256 × 128 × 1198 frames
  • Duration: 599.0 seconds (9.98 minutes)
  • Frame rate: 2.00 Hz
  • Stimulation events: 90 events
    - visual: 60 events
    - CS: 30 events
  • Behavioral data:
    - Running wheel: 598450 samples
    - G-sensor: 598450 samples
    - Pupil camera: 35880 frames

```

### Verification

After saving, verify completeness:

**Imaging data checks:**
- PDI data is non-empty
- Frame count matches timestamp count
- Dimensions match stored parameters

**Temporal alignment checks:**
- All timestamps ≥ 0
- Timestamps are sorted
- Frame intervals are consistent

**Data integrity checks:**
- Spatial dimensions match BFConfig
- All required fields present
- Save path is valid

### Success Criteria

Complete reconstruction achieved when PDI.mat contains:
- ✅ Imaging data properly reshaped and aligned
- ✅ Frame timestamps synchronized to t=0
- ✅ Stimulation events extracted and aligned
- ✅ Behavioral data loaded and aligned (if available)
- ✅ All metadata preserved
- ✅ File saved to correct location

The dataset is now ready for:
- Statistical analysis
- Visualization
- Machine learning
- Sharing with collaborators

---

# Summary

This refactored pipeline transforms raw functional ultrasound data into analysis-ready format through **6 major processing steps**:

**Step 1: Configuration Loading**
- Load TTL channel mappings from experiment_config.json
- Enable flexible configuration without code changes
- Display configuration for verification

**Step 2: Load Core Data**
- Scan parameters (BFConfig)
- Raw PDI binary (read and reshape to 3D)
- TTL timing signals
- NIDAQ/DAQ event log

**Step 3: Timeline Synchronization**
- Detect PDI frame markers using configured channels
- Reconcile frame counts with TTL markers
- Optional lag correction using IQ/RF data
- Establish t=0 timeline (experiment start)
- Remove pre-experiment frames

**Step 4: Extract Stimulation Events**
- Auto-detect available stimulation files
- Extract events using configured TTL channels
- Support multiple stimulation types (visual, shock, auditory)
- TTL primary, CSV fallback for redundancy

**Step 5: Load Behavioral Data**
- Auto-detect available behavioral files
- Running wheel, g-sensor, pupil camera
- Align timestamps to experiment timeline
- Optional - warnings if missing

**Step 6: Assemble and Save**
- Build complete PDI structure
- Create output directory
- Save to Data_analysis/ path
- Display comprehensive summary

## Key Architecture Features

**1. Configuration-Based Architecture**
- TTL channels in JSON file (no code changes needed)
- Self-documenting per-experiment configuration
- Easy adaptation to hardware variations

**2. Modular Code Organization**
- Organized into functional modules (io/, sync/, events/, assembly/)
- Single responsibility per function
- Better maintainability and extensibility

**3. Enhanced Error Handling**
- Helpful diagnostics when configuration is incorrect
- Suggests solutions (e.g., correct TTL channel)
- Auto-detects available data files

**4. Automatic Detection**
- No need to comment/uncomment code sections
- Processes whatever files are present
- Cleaner console output

**5. Centralized Utilities**
- `detect_ttl_edges.m` for consistent edge detection
- Reusable functions across all event types
- Better code reuse

## Key Principles

- **Graceful exception handling**: Optional data causes warnings, not errors
- **Multiple timing sources**: Hardware (TTL) preferred, software (CSV) fallback
- **Defensive programming**: Handles edge cases automatically
- **Temporal precision**: Sub-millisecond alignment of all data streams
- **Self-contained output**: Single MAT file with complete experiment
- **Configuration flexibility**: Adapt to different setups without code changes

The resulting `PDI.mat` file provides a synchronized, analysis-ready dataset where all imaging frames, experimental events, and behavioral measurements share a common temporal reference (t=0 = experiment start).

---
