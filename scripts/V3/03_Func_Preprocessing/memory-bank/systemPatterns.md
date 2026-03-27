# System Patterns: fUSI Preprocessing Architecture

## System Overview

The fUSI preprocessing pipeline processes functional ultrasound imaging data through a series of sequential transformations. The system consists of a main preprocessing script that orchestrates various helper functions to clean, align, and normalize the data.

## Current Architecture

### Data Flow
```
Input: Anatomical Path + Functional Path
  ↓
Load Data (PDI.mat, anatomic.mat, Transformation.mat, atlas)
  ↓
Create Brain Mask (from Allen atlas in subject space)
  ↓
Motion Correction (rigid in-plane, median reference)
  ↓
Outlier Rejection (voxelwise z-score thresholding + interpolation)
  ↓
Signal Conversion (to percent signal change)
  ↓
Temporal Resampling (to 5Hz)
  ↓
Highpass Filtering (DCT-based, cutoff 500 samples)
  ↓
Spatial Smoothing (Gaussian, σ=1)
  ↓
Output: prepPDI.mat
```

## Key Components

### 1. Main Preprocessing Script
**Current**: `Preprocessing_DEV.m`
- Script format (not a function)
- Uses `Datapath_DEV.m` for path management
- Contains `isub` indexing variable
- Processes single subject per execution
- Includes visualization code for mask verification

**Target**: Refactored function-based approach
- Function accepting input arguments
- No hardcoded paths
- No `isub` indexing
- Optional UI-based path selection
- Preserved preprocessing logic

### 2. Helper Functions (src/ directory)

#### Atlas2Individual.m
- Transforms Allen brain atlas to individual subject space
- Uses transformation matrix from anatomical registration
- Returns subject-specific atlas structure

#### DCThighpass.m
- Applies discrete cosine transform-based highpass filter
- Parameters: data, order (5), cutoff (500)
- Removes slow drift and low-frequency trends

#### fillmissingTime.m
- Interpolates NaN values along time dimension
- Used after outlier rejection
- Method: linear interpolation (configurable)

#### parsave.m
- Parallel-safe save function
- Enables saving from parallel workers
- Used for final output

#### PDIfilter.m
- Alternative filtering approach (in commented section)
- Supports 'highpass' mode
- Part of alternative preprocessing pipeline

#### resamplePDI.m
- Resamples PDI data to specified frequency
- Target: 5Hz (from original acquisition rate)
- Preserves spatial dimensions, adjusts temporal

### 3. Data Structures

#### PDI Structure (Power Doppler Imaging)
```matlab
PDI.PDI                    % 3D array [Y, X, Time]
PDI.savepath              % Output directory path
PDI.bmask                 % Binary brain mask [Y, X]
PDI.voxelFrameRjection    % Outlier rejection parameters
  .std                    % Z-score threshold (5)
  .interpMethod           % Interpolation method ('linear')
  .ratio                  % Fraction of rejected values
PDI.spatialSigma          % Gaussian smoothing parameter (1)
```

#### anatomic Structure
```matlab
anatomic.savepath         % Anatomical data directory
anatomic.funcSlice        % [X, Y, Z] of functional slice
```

#### Transf Structure
- Transformation matrix for atlas-to-subject registration
- Used by Atlas2Individual

#### atlas Structure (Allen Brain Atlas)
```matlab
atlas.Region.Data         % 3D labeled region data
```

## Key Technical Decisions

### 1. Motion Correction Approach
- **Method**: Translation-only (imregcorr)
- **Reference**: Median of all frames
- **Rationale**: Rigid in-plane motion only, preserves signal intensity
- **Output**: Spatially aligned time series

### 2. Outlier Handling Strategy
- **Detection**: Z-score > 5 per voxel across time
- **Treatment**: Flag as NaN, then interpolate
- **Rationale**: Remove spikes without losing timepoints
- **Tracking**: Records rejection ratio for QC

### 3. Signal Normalization
- **Method**: Percent signal change
- **Formula**: (signal - mean) / mean × 100
- **Alternative**: Z-score (commented out, for ISC analysis)
- **Rationale**: Standardizes for GLM analysis

### 4. Temporal Processing
- **Resampling**: From acquisition rate to 5Hz
- **Filtering**: Highpass to remove drift
- **Order**: Resampling before filtering (standard pipeline)

### 5. Spatial Processing
- **Smoothing**: Gaussian kernel, σ=1
- **FWHM**: ~2.355 voxels
- **Timing**: Last step in pipeline
- **Rationale**: Reduce noise, improve SNR

## Component Relationships

### Critical Dependencies
1. **Allen Atlas**: Required for brain mask creation
2. **Transformation Matrix**: Links anatomical to atlas space
3. **Anatomical Data**: Defines functional slice location
4. **Functional Data**: The primary data being preprocessed

### Processing Order Constraints
1. Motion correction must precede outlier detection
2. Outlier interpolation before signal conversion
3. Signal conversion before resampling (preserves units)
4. Resampling before filtering (filter parameters assume 5Hz)
5. Spatial smoothing last (after temporal processing)

## Design Patterns

### Current Pattern: Script-Based Pipeline
- Sequential execution
- Global variables (isub)
- Hardcoded paths via Datapath_DEV.m
- Inline visualization

### Target Pattern: Function-Based Pipeline
- Input parameter-based execution
- Local variables only
- Flexible path specification
- Separated concerns (preprocessing vs. visualization)

## Alternative Preprocessing Pipeline
The code includes a commented alternative pipeline featuring:
- LocalThreshold step (sliding window outlier removal)
- Different processing order
- Z-score normalization (instead of percent change)
- Saved to different location ('Functional' subfolder)

This suggests ongoing experimentation with preprocessing approaches.
