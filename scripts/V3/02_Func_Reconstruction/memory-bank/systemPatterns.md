# System Patterns: fUSI Reconstruction Architecture

> **Note**: This documentation reflects the refactoring work completed in `02_Functional_Reconstruction/` with sample data located in `sample_data/`. Architecture patterns remain the same, but file locations have been updated.

## Overall Architecture

### High-Level Data Flow
```
[Raw Data Collection] → [RAW_2_MAT.m] → [Structured Analysis Data]
       ↓                      ↓                    ↓
  Multiple files      Synchronization &       PDI.mat
  Various formats       Processing           Single file
```

### Processing Pipeline Stages

The refactored `do_reconstruct_functional.m` implements this pipeline using modular functions:

```
1. INPUT VALIDATION & SETUP
   ├── Parse/validate input paths (main script)
   ├── Generate output path structure (utils/generate_save_path.m)
   └── Locate FUSI_data directory (io/load_core_data.m)

2. CONFIGURATION LOADING
   ├── Load experiment_config.json (utils/load_experiment_config.m)
   ├── Parse TTL channel assignments (utils/parse_config.m)
   └── Display configuration (utils/print_ttl_config.m)

3. PARAMETER LOADING
   ├── Load BFConfig from MAT files (io/load_core_data.m)
   └── Extract imaging dimensions (Nx, Nz, ScaleX, ScaleZ)

4. RAW DATA READING
   ├── Read binary PDI data (io/load_core_data.m)
   ├── Calculate temporal dimension (nt)
   └── Reshape to 3D array [nz × nx × nt]

5. TTL SYNCHRONIZATION
   ├── Read TTL timing signals (io/load_core_data.m)
   ├── Identify PDI frame markers (processing/detect_ttl_edges.m)
   ├── Reconcile frame count (sync/synchronize_timeline.m)
   └── Trim excess frames or events

6. LAG CORRECTION (optional, if IQ data exists)
   ├── Call LagAnalysisFusi() (sync/synchronize_timeline.m)
   ├── Validate frame timing consistency
   ├── Filter irregular frames
   └── Generate corrected timestamps

7. TIMELINE ALIGNMENT
   ├── Find first acquisition event (sync/synchronize_timeline.m)
   ├── Shift all times to t=0 reference
   ├── Adjust PDI times by mean frame interval
   └── Remove pre-acquisition frames

8. EVENT EXTRACTION
   ├── Auto-detect stimulation files (events/detect_and_load_stimulation.m)
   ├── Shock stimulation (events/extract_shock_events.m)
   ├── Visual stimulation (events/extract_visual_events.m)
   ├── Auditory stimulation (events/extract_auditory_events.m)
   └── Build stimInfo table

9. BEHAVIORAL DATA INTEGRATION
   ├── Auto-detect behavioral files (io/detect_and_load_behavioral.m)
   ├── Running wheel timestamps and speeds
   ├── G-sensor (accelerometer x,y,z)
   └── Pupil camera timestamps

10. OUTPUT GENERATION
    ├── Assemble PDI structure (assembly/build_pdi_structure.m)
    ├── Create output directory (assembly/save_pdi_data.m)
    └── Save PDI.mat file
```

## Key Design Patterns

### Pattern 1: Graceful Degradation
**Principle**: Handle missing optional data without failing

**Implementation**:
```matlab
% Try loading, provide fallback if missing
if exist(filepath, 'file')
    data = load(filepath);
else
    data = [];  % or default value
    warning('File not found!');
end
```

**Applied To**:
- Pupil camera data
- Running wheel data
- G-sensor data
- Various stimulation files
- Secondary scan parameter files

### Pattern 2: Edge Detection for Event Timing
**Principle**: Use signal transitions to identify events

**Implementation**:
```matlab
% Falling edge detection (1 → 0 transition)
startIndices = find(diff(TTLinfo(:,channel)) < 0);

% Rising edge detection (0 → 1 transition)
endIndices = find(diff(TTLinfo(:,channel)) > 0);

% Extract timestamps
startTimes = TTLinfo(startIndices, 1);
```

**Applied To**:
- PDI frame markers
- Stimulation onset/offset
- First acquisition event

### Pattern 3: Dual-Source Data Resolution with Synchronized References
**Principle**: Try primary source (TTL), fall back to secondary (CSV) if needed

**Critical Design Note**: The DAQ.csv first timestamp (`NIDAQInfo.time(1)`) is synchronized to the experiment start marker determined from TTL. This makes it a valid proxy for the experiment start when TTL stimulus information is missing.

**Implementation**:
```matlab
% Primary path: Use TTL timing (preferred)
startTimes = ttlData(startIndices, 1);  // Already aligned to experiment start

% Fallback: Use CSV timing when TTL missing
if isempty(startTimes)
    stimInfo.time = stimInfo.time - NIDAQInfo.time(1);  // Valid: DAQ synced to exp start
    startTimes = stimInfo.time(strcmp('stim', stimInfo.stim));
end
```

**Why This Works**:
- DAQ recording is started at (or very close to) the experiment start marker
- `NIDAQInfo.time(1)` represents the same reference point as TTL experiment start
- Both paths produce times relative to the same experiment start
- No additional alignment correction needed

**Applied To**:
- Scan parameter files (post_ vs regular)
- NIDAQ files (NIDAQ.csv vs DAQ.csv)
- Visual stimulation (TTL vs CSV timing)
- Auditory stimulation (TTL vs CSV timing)
- Running wheel data alignment
- G-sensor data alignment

