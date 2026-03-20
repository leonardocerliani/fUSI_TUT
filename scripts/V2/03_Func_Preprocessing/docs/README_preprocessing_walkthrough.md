# fUSI Data Preprocessing - Code Walkthrough

## Overview

The `do_preprocessing.m` function converts reconstructed fUSI data (PDI.mat) into analysis-ready format through brain masking, motion correction, outlier rejection, signal normalization, temporal filtering, and spatial smoothing.

```matlab
do_preprocessing(anatPath, funcPath, atlasPath)
```

🔧 **For in-depth technical details and implementation specifics, see:**  
[Technical Documentation](FUNC_PREPROCESSING_TECH_DOCUMENT.md)

---

## 1. Handle Input Arguments

**→ [See technical details: Handle Input Arguments](FUNC_PREPROCESSING_TECH_DOCUMENT.md#1-handle-input-arguments)**

```matlab
%% Step 1: Get data paths
if nargin < 1 || isempty(anatPath)
    anatPath = [];
end
if nargin < 2 || isempty(funcPath)
    funcPath = [];
end
if nargin < 3 || isempty(atlasPath)
    atlasPath = [];
end
```

If no paths are provided, opens interactive dialog to select directories. This enables both scripted batch processing and exploratory interactive use.

**Three usage modes:**
```matlab
% Mode 1: Interactive - prompts for all paths
do_preprocessing()

% Mode 2: Provide all paths directly
do_preprocessing(anatPath, funcPath, atlasPath)

% Mode 3: Mixed - provide some paths, prompt for others
do_preprocessing(anatPath, funcPath)  % Will prompt for atlas
```

**What gets selected:**
1. **Anatomical directory**: Contains anatomic.mat and Transformation.mat
2. **Functional directory**: Contains PDI.mat to preprocess
3. **Atlas directory**: Contains allen_brain_atlas.mat

---

## 2. Load All Required Data

**→ [See technical details: Load All Required Data](FUNC_PREPROCESSING_TECH_DOCUMENT.md#2-load-all-required-data)**

**Dependencies:**
```
src/load_anat_and_func.m
```

```matlab
%% Step 2: Load all required data
fprintf('=== Loading Data ===\n');
[PDI, anatomic, Transf, atlas] = load_anat_and_func(anatPath, funcPath, atlasPath);
fprintf('=== Data Loading Complete ===\n\n');
```

### Data Loading Process

The `load_anat_and_func()` function loads four essential data sources:

#### 2.1 Allen Brain Atlas
```matlab
% allen_brain_atlas.mat
atlas (struct)
├── Regions [X × Y × Z uint16]    % Labeled anatomical regions
└── Histology [X × Y × Z uint8]   % Histological reference
```
**Purpose**: Common coordinate system reference for mouse brain anatomy. Each voxel labeled with region ID (0 = outside brain, >0 = brain regions).

#### 2.2 Anatomical Scan
```matlab
% anatomic.mat
anatomic (struct)
├── Data [Y × X × Z double]       % 3D anatomical volume
├── funcSlice [1 × 3 double]      % Functional slice position [X, Y, Z]
├── Scale [1 × 3 double]          % Voxel spacing (mm)
└── Dim [1 × 3 double]            % Array dimensions
```
**Purpose**: Subject-specific anatomical reference. The critical field `funcSlice(3)` specifies which Z-slice corresponds to the functional imaging plane.

#### 2.3 Transformation Matrix
```matlab
% Transformation.mat
Transf (struct)
└── M [4 × 4 double]              % Affine transformation matrix
```
**Purpose**: Spatial alignment between Allen atlas (standard space) and subject anatomy (individual space).

#### 2.4 Functional Data
```matlab
% PDI.mat
PDI (struct)
├── PDI [Y × X × T double]        % Power Doppler Imaging data
├── time [T × 1 double]           % Frame timestamps
├── Dim (struct)                  % Dimension metadata
├── stimInfo [table]              % Experimental events
└── [behavioral data...]          % wheelInfo, gsensorInfo (optional)
```
**Purpose**: Raw functional imaging data from reconstruction pipeline.

**Output:**
```
✓ Allen Brain Atlas loaded
✓ Anatomical scan loaded
✓ Transformation matrix loaded
✓ Functional data loaded: [92 × 128 × 1198] frames
```

---

## 3. Create Brain Mask

**→ [See technical details: Create Brain Mask](FUNC_PREPROCESSING_TECH_DOCUMENT.md#3-create-brain-mask)**

**Dependencies:**
```
src/Atlas2Individual.m
src/visualize_brain_mask.m
```

```matlab
%% Step 3: Create brain mask
fprintf('=== Creating Brain Mask ===\n');

% Transform Allen atlas to subject space
subAtlas = Atlas2Individual(atlas, anatomic, Transf);

% Extract functional slice
subRegions = subAtlas.Region.Data(:,:,anatomic.funcSlice(3));

% Create binary mask (1 = brain, 0 = background)
bmask = double(subRegions > 1);

% Dilate mask to include edge voxels
dilatation_radius = 2;
se = strel('disk', dilatation_radius);
bmask = imdilate(bmask, se);

% Store in PDI structure
PDI.bmask = bmask;

% Visualize for quality control
visualize_brain_mask(subAtlas, bmask, anatomic.funcSlice(3));

fprintf('=== Brain Mask Creation Complete ===\n\n');
```

### Processing Steps

**Step 3.1: Transform Atlas to Subject Space**
- Maps standard Allen atlas to individual subject's coordinate system
- Applies affine transformation from Transformation.mat
- Accounts for different brain sizes and positioning

**Step 3.2: Extract Functional Slice**
- Selects single 2D slice from 3D subject atlas
- Uses `anatomic.funcSlice(3)` to identify correct Z-plane
- Result: 2D array [Y × X] with region labels

**Step 3.3: Create Binary Mask**
- Threshold region labels: `> 1` = brain tissue
- Excludes background (label=0) and uncertain tissue (label=1)
- Conservative approach reduces false positives

**Step 3.4: Morphological Dilation**
- Expands mask by 2-pixel radius
- Includes edge voxels that may contain brain signal
- Accounts for registration uncertainty and hemodynamic spread

**Step 3.5: Quality Control Visualization**
- Displays all anatomical slices with red mask overlay
- Enables visual verification of mask alignment
- User can close figure after inspection

**Output:**
```
Brain mask created (dilation radius = 2)
[Visualization figure appears]
```

---

## 4. Rigid In-Plane Motion Correction

**→ [See technical details: Motion Correction](FUNC_PREPROCESSING_TECH_DOCUMENT.md#4-rigid-in-plane-motion-correction)**

**Dependencies:**
```
src/visualize_motion_correction.m
```

```matlab
%% Step 4: Motion correction
fprintf('=== Performing Motion Correction ===\n');

% Create median reference image
ref = median(PDI.PDI, 3);

% Get dimensions
[nY, nX, nFrames] = size(PDI.PDI);

% Preallocate
cPDI = zeros(nY, nX, nFrames, 'like', PDI.PDI);
motionParams = zeros(nFrames, 2);  % [X-shift, Y-shift]

% Progress bar
h = waitbar(0, 'Performing motion correction...');

% Correct each frame
for k = 1:nFrames
    % Estimate rigid transformation (translation only)
    tform = imregcorr(PDI.PDI(:,:,k), ref, 'translation');
    
    % Apply transformation
    cPDI(:,:,k) = imwarp(PDI.PDI(:,:,k), tform, 'OutputView', imref2d(size(ref)));
    
    % Store motion parameters
    motionParams(k,1) = tform.T(3,1);  % X translation
    motionParams(k,2) = tform.T(3,2);  % Y translation
    
    if mod(k, 100) == 0 || k == nFrames
        waitbar(k/nFrames, h, sprintf('Correcting frame %d of %d', k, nFrames));
    end
end
close(h);

% Calculate statistics
totalMotion = sqrt(motionParams(:,1).^2 + motionParams(:,2).^2);
fprintf('Motion correction complete:\n');
fprintf('  Mean displacement: %.2f pixels\n', mean(totalMotion));
fprintf('  Max displacement: %.2f pixels\n', max(totalMotion));

% Store and visualize
PDI.motionParams = motionParams;
visualize_motion_correction(PDI.time, motionParams);

% Update data
PDI.PDI = cPDI;

fprintf('=== Motion Correction Complete ===\n\n');
```

### Processing Steps

**Step 4.1: Create Median Reference**
- Uses median (not mean) for robustness to outliers
- Represents typical brain anatomy
- Stable reference for frame alignment

**Step 4.2: Estimate Transformations**
- Uses `imregcorr` for cross-correlation-based registration
- Translation-only (rigid, 2 degrees of freedom)
- Sub-pixel precision (~0.1 pixel accuracy)
- Optimal for same-modality alignment (all frames are PDI)

**Step 4.3: Apply Transformations**
- `imwarp` shifts each frame to align with reference
- Bilinear interpolation for sub-pixel accuracy
- Maintains consistent field of view

**Step 4.4: Quality Control**
- Calculates motion statistics (mean, max, std)
- Generates QC plots showing motion over time
- Typical values: mean < 2 pixels, max < 5 pixels

**Why translation-only?**
- Head is physically fixed during imaging
- Rotation/scaling unlikely in fixed-head preparation
- Simple model prevents overfitting

**Output:**
```
Motion correction complete:
  Mean displacement: 1.23 pixels
  Max displacement: 3.45 pixels
[QC figure appears]
```

---

## 5. Voxelwise Outlier Rejection

**→ [See technical details: Outlier Rejection](FUNC_PREPROCESSING_TECH_DOCUMENT.md#5-voxelwise-outlier-rejection)**

**Dependencies:**
```
src/fillmissingTime.m
```

```matlab
%% Step 5: Outlier rejection
fprintf('=== Performing Outlier Rejection ===\n');

% Set threshold to 5 standard deviations
std_threshold = 5;

% Calculate voxelwise z-scores
zG = abs(zscore(PDI.PDI, 0, 3));

% Create outlier mask
maskG = zG > std_threshold;

% Count outliers
numOutliers = sum(maskG(:));
numTotal = numel(PDI.PDI);
outlierRatio = numOutliers / numTotal;

fprintf('Detected %d outliers (%.2f%% of all values)\n', numOutliers, outlierRatio * 100);

% Flag outliers as NaN
PDI.PDI(maskG) = NaN;

% Interpolate NaN values temporally
PDI.PDI = fillmissingTime(PDI.PDI, 'linear');

% Store parameters
PDI.voxelFrameRjection.std = std_threshold;
PDI.voxelFrameRjection.interpMethod = 'linear';
PDI.voxelFrameRjection.ratio = outlierRatio;

fprintf('=== Outlier Rejection Complete ===\n\n');
```

### Processing Steps

**Step 5.1: Calculate Voxelwise Z-scores**
- Each voxel analyzed independently across time
- Z-score = (value - mean) / std
- Absolute values used (outliers can be high or low)

**Step 5.2: Detect Outliers**
- 5-sigma threshold: only extreme artifacts flagged
- Conservative: probability of false positive ≈ 0.00006%
- Typical ratio: 0.1-1% of all values

**Step 5.3: Temporal Interpolation**
- Replaces outliers with linear interpolation from neighbors
- Uses temporal (not spatial) neighbors
- Preserves all frames (no data loss)
- fUSI signals have strong temporal autocorrelation

**Why voxelwise (not frame-based)?**
- Artifacts often affect individual voxels only
- Preserves temporal resolution
- More selective than removing entire frames
- Typical for fUSI: sparse, random outliers

**Output:**
```
Detected 276 outliers (0.23% of all values)
Outlier rejection complete (threshold: 5-sigma, method: linear)
```

---

## 6. Signal Normalization (Percent Signal Change)

**→ [See technical details: Signal Normalization](FUNC_PREPROCESSING_TECH_DOCUMENT.md#6-signal-normalization-percent-signal-change)**

```matlab
%% Step 6: Percent signal change conversion
fprintf('=== Converting to Percent Signal Change ===\n');

% Calculate temporal mean for each voxel
nFrames = size(PDI.PDI, 3);
mu = repmat(mean(PDI.PDI, 3), 1, 1, nFrames);

% Apply PSC formula: PSC(t) = (S(t) - mean) / mean × 100
PDI.PDI = (PDI.PDI - mu) ./ mu .* 100;

fprintf('Signal converted to percent change (baseline = 0%%)\n');
fprintf('=== Percent Signal Change Complete ===\n\n');
```

### Processing Steps

**Step 6.1: Calculate Baseline**
- Temporal mean computed for each voxel independently
- Represents baseline blood flow for that voxel
- Replicated across time for element-wise operations

**Step 6.2: Apply PSC Formula**
```
PSC(t) = (Signal(t) - Mean) / Mean × 100
```

**Why percent signal change?**
- **Removes baseline differences**: Different voxels have different baseline blood flow
- **Interpretable units**: "5% increase" has clear meaning
- **Better for GLM**: More homogeneous variance across brain
- **Standard practice**: Used in fMRI/fUSI analysis

**Alternative (commented out):**
```matlab
% Z-score normalization (for ISC analysis)
% PDI.PDI = zscore(PDI.PDI, 0, 3);
```
Z-score is used for inter-subject correlation (ISC) where temporal patterns matter more than absolute magnitude.

**Output:**
```
Signal converted to percent change (baseline = 0%)
```

---

## 7. Temporal Resampling

**→ [See technical details: Temporal Resampling](FUNC_PREPROCESSING_TECH_DOCUMENT.md#7-temporal-resampling)**

**Dependencies:**
```
src/resamplePDI.m
```

```matlab
%% Step 7: Resample to 5 Hz
fprintf('=== Resampling to 5 Hz ===\n');

resampling_rate = 5;  % Hz
original_rate = 1 / mean(diff(PDI.time));

fprintf('Original sampling rate: %.2f Hz\n', original_rate);
fprintf('Target sampling rate: %d Hz\n', resampling_rate);

% Resample PDI data and time vector
PDI = resamplePDI(PDI, resampling_rate);

fprintf('Data resampled to %d Hz (%d frames)\n', resampling_rate, size(PDI.PDI, 3));
fprintf('=== Resampling Complete ===\n\n');
```

### Processing Steps

**Step 7.1: Create New Time Vector**
```matlab
% Inside resamplePDI.m:
PDI.time = min(PDI.time):1/frequency:max(PDI.time);
```
- Creates regular grid at exactly 5 Hz (0.2s intervals)
- Spans same duration as original data

**Step 7.2: Linear Interpolation**
```matlab
% Inside resamplePDI.m:
PDIres = interp1(oldtime, permute(PDI.PDI,[3,1,2]), PDI.time);
```
- Interpolates signal values at new timepoints
- Linear interpolation between neighbors
- Vectorized across all voxels for efficiency

**Why 5 Hz?**
- **Higher than Nyquist**: fUSI signals < 1 Hz, 5 Hz safely captures them
- **Standard rate**: Common in fMRI/fUSI literature  
- **Not excessive**: Higher rates increase file size unnecessarily
- **Filter compatibility**: Good for DCT-based filtering

**Why resample?**
- **Standardization**: Different sessions may have different frame rates
- **GLM requirement**: Requires uniform sampling intervals
- **Filtering**: DCT and other filters need regular spacing

**Output:**
```
Original sampling rate: 1.80 Hz
Target sampling rate: 5 Hz
Data resampled to 5 Hz (3335 frames)
```

---

## 8. Temporal Highpass Filtering

**→ [See technical details: Temporal Highpass Filtering](FUNC_PREPROCESSING_TECH_DOCUMENT.md#8-temporal-highpass-filtering)**

**Dependencies:**
```
src/DCThighpass.m
```

```matlab
%% Step 8: Temporal highpass filter
fprintf('=== Applying Temporal Highpass Filter ===\n');

cutoff_in_seconds = 500;  % Remove drift with period > 500 seconds
sampling_rate = resampling_rate;

fprintf('Filter parameters:\n');
fprintf('  Cutoff period: %d seconds\n', cutoff_in_seconds);
fprintf('  Sampling rate: %d Hz\n', sampling_rate);

% Apply DCT-based highpass filter
PDI.PDI = DCThighpass(PDI.PDI, sampling_rate, cutoff_in_seconds);

fprintf('Temporal highpass filtering complete\n');
fprintf('=== Highpass Filtering Complete ===\n\n');
```

### Processing Steps

**Step 8.1: Build DCT Basis**
- Creates discrete cosine transform basis functions
- Represents slow drift components (period > cutoff)
- Number of basis functions: K = floor(2 × scan_length / cutoff)

**Step 8.2: Regression and Residuals**
```matlab
% Inside DCThighpass.m:
beta = (C' * C) \ (C' * Y')  % Fit drift to data
Yhp = Y' - C * beta           % Remove drift (residuals)
```
- Like GLM nuisance regression
- Fits drift components to data
- Subtracts fitted drift
- Returns drift-free signal

**Why DCT-based filtering?**
- **No edge artifacts**: Unlike Butterworth filters
- **Interpretable cutoff**: Period in seconds (not just frequency)
- **SPM standard**: Well-validated in neuroimaging
- **Like GLM**: Conceptually similar to nuisance regression

**What does 500s cutoff mean?**
- Removes signals with period **> 500 seconds** (< 0.002 Hz)
- Preserves signals with period **< 500 seconds** (> 0.002 Hz)
- Typical drift: scanner drift, physiological slow changes

**Output:**
```
Filter parameters:
  Cutoff period: 500 seconds
  Sampling rate: 5 Hz
Temporal highpass filtering complete
```

---

## 9. Spatial Smoothing

**→ [See technical details: Spatial Smoothing](FUNC_PREPROCESSING_TECH_DOCUMENT.md#9-spatial-smoothing)**

```matlab
%% Step 9: Spatial smoothing
fprintf('=== Applying Spatial Smoothing ===\n');

spatial_sigma = 1;  % Gaussian kernel width (pixels)
[nY, nX, nFrames] = size(PDI.PDI);

fprintf('Smoothing parameters:\n');
fprintf('  Sigma: %.1f pixels\n', spatial_sigma);
fprintf('  FWHM: %.2f pixels\n', 2.355 * spatial_sigma);
fprintf('  Effective smoothing radius: ~%d pixels\n', ceil(3*spatial_sigma));

% Apply Gaussian filter to each frame
for k = 1:nFrames
    PDI.PDI(:,:,k) = imgaussfilt(PDI.PDI(:,:,k), spatial_sigma);
end

% Store smoothing parameter
PDI.spatialSigma = spatial_sigma;

fprintf('Spatial smoothing complete\n');
fprintf('=== Spatial Smoothing Complete ===\n\n');
```

### Processing Steps

**Step 9.1: Gaussian Kernel Definition**
- Sigma (σ) = 1 pixel controls kernel width
- FWHM = 2.355 × σ ≈ 2.4 pixels (full width at half maximum)
- Effective radius: ~3 pixels (Gaussian extends ~3σ)

**Step 9.2: Frame-by-Frame Smoothing**
- Applies 2D Gaussian filter to each frame independently
- Spatial smoothing only (not temporal)
- Uses `imgaussfilt` for efficient computation

**Why spatial smoothing?**
- **Reduces noise**: Averages random voxel-wise fluctuations
- **Improves SNR**: Signal stands out more clearly
- **Matches hemodynamics**: Blood flow changes spread ~1-2 pixels
- **Standard practice**: Used in fMRI/fUSI preprocessing

**Why σ=1 pixel?**
- Matches hemodynamic point spread function
- Balance between noise reduction and spatial resolution
- Standard in neuroimaging (SPM/FSL default)

**FWHM relationship:**
```
FWHM = 2√(2ln2) × σ ≈ 2.355σ

For σ=1: FWHM ≈ 2.4 pixels
```

**Output:**
```
Smoothing parameters:
  Sigma: 1.0 pixels
  FWHM: 2.35 pixels
  Effective smoothing radius: ~3 pixels
Spatial smoothing complete
```

---

## 10. Save Preprocessed Data

**→ [See technical details: Save Preprocessed Data](FUNC_PREPROCESSING_TECH_DOCUMENT.md#10-save-preprocessed-data)**

**Dependencies:**
```
src/parsave.m
```

```matlab
%% Step 10: Save preprocessed data
fprintf('=== Saving Preprocessed Data ===\n');

output_filename = 'prepPDI.mat';
output_path = fullfile(PDI.savepath, output_filename);

fprintf('Output location: %s\n', output_path);
fprintf('Saving preprocessed data...\n');

% Save using parsave (parallel-safe)
parsave(output_path, PDI);

fprintf('Preprocessed data saved successfully\n');
fprintf('=== Preprocessing Complete ===\n\n');

% Print summary
fprintf('╔════════════════════════════════════════════════════════════════╗\n');
fprintf('║                   PREPROCESSING SUMMARY                        ║\n');
fprintf('╚════════════════════════════════════════════════════════════════╝\n');
fprintf('  Output file: %s\n', output_filename);
fprintf('  Final dimensions: [%d × %d × %d]\n', size(PDI.PDI, 1), size(PDI.PDI, 2), size(PDI.PDI, 3));
fprintf('  Sampling rate: 5 Hz\n');
fprintf('  Processing steps completed: 10/10\n');
fprintf('  ✓ Brain masking\n');
fprintf('  ✓ Motion correction\n');
fprintf('  ✓ Outlier rejection\n');
fprintf('  ✓ Signal normalization (PSC)\n');
fprintf('  ✓ Temporal resampling\n');
fprintf('  ✓ Highpass filtering\n');
fprintf('  ✓ Spatial smoothing\n');
fprintf('  ✓ Data saved\n');
fprintf('\n');
```

### Output Structure

**Filename:** `prepPDI.mat`  
**Location:** Same directory as input PDI.mat

**Complete PDI structure:**
```matlab
PDI (struct)
├── PDI [Y × X × T double]            % Preprocessed data (% signal change)
├── time [T × 1 double]               % Regular timestamps at 5 Hz
├── bmask [Y × X logical]             % Brain mask
├── motionParams [T × 2 double]       % Motion parameters [X,Y translation]
├── voxelFrameRjection (struct)       % Outlier rejection metadata
│   ├── std (5)
│   ├── interpMethod ('linear')
│   └── ratio (e.g., 0.0023)
├── spatialSigma (1)                  % Smoothing parameter
├── Dim (struct)                      % Dimension metadata (preserved)
├── stimInfo [table]                  % Experimental events (preserved)
├── wheelInfo [table]                 % Running wheel (preserved, optional)
├── gsensorInfo [table]               % G-sensor (preserved, optional)
└── savepath                          % Output directory
```

### Data Transformations Summary

**Raw (PDI.mat) → Preprocessed (prepPDI.mat):**
- **Units**: Arbitrary → Percent signal change
- **Sampling**: Variable (~1.8 Hz) → Regular (5 Hz)
- **Motion**: Uncorrected → Rigid translation corrected
- **Outliers**: Present → Interpolated (5-sigma threshold)
- **Drift**: Present → Removed (DCT highpass, 500s cutoff)
- **Noise**: Raw → Smoothed (Gaussian σ=1 pixel)

**Why parsave?**
- Parallel-safe save function
- Enables future batch processing with `parfor`
- Consistent save method across scripts

**Output:**
```
Output location: /path/to/Data_analysis/run-115047-func/prepPDI.mat
Saving preprocessed data...
Preprocessed data saved successfully

╔════════════════════════════════════════════════════════════════╗
║                   PREPROCESSING SUMMARY                        ║
╚════════════════════════════════════════════════════════════════╝
  Output file: prepPDI.mat
  Final dimensions: [92 × 128 × 3335]
  Sampling rate: 5 Hz
  Processing steps completed: 10/10
  ✓ Brain masking
  ✓ Motion correction
  ✓ Outlier rejection
  ✓ Signal normalization (PSC)
  ✓ Temporal resampling
  ✓ Highpass filtering
  ✓ Spatial smoothing
  ✓ Data saved
```

---

## Usage Example

```matlab
% Navigate to preprocessing directory
cd('/path/to/03_Func_Preprocessing')

% Interactive mode (prompts for all paths)
do_preprocessing()

% Provide all paths directly
anatPath = 'sample_data/Data_analysis/run-113409-anat';
funcPath = 'sample_data/Data_analysis/run-115047-func';
atlasPath = '/path/to/atlas';
do_preprocessing(anatPath, funcPath, atlasPath)
```

---

## Key Design Principles

1. **Flexible input**: Interactive or scripted execution
2. **Single-subject processing**: No subject indexing, parallel-ready
3. **Modular architecture**: Helper functions in src/ directory
4. **Quality control**: Automatic visualizations for mask and motion
5. **Self-documenting**: All parameters saved in output
6. **Progress feedback**: Clear console messages throughout
7. **Non-destructive**: Mask stored separately, can be applied later

---

## Processing Time

**Typical processing time** (single subject):
- Brain masking: ~5-10 seconds
- Motion correction: ~2-5 minutes (1000-2000 frames)
- Other steps: ~1-2 minutes
- **Total**: ~5-10 minutes per subject

---

## Quality Control Checkpoints

### 1. Brain Mask Visualization (Step 3)
- **Check**: Mask should cover brain tissue, exclude background
- **Red overlay** on functional slice shows masked region
- **Warning signs**: Mask only covers half brain, includes large non-brain area

### 2. Motion Parameters (Step 4)
- **Check**: Mean < 2 pixels, Max < 5 pixels
- **Plots**: X translation, Y translation, total displacement
- **Warning signs**: Large spikes (>10 pixels), excessive drift (>5 pixels mean)

### 3. Outlier Ratio (Step 5)
- **Check**: Ratio < 1-2%
- **Typical**: 0.1-0.5% for good data
- **Warning signs**: Ratio > 2% indicates data quality issues

---

## See Also

- **[User Guide](../README_FUNC_PREPROCESSING.md)**: Overview and usage examples
- **[Technical Documentation](FUNC_PREPROCESSING_TECH_DOCUMENT.md)**: In-depth implementation details
- **Helper functions**: src/ directory contains 7 modular functions
