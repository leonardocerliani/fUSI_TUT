# fUSI Data Reconstruction - Code Walkthrough

## Overview

The `do_reconstruct_functional.m` script converts raw fUSI data (PDI binary, TTL signals, stimulation logs) into a structured MAT file for downstream analysis. The pipeline automatically detects available data files based on `experiment_config.json` and processes them accordingly.

```matlab
PDI = do_reconstruct_functional(datapath, savepath)
```

🔧 **For in-depth technical details and implementation specifics, see:**  
[Technical Documentation](FUNC_RECONSTRUCTION_TECH_DOCUMENT.md)

---

## 1. Get Data Path

**Dependencies:**
```
src/utils/generate_save_path.m
```

```matlab
%% Step 1: Get data path
if nargin < 1 || isempty(datapath)
    datapath = uigetdir('', 'Select functional scan directory');
    if datapath == 0
        error('Data path selection canceled.');
    end
end

if nargin < 2 || isempty(savepath)
    savepath = generate_save_path(datapath);
end
```

If no path is provided, opens a dialog to select the data directory (typically `Data_collection/run-XXXXX-func/`). The save path is automatically generated to mirror the structure in `Data_analysis/`.

---

## 2. Load Configuration

**→ [See technical details: Load Configuration](FUNC_RECONSTRUCTION_TECH_DOCUMENT.md#1-load-configuration)**

**Dependencies:**
```
src/utils/load_experiment_config.m
src/utils/parse_config.m
src/utils/print_ttl_config.m
```

```matlab
%% Step 2: Load and display config
fprintf('→ Loading configuration: experiment_config.json\n');
config = load_experiment_config(datapath);
print_ttl_config(config);
```

### Configuration File Structure

The `experiment_config.json` file must be present in the data directory. It contains TTL channel assignments specific to each experiment:

```json
{
  "experiment_id": "run-115047-func",
  "ttl_channels": {
    "pdi_frame": 3,
    "experiment_start": 6,
    "visual": 10,
    "auditory": 11,
    "shock": [4, 5, 12]
  }
}
```

**Key Points:**
- **`pdi_frame`**: Channel carrying frame synchronization pulses
- **`experiment_start`**: Channel marking experiment onset
- **`visual/auditory/shock`**: Stimulation trigger channels
- If the config file is missing, the script displays a template and exits

---

## 3. Load Core Data

**→ [See technical details: Load Core Data Files](FUNC_RECONSTRUCTION_TECH_DOCUMENT.md#2-load-core-data-files)**

**Dependencies:**
```
src/io/load_core_data.m
```

```matlab
%% Step 3: Load core data with status
fprintf('\n→ Loading core data files:\n');
[pdiData, scanParams, ttlData, nidaqLog] = load_core_data(datapath, config);
```

### Data Loading Process

The `load_core_data()` function loads four essential data sources:

#### 3.1 Scan Parameters
```matlab
% Look for scan parameter files in FUSI_data directory
scanParamFiles = {'post_L22-14_PlaneWave_FUSI_data.mat', 
                  'L22-14_PlaneWave_FUSI_data.mat'};
```
Loads `BFConfig` structure containing spatial dimensions (`Nx`, `Nz`) and scale factors (`ScaleX`, `ScaleZ`).

#### 3.2 PDI Binary Data
```matlab
pdiFile = fullfile(fusDatapath, 'fUS_block_PDI_float.bin');
fid = fopen(pdiFile, 'r');
rawPDI = fread(fid, inf, 'single');
fclose(fid);

nt = numel(rawPDI) / (BFConfig.Nx * BFConfig.Nz);
pdiData = reshape(rawPDI, [BFConfig.Nz, BFConfig.Nx, nt]);
```
Reads the raw PDI binary file (single-precision floats) and reshapes into 3D array [Z × X × Time].

#### 3.3 TTL Signal Data
```matlab
ttlFiles = dir(fullfile(datapath, 'TTL*.csv'));
ttlData = readmatrix(fullfile(ttlFiles(1).folder, ttlFiles(1).name));
```
Loads TTL channels recorded by the data acquisition system. Each row is a time point, each column is a TTL channel.

#### 3.4 NIDAQ Log
```matlab
nidaqFiles = {'NIDAQ.csv', 'DAQ.csv'};
nidaqLog = readtable(nidaqPath);
```
Loads the acquisition log containing timestamps for all recorded signals. Used as the master timeline reference.

**Output:**
```
✓ Scan parameters loaded: post_L22-14_PlaneWave_FUSI_data.mat
✓ PDI binary loaded: fUS_block_PDI_float.bin (128 × 128 × 1250 frames)
✓ TTL data loaded: TTL_01.csv (16 channels, 75000 samples)
✓ DAQ log loaded: DAQ.csv
```

---

## 4. Timeline Synchronization

**→ [See technical details: Timeline Synchronization](FUNC_RECONSTRUCTION_TECH_DOCUMENT.md#3-timeline-synchronization)**

**Dependencies:**
```
src/sync/synchronize_timeline.m
src/io/detect_ttl_edges.m
```

```matlab
%% Step 4: Timeline synchronization
fprintf('\n→ Timeline synchronization:\n');
[pdiData, pdiTime, scanParams, ttlData] = synchronize_timeline(pdiData, scanParams, ttlData, config, datapath);
```

### Purpose

Assign timestamps from `ttlData` to each PDI frame in `pdiData`, creating a common temporal reference between imaging data and external events (stimuli, behavior).

---

### Step 4.1: Detect PDI Frame Markers

```matlab
PDITTL = detect_ttl_edges(ttlData, ttl.pdi_frame, 'falling');
numPDITTL = numel(PDITTL);
numPDIframes = size(pdiData, 3);
```

Finds falling edges on the `pdi_frame` TTL channel. Each edge corresponds to one acquired PDI frame.

**Error handling:** If no edges are found, the script checks all channels and suggests the correct channel assignment.

---

### Step 4.2: Reconcile Frame Counts

```matlab
if numPDITTL < numPDIframes
    pdiData(:, :, numPDITTL+1:end) = [];    % too many frames → cut off extras
elseif numPDITTL > numPDIframes
    PDITTL(numPDIframes+1:end) = [];        % too many events → cut off extras
end
```

Ensures the number of TTL markers matches the number of PDI frames. Mismatches can occur due to acquisition glitches.

---

### Step 4.3: Precise Timing from IQ/RF Data (Optional)

```matlab
try
    % Attempt to load timing from raw IQ/RF binary files
    [~, timeTagsSec] = LagAnalysisFusi(fusDatapath);
    
    % Calculate frame interval
    frameInterval = mode(diff(timeTagsSec));
    blockDuration = ceil(1 / frameInterval);
    
    % Validate timing consistency in 1-second windows
    acceptIndex = true(size(timeTagsSec));
    for it = 1:numel(timeTagsSec)-blockDuration
        rangeInterval = range(diff(timeTagsSec(it:it+blockDuration)));
        if rangeInterval > 0.01  % More than 10ms variation
            acceptIndex(it) = false;
        end
    end
    
    % Align timeline
    PDItime = ttlData(PDITTL(1), 1) + timeTagsSec(acceptIndex);
    pdiData = pdiData(:, :, acceptIndex);
    
catch ME
    % IQ/RF files not available (normal case)
    PDItime = ttlData(PDITTL, 1);
    blockDuration = mode(diff(PDItime));
end
```

**Two timing paths:**

1. **IQ/RF timing** (if available): Uses raw acquisition timestamps with frame validation
   - Removes frames with timing jitter > 10ms
   - Provides highest temporal precision
   - IQ/RF files are typically 10-100 GB and deleted after PDI conversion

2. **TTL timing** (standard): Uses TTL timestamps directly
   - Precision: ~0.2ms (excellent)
   - All frames retained
   - **This is the expected path for most users**

---

### Step 4.4: Align to Experiment Start

```matlab
% Find experiment start marker
initTTL = detect_ttl_edges(ttlData, ttl.experiment_start, 'rising');
if ~isempty(initTTL)
    initTTL = initTTL(1);  % Use first event only
    
    % Remove pre-experiment data from TTL
    ttlData(1:initTTL-1, :) = [];
    
    % Shift timestamps to t=0
    PDItime = PDItime - ttlData(1,1);
    ttlData(:,1) = ttlData(:,1) - ttlData(1,1);
    
    % Remove negative time frames
    validFrames = PDItime >= 0;
    pdiData(:, :, ~validFrames) = [];
    PDItime(~validFrames) = [];
end
```

Synchronizes all timestamps to the experiment start marker, setting t=0 at experiment onset. Removes any pre-experiment acquisition frames.

**Output:**
```
✓ Using TTL-based frame timing instead:
    - Timing precision: ~0.2ms (excellent)
    - All frames retained (no filtering)
✓ Experiment start detected at t = 0.000 s
✓ PDI frames aligned: 1200 frames spanning 240.0 s
✓ Frame rate: 5.00 Hz (200 ms intervals)
```

---

## 5. Detect Stimulation and Behavioral Data

**→ [See technical details: Extract Stimulation Events](FUNC_RECONSTRUCTION_TECH_DOCUMENT.md#4-extract-stimulation-events) and [Load Behavioral Data](FUNC_RECONSTRUCTION_TECH_DOCUMENT.md#5-load-behavioral-data)**

**Dependencies:**
```
src/events/detect_and_load_stimulation.m
src/events/extract_visual_events.m
src/events/extract_shock_events.m
src/events/extract_auditory_events.m
src/events/detect_and_load_behavioral.m
```

```matlab
%% Step 5: Detect and load stimulation and behavioral data
fprintf('\n→ Detected stimulation files:\n');
stimInfo = detect_and_load_stimulation(datapath, ttlData, nidaqLog, config);

fprintf('\n→ Detected behavioral data:\n');
behavioral = detect_and_load_behavioral(datapath, nidaqLog);
```

### 5.1 Stimulation Detection

The pipeline automatically detects and extracts events from available stimulation CSV files:

```matlab
% Check for visual stimulation
if exist(fullfile(datapath, 'VisualStimulation.csv'), 'file') && isfield(ttl, 'visual')
    events = extract_visual_events(datapath, ttlData, nidaqLog, ttl.visual);
    stimInfo = [stimInfo; events];
end

% Similar checks for shock and auditory
```

**Event Extraction:**
- Reads stimulation log CSV files
- Matches logged events to TTL pulses using timestamps
- Extracts trial timing (`startTime`, `endTime`) and parameters (`stimCond`, `intensity`, etc.)
- Returns a table with one row per trial

**Output:**
```
✓ Visual stimulation: VisualStimulation.csv
  → Found 40 visual events (channel 10)
✗ Shock stimulation: Not found
✗ Auditory stimulation: Not found
```

---

### 5.2 Behavioral Data Detection

```matlab
% Running wheel
wheelFile = fullfile(datapath, 'RunningWheel.csv');
if exist(wheelFile, 'file')
    wheelInfo = readtable(wheelFile);
    wheelInfo.time = wheelInfo.time - nidaqLog.time(1);  % Align to t=0
    behavioral.wheelInfo = wheelInfo;
end
```

Automatically loads available behavioral data:
- **Running wheel**: Locomotion speed (cm/s) at ~55 Hz
- **G-sensor**: 3-axis acceleration (motion artifacts)
- **Pupil camera**: Frame timestamps for pupil tracking

All behavioral timestamps are aligned to the experiment timeline (t=0).

**Output:**
```
✓ Running wheel: RunningWheel.csv
  → 13200 time points, speed range: 0.0-45.2 cm/s
✓ G-sensor: GSensor.csv
  → 13200 time points, 3-axis acceleration
✗ Pupil camera: Not found
```

---

## 6. Assemble and Save

**→ [See technical details: Assemble and Save PDI Structure](FUNC_RECONSTRUCTION_TECH_DOCUMENT.md#6-assemble-and-save-pdi-structure)**

**Dependencies:**
```
src/io/build_pdi_structure.m
src/io/save_pdi_data.m
```

```matlab
%% Step 6: Assemble and save
fprintf('\n→ Assembling PDI structure...\n');
PDI = build_pdi_structure(pdiData, pdiTime, scanParams, stimInfo, behavioral, savepath);
save_pdi_data(PDI, savepath);
```

### PDI Structure

The final `PDI` structure contains all processed data:

```matlab
PDI.Dim.nx         % Spatial dimensions (X)
PDI.Dim.nz         % Spatial dimensions (Z)
PDI.Dim.dx         % X-axis scale (mm)
PDI.Dim.dz         % Z-axis scale (mm)
PDI.Dim.nt         % Number of time frames
PDI.Dim.dt         % Frame interval (seconds)

PDI.PDI            % 3D array [Z × X × T]
PDI.time           % Frame timestamps [T × 1]

PDI.stimInfo       % Table of stimulation events
PDI.wheelInfo      % Running wheel data
PDI.gsensorInfo    % G-sensor data
PDI.pupil          % Pupil camera timestamps

PDI.savepath       % Output directory
```

The structure is saved as `PDI.mat` in the output directory (typically `Data_analysis/run-XXXXX-func/`).

---

## 7. Final Summary

**Dependencies:**
```
src/utils/print_final_summary.m
```

```matlab
%% Step 7: Final summary
print_final_summary(PDI, stimInfo, behavioral);
```

Prints a concise summary of the reconstructed data:

```
========================================
Reconstruction Complete
========================================

Output saved to:
  /path/to/Data_analysis/run-115047-func/PDI.mat

Data Summary:
  PDI dimensions: 128 × 128 × 1200 frames
  Duration: 240.0 seconds
  Frame rate: 5.00 Hz

Stimulation:
  Visual: 40 trials

Behavioral:
  Running wheel: Available
  G-sensor: Available
  Pupil camera: Not available

========================================
```

---

## Usage Example

```matlab
% Basic usage with dialog
PDI = do_reconstruct_functional();

% Specify paths
datapath = '/path/to/Data_collection/run-115047-func/';
savepath = '/path/to/Data_analysis/run-115047-func/';
PDI = do_reconstruct_functional(datapath, savepath);
```

---

## Key Design Principles

1. **Auto-detection**: Script automatically finds and processes available data files
2. **Graceful degradation**: Missing optional data (behavioral, certain stimulation types) doesn't cause errors
3. **Clear feedback**: Terminal output shows ✓/✗ indicators for each data component
4. **Minimal configuration**: Only TTL channels need to be specified in JSON config
5. **Experiment-specific config**: Each dataset has its own `experiment_config.json`