### Pattern 4: Frame Count Reconciliation
**Principle**: Handle mismatch between expected and actual frames

**Implementation**:
```matlab
if numTTLEvents < numFrames
    % Too many frames → trim extras
    data(:,:,numTTLEvents+1:end) = [];
elseif numTTLEvents > numFrames
    % Too many events → trim extras
    events(numFrames+1:end) = [];
end
```

**Applied To**:
- PDI frame synchronization with TTL

### Pattern 5: Timeline Zero Alignment
**Principle**: Establish common time reference across all data streams

**Implementation Steps**:
1. Find experiment start marker (first rising edge in channel 6 or 5)
2. Remove all data before this marker
3. Subtract start time from all timestamps
4. Result: All data streams share t=0 reference

**Applied To**:
- PDI timestamps
- TTL timing
- Behavioral data (wheel, gsensor)
- Stimulation events

## Critical Component Relationships

### BFConfig → PDI Reshaping
```
BFConfig.Nx, BFConfig.Nz → Spatial dimensions
BFConfig.ScaleX, ScaleZ → Pixel spacing (mm)
                ↓
Used to reshape 1D binary → 3D [nz × nx × nt]
                ↓
Stored in PDI.Dim for reference
```

### TTL → Event Timing
```
TTL Channel 3 (Events) → PDI frame markers
Channel 4,5,12 (Shock) → Shock stimulation timing
Channel 6 (AdjustPDI)  → Experiment start marker
Channel 10 (Visual)    → Visual stim timing
Channel 11 (Auditory)  → Audio stim timing
                ↓
All extracted via edge detection
                ↓
Combined with CSV metadata
                ↓
Stored in PDI.stimInfo
```

### LagAnalysisFusi → Frame Timing
```
IQ Data (if exists) → LagAnalysisFusi()
                ↓
Returns: timeTagsSec (actual frame times)
                ↓
Validate consistency (±0.01s tolerance)
                ↓
Filter irregular frames (acceptIndex)
                ↓
Align with TTL timestamps
                ↓
Stored in PDI.time
```

### DAQ/NIDAQ → Behavioral Data Alignment
```
DAQ.csv → First timestamp (NIDAQInfo.Var1(1))
                ↓
Used as reference for behavioral data
                ↓
Wheel, GSensor timestamps adjusted:
  adjustedTime = originalTime - NIDAQInfo.Var1(1)
                ↓
Ensures behavioral data aligns with PDI timeline
```

## Error Handling Strategy

### Fatal Errors (script stops)
- No data path provided and user cancels selection
- Data path doesn't contain 'Data_collection'
- No FUSI_data directory found
- No scan parameter files found
- No PDI binary file found
- No TTL file found
- No NIDAQ log file found

### Non-Fatal Warnings (continues with degradation)
- Pupil camera data missing
- Running wheel data missing
- G-sensor data missing
- Stimulation files missing
- IQ data missing (skips lag correction)

## Data Structure Design

### PDI Structure Hierarchy
```
PDI (struct)
├── PDI [nz × nx × nt double]       % Main imaging data
├── Dim (struct)
│   ├── nx, nz                      % Spatial dimensions
│   ├── dx, dz                      % Pixel spacing (mm)
│   ├── nt                          % Number of time points
│   └── dt                          % Frame interval (s)
├── time [nt × 1 double]            % Frame timestamps
├── stimInfo (table)                % Stimulation events
│   ├── stimCond [cell string]      % Condition labels
│   ├── startTime [double]          % Event start times
│   ├── endTime [double]            % Event end times
│   └── [additional columns]        % Experiment-specific
├── pupil (struct)
│   └── pupilTime                   % Camera timestamps
├── wheelInfo (table)               % Running wheel
│   ├── time                        % Wheel timestamps
│   └── wheelspeed                  % Speed values
├── gsensorInfo (table)             % Accelerometer
│   ├── time                        % Sensor timestamps
│   └── x, y, z                     % Acceleration axes
└── savepath [char]                 % Output directory
```

## Performance Considerations

### Memory Management
- Binary PDI file loaded entirely into memory
- Large files (several GB) require adequate RAM
- Temporary rawPDI cleared after reshaping
- No streaming or chunk-based processing

### File I/O Patterns
- Sequential reads preferred (binary files)
- Multiple small CSV reads (can be inefficient for large files)
- MAT file loads entire structure (no partial loading)

### Computational Bottlenecks
- Binary file reading (I/O bound)
- Array reshaping (memory allocation)
- Edge detection on long TTL arrays (diff operations)
- No parallel processing utilized

## Future Extensibility Points

### Already Implemented
1. ✅ **Configurable TTL mapping**: Now reads from `experiment_config.json`
2. ✅ **Modular architecture**: 15 focused functions in organized folders
3. ✅ **Clear feedback**: Terminal output with status indicators
4. ✅ **Auto-detection**: Automatic discovery of available data files

### Potential Future Improvements
1. **Streaming binary reads**: Process chunks instead of full load (for very large files)
2. **Parallel processing**: Utilize MATLAB's parfor for independent operations
3. **Validation reporting**: Generate QC report with plots and diagnostics
4. **Format flexibility**: Support alternative binary formats (e.g., compressed PDI)
5. **Error recovery**: Attempt repair of common data issues
6. **Batch processing utilities**: Built-in multi-run processing functions
