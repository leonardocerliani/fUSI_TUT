# Timeline Synchronization

## Purpose

The `synchronize_timeline.m` script assigns timestamps to PDI frames, creating a unified timeline that synchronizes brain imaging data with experimental events (stimuli, behavioral data).

**Core objective**: Establish temporal correspondence between:
- Brain activity frames (`pdiData`)
- Hardware timing signals (`ttlData`)
- Experimental events (stimulation, behavior)

---

## Inputs & Outputs

### Inputs
- `pdiData` - 3D array [nz × nx × nt] of brain imaging frames
- `scanParams` - Scan configuration (BFConfig structure)
- `ttlData` - Hardware timing signals [time, channels]
- `config` - Experiment configuration (TTL channel assignments)
- `datapath` - Path to experiment data

### Outputs
- `pdiData` - Same array, possibly trimmed to match TTL markers
- `pdiTime` - Timestamp for each frame [nt × 1], aligned to t=0
- `scanParams` - Updated with frame interval (dt)
- `ttlData` - Modified TTL array with pre-experiment data removed and timestamps shifted to t=0 (CRITICAL: must be returned for event extraction to work correctly)

---

## Data Flow

### 1. Detect PDI Frame Markers

```matlab
PDITTL = detect_ttl_edges(ttlData, ttl.pdi_frame, 'falling');
```

**What**: Extracts row indices from `ttlData` where PDI frame markers occur (falling edges on configured channel)

**Result**: `PDITTL` contains row numbers pointing to frame acquisition times
- Example: `[80449, 81449, 82449, ...]` (unitless indices)
- Spacing: ~1000 rows apart (0.2s at 5000 Hz TTL sampling)

**Purpose**: Identify when each frame was acquired in the hardware timeline

### 2. Reconcile Frame Counts

```matlab
if numPDITTL < numPDIframes
    pdiData(:, :, numPDITTL+1:end) = [];
elseif numPDITTL > numPDIframes
    PDITTL(numPDIframes+1:end) = [];
end
```

**Why needed**: Hardware timing (TTL) and imaging system may record slightly different numbers due to:
- Buffer overruns
- System start/stop timing differences
- Incomplete writes

**What it does**: Ensures one-to-one correspondence
- `numPDITTL` = Number of TTL frame markers
- `numPDIframes` = Actual frames in `pdiData`
- Trims excess from whichever is larger

**Critical**: Every frame must have exactly one timestamp for downstream indexing to work

### 3. Lag Correction (Optional)

**Two paths:**

#### Path A: IQ/RF Data Available (Rare)
```matlab
[~, timeTagsSec] = LagAnalysisFusi(fusDatapath);
PDItime = ttlData(PDITTL(1), 1) + timeTagsSec(acceptIndex);
```
- Loads raw ultrasound timing from IQ/RF binary files (~10-100 GB)
- Validates frame intervals in 1-second blocks (reject >10ms jitter)
- Filters irregular frames
- Provides sub-millisecond precision

#### Path B: TTL-Based Timing (Standard)
```matlab
PDItime = ttlData(PDITTL, 1);
```
- Uses TTL timestamps directly
- Precision: ~0.2ms (excellent for fUSI analysis)
- No frame filtering
- **Most common path** (IQ/RF files typically deleted to save space)

**Output**: `PDItime` contains initial timestamps for each frame (seconds)

### 4. Timestamp Adjustment

```matlab
PDItime = PDItime + mean(diff(PDItime));
```

**Why**: Accounts for frame acquisition duration

**Concept**:
- TTL falling edge marks frame acquisition **start**
- Adding one frame interval shifts timestamps to acquisition **end**
- Ensures timestamps represent the temporal data frames contain

**Example**:
```
Before: [16.09, 16.29, 16.49, ...] s (acquisition starts)
After:  [16.29, 16.49, 16.69, ...] s (acquisition ends)
```

**Benefit**: Better synchronization with instantaneous events (e.g., stimulus at t=16.25s is correctly associated with frame ending at 16.29s)

### 5. Align to t=0 (Experiment Start)

```matlab
initTTL = detect_ttl_edges(ttlData, ttl.experiment_start, 'rising');
ttlData(1:initTTL-1, :) = [];
PDItime = PDItime - ttlData(1,1);
ttlData(:,1) = ttlData(:,1) - ttlData(1,1);
```

**Why**: Experiments typically start 10-30s after recording begins (setup period)

**Process**:
1. Find experiment start marker (rising edge, usually channel 6)
2. Remove all TTL data before this marker
3. Subtract experiment start time from all timestamps
4. Result: Experiment start = t=0

**Example**:
```
Hardware timeline: [0s ---- 15s ---- 120s]
                           ↑ Experiment starts
After alignment:   [0s ------------- 105s]
                    ↑ Now t=0
```

### 6. Remove Pre-Experiment Frames

```matlab
validFrames = PDItime >= 0;
pdiData(:, :, ~validFrames) = [];
PDItime(~validFrames) = [];
```

**Why**: After time shift, frames acquired before experiment start have negative timestamps

**Process**:
- Keep only frames with t ≥ 0
- Discards irrelevant setup/baseline frames
- Simplifies downstream analysis (no offset to remember)

---

## Key Concepts

### PDITTL
- **Type**: Array of row indices (not times)
- **Content**: Points to rows in `ttlData` where frame markers occurred
- **Purpose**: Reference for extracting frame timestamps
- **Usage**: `ttlData(PDITTL, 1)` retrieves actual timestamps

### Frame Reconciliation
- **Ensures**: `length(PDItime) == size(pdiData, 3)`
- **Critical for**: All downstream frame indexing operations
- **Impact**: Small (~1-3 frames, <1% of data typically trimmed)

### Timeline Unification
Final result enables questions like:
- "What was brain activity 2s after each shock?"
- "Which frames occurred during visual stimulation?"
- "How did behavior correlate with brain responses?"

All possible because PDI frames, stimuli, and behavior share the same t=0 reference.

### DAQ-TTL Synchronization (Critical for Event Extraction)

**Important**: The DAQ recording (DAQ.csv/NIDAQ.csv) is synchronized with TTL timing:

```
Hardware Setup:
- DAQ recording starts at (or very close to) experiment start marker
- NIDAQInfo.time(1) represents the same reference point as TTL experiment start
```

**Implication for Event Extraction**:
When TTL stimulus information is missing, CSV files (VisualStimulation.csv, etc.) can be aligned using:
```matlab
stimInfo.time = stimInfo.time - NIDAQInfo.time(1);
```

This produces times relative to the same experiment start as TTL-based events, ensuring:
- No additional correction needed
- TTL and CSV paths produce equivalent timestamps
- Both methods reference the same t=0

**Why this matters**: Event extraction modules can safely fall back to CSV timing when TTL channels don't record stimulus information, without introducing alignment errors.

---

## Output Summary

After completion:
- `pdiTime[i]` = timestamp when `pdiData(:,:,i)` was acquired
- All times relative to experiment start (t=0)
- Pre-experiment data removed
- One-to-one frame-to-timestamp correspondence guaranteed
- Frame rate calculated and stored in `scanParams.dt`

---

## Dependencies

- `detect_ttl_edges()` - [src/processing/] Edge detection in TTL channels
- `LagAnalysisFusi()` - [external] Optional IQ/RF timing analysis

---

## Typical Execution

```
→ Timeline synchronization:
  ✓ Using TTL-based frame timing (0.2ms precision)
  ✓ Experiment start detected at t = 0.000 s
  ✓ PDI frames aligned: 1842 frames spanning 368.4 s
  ✓ Frame rate: 5.00 Hz (200 ms intervals)
```
