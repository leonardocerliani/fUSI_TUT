# do_preprocessing.m - Technical Documentation

## Table of Contents

### Overview & Setup
- [Overview](#overview)
- [Dependencies](#dependencies)
- [Expected Input Structure](#expected-input-structure)
- [Output Structure](#output-structure)

### Processing Steps
- [1. Handle Input Arguments](#1-handle-input-arguments)
  - [Flexible Path Input](#flexible-path-input)
  - [Interactive Mode (uigetdir)](#interactive-mode-uigetdir)
  - [Direct Path Mode](#direct-path-mode)
- [2. Load All Required Data](#2-load-all-required-data)
  - [Data Loading Architecture](#data-loading-architecture)
  - [Allen Brain Atlas](#allen-brain-atlas)
  - [Anatomical Scan Data](#anatomical-scan-data)
  - [Functional Scan Data](#functional-scan-data)
  - [Transformation Matrix](#transformation-matrix)
- [3. Create Brain Mask](#3-create-brain-mask)
  - [Transform Atlas to Subject Space](#3a-transform-atlas-to-subject-space)
  - [Extract Functional Slice](#3b-extract-functional-slice)
  - [Create Binary Mask](#3c-create-binary-mask)
  - [Morphological Dilation](#3d-morphological-dilation)
  - [Store Mask in PDI Structure](#3e-store-mask-in-pdi-structure)
  - [Visualize Mask Overlay](#3f-visualize-mask-overlay)
- [4. Rigid In-Plane Motion Correction](#4-rigid-in-plane-motion-correction)
  - [Create Median Reference Image](#4a-create-median-reference-image)
  - [Estimate Frame-by-Frame Transformations](#4b-estimate-frame-by-frame-transformations)
  - [Apply Transformations](#4c-apply-transformations)
  - [Store Motion Parameters](#4d-store-motion-parameters)
  - [Motion Statistics](#4e-motion-statistics)
  - [Visualize Motion Parameters](#4f-visualize-motion-parameters)
- [5. Voxelwise Outlier Rejection](#5-voxelwise-outlier-rejection)
  - [Calculate Voxelwise Z-scores](#5a-calculate-voxelwise-z-scores)
  - [Create Outlier Mask](#5b-create-outlier-mask)
  - [Flag Outliers as NaN](#5c-flag-outliers-as-nan)
  - [Temporal Interpolation](#5d-temporal-interpolation)
  - [Store Rejection Parameters](#5e-store-rejection-parameters)
- [6. Signal Normalization (Percent Signal Change)](#6-signal-normalization-percent-signal-change)
  - [Calculate Temporal Mean](#6a-calculate-temporal-mean)
  - [Apply PSC Formula](#6b-apply-psc-formula)
  - [Alternative: Z-score Normalization](#6c-alternative-z-score-normalization)
- [7. Temporal Resampling](#7-temporal-resampling)
  - [Create New Time Vector](#7a-create-new-time-vector)
  - [Linear Interpolation](#7b-linear-interpolation)
  - [Update Time Stamps](#7c-update-time-stamps)
- [8. Temporal Highpass Filtering](#8-temporal-highpass-filtering)
  - [DCT Basis Construction](#8a-dct-basis-construction)
  - [Regression and Residuals](#8b-regression-and-residuals)
  - [Filter Parameters](#8c-filter-parameters)
- [9. Spatial Smoothing](#9-spatial-smoothing)
  - [Gaussian Kernel](#gaussian-kernel)
  - [Implementation](#implementation)
  - [Why σ=1 Pixel?](#why-σ1-pixel)
  - [Effective Smoothing Radius](#effective-smoothing-radius)
  - [Frame-by-Frame Processing](#frame-by-frame-processing)
- [10. Save Preprocessed Data](#10-save-preprocessed-data)
  - [Output File](#output-file)
  - [File Contents](#file-contents)
  - [Save Function: parsave](#save-function-parsave)
  - [Processing Summary](#processing-summary)
  - [Data Transformations Summary](#data-transformations-summary)
- [Summary](#summary)

---

# Overview

`do_preprocessing.m` is the primary preprocessing function for functional ultrasound imaging (fUSI) data. It converts raw Power Doppler Imaging (PDI) data into analysis-ready format through motion correction, outlier rejection, signal normalization, temporal filtering, and spatial smoothing.

**Purpose**: Prepare functional imaging data for statistical analysis:
- Apply brain mask to exclude non-brain voxels
- Correct for head motion artifacts
- Remove outlier frames and interpolate
- Normalize signal to percent change
- Resample to consistent temporal resolution
- Apply temporal and spatial filtering

**Key Functionality**:
1. Flexible path input (direct arguments or interactive selection)
2. Loads anatomical, functional, and atlas data
3. Creates brain mask from Allen atlas
4. Motion correction (rigid in-plane translation)
5. Outlier detection and interpolation
6. Signal normalization to percent change
7. Temporal resampling and filtering
8. Spatial smoothing
9. Saves preprocessed data

**Key Features**:
- **Flexible input**: Accepts paths as arguments or prompts with uigetdir
- **Modular architecture**: Helper functions in src/ directory
- **No subject indexing**: Single-subject processing (parallel-ready)
- **Enhanced documentation**: Clear comments explaining each step
- **Progress feedback**: Console messages track processing stages

## Dependencies

### Required MATLAB Toolboxes
1. **Image Processing Toolbox**
   - `imwarp` - Image warping with geometric transformations
   - `imref2d`, `imref3d` - Spatial reference objects
   - `affine3d` - Affine transformation objects
   - `imregcorr` - Image registration using correlation
   - `imgaussfilt` - Gaussian filtering
   - `imdilate`, `strel` - Morphological operations

2. **Statistics and Machine Learning Toolbox**
   - `zscore` - Z-score standardization for outlier detection

3. **Base MATLAB**
   - File I/O operations
   - Array manipulation
   - Visualization functions

### Required Data Files
- **allen_brain_atlas.mat**: Allen Brain Atlas reference
- **anatomic.mat**: Subject anatomical scan
- **Transformation.mat**: Atlas-to-subject registration matrix
- **PDI.mat**: Raw functional imaging data

### Custom Helper Functions (src/ directory)
- **load_anat_and_func.m**: Coordinates data loading with path selection
- **Atlas2Individual.m**: Transforms atlas to subject space
- **visualize_brain_mask.m**: Displays mask overlay on anatomical slices
- **resamplePDI.m**: Temporal resampling of PDI data
- **DCThighpass.m**: Discrete cosine transform-based highpass filtering
- **fillmissingTime.m**: Temporal interpolation of NaN values
- **parsave.m**: Parallel-safe save function

## Expected Input Structure

### Directory Organization
```
Data_analysis/
└── [subject]/
    └── [session]/
        ├── run-[time]-anat/           [Anatomical scan]
        │   ├── anatomic.mat           [REQUIRED]
        │   ├── Transformation.mat     [REQUIRED]
        │   ├── anatomic_2_atlas.mat   [optional]
        │   └── anatomic_2_atlas.nii   [optional]
        └── run-[time]-func/           [Functional scan]
            └── PDI.mat                [REQUIRED]
```

### Allen Brain Atlas Location
```
[atlas_directory]/
└── allen_brain_atlas.mat              [REQUIRED]
```

The atlas can be located anywhere - the user specifies the directory containing this file.

### Required File Contents

**1. anatomic.mat** - Subject anatomical scan:
```matlab
anatomic (struct)
├── Data [Y × X × Z double]           % Anatomical volume
├── funcSlice [1 × 3 double]          % Functional slice coordinates [X, Y, Z]
├── Scale [1 × 3 double]              % Voxel spacing [dx, dy, dz] in mm
└── Dim [1 × 3 double]                % Volume dimensions [nX, nY, nZ]
```

**2. Transformation.mat** - Atlas registration:
```matlab
Transf (struct)
└── M [4 × 4 double]                  % Affine transformation matrix
```

**3. PDI.mat** - Raw functional data:
```matlab
PDI (struct)
├── PDI [Y × X × T double]            % Power Doppler Imaging data
├── time [T × 1 double]               % Frame timestamps (seconds)
└── [other fields from reconstruction]
```

**4. allen_brain_atlas.mat** - Reference atlas:
```matlab
atlas (struct)
├── Regions [X × Y × Z uint16]        % Labeled region volume
├── Histology [X × Y × Z uint8]       % Histology volume
└── [additional atlas metadata]
```

## Output Structure

### Preprocessed PDI.mat File
Location: Same directory as input `PDI.mat`, saved as `prepPDI.mat`

```matlab
PDI (struct)
├── PDI [Y × X × T double]            % Preprocessed imaging data
├── time [T × 1 double]               % Aligned frame timestamps
├── bmask [Y × X logical]             % Brain mask
├── voxelFrameRjection (struct)       % Outlier rejection parameters
│   ├── std                           % Z-score threshold (5)
│   ├── interpMethod                  % Interpolation method ('linear')
│   └── ratio                         % Fraction of values rejected
├── spatialSigma                      % Gaussian smoothing parameter (1)
├── Dim (struct)                      % Dimensions maintained from input
└── savepath                          % Output directory path
```

### Processing Transformations

**Raw → Preprocessed transformations**:
1. **Masked**: Brain voxels identified (non-brain optionally zeroed)
2. **Motion corrected**: Rigid in-plane alignment to median reference
3. **Outliers removed**: Z-score > 5 flagged and interpolated
4. **Normalized**: Converted to percent signal change
5. **Resampled**: Temporal resolution set to 5 Hz
6. **Filtered**: Highpass to remove slow drift
7. **Smoothed**: Spatial Gaussian (σ = 1 voxel)

---

# Processing Steps

## 1. Handle Input Arguments

### What Happens
This section manages flexible input handling, allowing the function to be called with explicit path arguments or interactively with uigetdir prompts. This design enables both scripted batch processing and exploratory interactive use.

### Flexible Path Input

**Function signature**:
```matlab
function do_preprocessing(anatPath, funcPath, atlasPath)
```

**All three arguments are optional**:
- If provided: Uses specified paths directly
- If omitted: Opens uigetdir dialog to prompt user
- Mixed mode supported: Can provide some paths, prompt for others

### Interactive Mode (uigetdir)

**When activated**:
- Any argument not provided or empty
- User sees terminal prompt followed by directory selection dialog

**Prompting sequence**:
```
>>> Please select the ANATOMICAL data directory
[uigetdir dialog appears]

>>> Please select the FUNCTIONAL data directory
[uigetdir dialog appears]

>>> Please select the directory containing ALLEN BRAIN ATLAS (allen_brain_atlas.mat)
[uigetdir dialog appears]
```

**Why terminal prompts on macOS**:
- macOS doesn't display uigetdir window titles
- Terminal messages clarify what each dialog is requesting
- Prevents user confusion about which path is being selected

**Cancellation handling**:
- If user clicks "Cancel" on any dialog → Fatal error
- Cannot proceed without required data
- Clear error message indicates which path was cancelled

### Direct Path Mode

**Example usage**:
```matlab
% Provide all paths
do_preprocessing('sample_data/Data_analysis/run-113409-anat', ...
                 'sample_data/Data_analysis/run-115047-func', ...
                 '/path/to/atlas')

% Mix modes (prompt for atlas only)
do_preprocessing('sample_data/Data_analysis/run-113409-anat', ...
                 'sample_data/Data_analysis/run-115047-func')
```

**Path validation**:
- All provided paths validated (directory exists)
- Fatal error if specified path is invalid
- Helps catch typos before processing begins

### Implementation Details

**Argument checking logic**:
```matlab
if nargin < 1
    anatPath = [];
end
if nargin < 2
    funcPath = [];
end
if nargin < 3
    atlasPath = [];
end
```

**Empty array handling**:
- Sets missing arguments to empty (`[]`)
- Helper function (`load_anat_and_func`) interprets empty as "prompt user"
- Enables flexible calling patterns

### Why This Design?

**Benefits of flexible input**:
1. **Batch processing**: Call with paths from script
2. **Interactive exploration**: Run without arguments for manual selection
3. **Partial automation**: Mix scripted and interactive selection
4. **Parallel processing**: Easy to call with different paths in parallel workers
5. **No hardcoded paths**: Unlike old `Datapath_DEV.m` approach

**Comparison to old approach**:

Old version (`Preprocessing_DEV.m`):
```matlab
[subDataPath, subAnatPath, ~] = Datapath_DEV('VisualTest');
isub = 1;
load([subDataPath{isub} filesep 'PDI.mat']);
```

New version (`do_preprocessing.m`):
```matlab
do_preprocessing(anatPath, funcPath, atlasPath);
% OR
do_preprocessing();  % Interactive
```

**Improvements**:
- No hardcoded condition strings ('VisualTest', 'ShockTest')
- No subject indexing (`isub`)
- No need to edit path definition file
- Works with any directory structure

### Console Output

```
=== Loading Data ===

>>> Please select the ANATOMICAL data directory
[Selection: /path/to/Data_analysis/run-113409-anat]

>>> Please select the FUNCTIONAL data directory
[Selection: /path/to/Data_analysis/run-115047-func]

>>> Please select the directory containing ALLEN BRAIN ATLAS (allen_brain_atlas.mat)
[Selection: /path/to/atlas]
```

### Success Criteria

Input handling complete when:
- ✅ All three paths defined (either provided or selected)
- ✅ All paths validated as existing directories
- ✅ Ready to pass paths to data loading function

---

## 2. Load All Required Data

### What Happens
This section loads all data required for preprocessing: anatomical scan, functional scan, transformation matrix, and Allen brain atlas. The loading is centralized in a single helper function that manages path validation, file existence checks, and proper data structure assembly.

### Data Loading Architecture

**Primary function**: `load_anat_and_func(anatPath, funcPath, atlasPath)`

**Returns**:
```matlab
[PDI, anatomic, Transf, atlas] = load_anat_and_func(anatPath, funcPath, atlasPath);
```

**Advantages of centralized loading**:
- Single point of failure detection
- Consistent error messages
- Reusable across different workflows
- Easier to maintain and test

### Allen Brain Atlas

**Purpose**: Common coordinate system reference for mouse brain anatomy

**File**: `allen_brain_atlas.mat` in user-specified directory

**Contents**:
```matlab
atlas (struct)
├── Regions [X × Y × Z uint16]        % Labeled anatomical regions
│                                     % Each voxel labeled with region ID
│                                     % 0 = outside brain, >0 = brain regions
├── Histology [X × Y × Z uint8]       % Histological staining reference
└── [metadata fields]                 % Region names, hierarchy, etc.
```

**What is the Allen Brain Atlas?**
- **Standardized reference**: Common Coordinate Framework (CCF v3)
- **Resolution**: Typically 10-25 μm isotropic voxels
- **Coverage**: Complete adult mouse brain
- **Labels**: 300+ distinct anatomical structures
- **Purpose**: Enables cross-subject, cross-study comparisons

**Why we need it**:
- Defines brain boundaries (region labels > 0)
- Provides anatomical context for functional activations
- Enables region-of-interest (ROI) analysis
- Required for creating brain mask

**Loading process**:
```matlab
atlasFile = fullfile(atlasPath, 'allen_brain_atlas.mat');
load(atlasFile, 'atlas');
```

**Validation**: Fatal error if file not found - cannot proceed without atlas reference

### Anatomical Scan Data

**Purpose**: Subject-specific anatomical reference aligned to functional imaging plane

**File**: `anatomic.mat` in anatomical data directory

**Contents**:
```matlab
anatomic (struct)
├── Data [Y × X × Z double]           % 3D anatomical volume
│                                     % Acquired at higher resolution than fUSI
│                                     % Typically gradient echo or T2 MRI
├── funcSlice [1 × 3 double]          % Functional slice position [X, Y, Z]
│                                     % Critical: Links fUSI plane to 3D anatomy
├── Scale [1 × 3 double]              % Voxel dimensions [dx, dy, dz] in mm
├── Dim [1 × 3 double]                % Array size [nX, nY, nZ]
└── savepath                          % Directory path (set during load)
```

**Critical field: anatomic.funcSlice**

This 3-element vector specifies which slice in the anatomical volume corresponds to the functional imaging plane:
- `funcSlice(1)`: X coordinate (lateral position)
- `funcSlice(2)`: Y coordinate (anterior-posterior)
- `funcSlice(3)`: Z coordinate (dorsal-ventral, **most commonly used**)

**Example**:
```matlab
anatomic.funcSlice = [79, 45, 17];
```
This means the functional imaging was performed at:
- 79th position in X dimension
- 45th position in Y dimension  
- **17th slice in Z dimension** (dorsal-ventral depth)

**Why funcSlice is critical**:
- fUSI acquires a **single 2D slice** through the brain
- Anatomical scan is a **full 3D volume**
- `funcSlice(3)` tells us which Z-plane in 3D volume matches our 2D fUSI data
- Enables extraction of correct atlas slice for masking

**Dimension note**:
There's a known discrepancy - comments in code note that X and Z dimensions in `funcSlice` are half those in the anatomical/atlas volumes. This requires further investigation but doesn't affect Z-slice extraction.

### Functional Scan Data

**Purpose**: Raw Power Doppler Imaging (PDI) data to be preprocessed

**File**: `PDI.mat` in functional data directory

**Contents** (from reconstruction pipeline):
```matlab
PDI (struct)
├── PDI [Y × X × T double]            % Imaging data (already reconstructed)
│                                     % T = number of frames (e.g., 1200)
│                                     % Typical range: 0-100 (arbitrary units)
├── time [T × 1 double]               % Frame timestamps (seconds)
│                                     % Aligned to experiment start (t=0)
├── Dim (struct)                      % Dimensions and spacing
│   ├── nx, nz                        % Spatial dimensions (pixels)
│   ├── dx, dz                        % Pixel spacing (mm)
│   ├── nt                            % Number of time points
│   └── dt                            % Frame interval (seconds)
├── stimInfo [table]                  % Experimental events (from reconstruction)
├── wheelInfo [table]                 % Running wheel (optional)
├── gsensorInfo [table]               % Head motion (optional)
└── savepath                          % Directory path (updated during load)
```

**Data characteristics**:
- **Spatial resolution**: Typically 0.05-0.1 mm per pixel
- **Temporal resolution**: 0.5-2 Hz (functional imaging range)
- **Signal**: Blood flow changes (Power Doppler)
- **Baseline**: Non-zero (tissue background signal)
- **Dynamic range**: Small changes (±5-20%) on large baseline

**Loading note**: The entire PDI structure is loaded, preserving all metadata from the reconstruction pipeline.

### Transformation Matrix

**Purpose**: Defines spatial alignment between Allen atlas and subject anatomy

**File**: `Transformation.mat` in anatomical data directory

**Contents**:
```matlab
Transf (struct)
└── M [4 × 4 double]                  % Affine transformation matrix
```

**What is an affine transformation?**

A 4×4 matrix encoding:
- **Translation**: Shifting origin (X, Y, Z offsets)
- **Rotation**: Angular alignment (around 3 axes)
- **Scaling**: Size differences (different image resolutions)
- **Shear**: Shape adjustments (rare, usually minimal)

**Example matrix structure**:
```
[Rx  Ry  Rz  Tx]
[Rx  Ry  Rz  Ty]
[Rx  Ry  Rz  Tz]
[0   0   0   1 ]

Where:
  R = Rotation/scaling components
  T = Translation components
```

**Why we need it**:
- Atlas is in **standard space** (stereotaxic coordinates)
- Subject anatomy is in **individual space** (acquisition coordinates)
- Transformation maps atlas → subject to account for:
  - Different brain sizes
  - Different positioning during imaging
  - Different orientations

**How it's created**:
- Generated during anatomical preprocessing (separate pipeline)
- Uses image registration algorithms (e.g., ANTs, FSL, SPM)
- Optimizes alignment between subject anatomy and atlas
- Stored once, reused for all functional sessions

### Loading Process Flow

**Sequential loading**:
1. **Atlas**: Needed first (reference for all subjects)
2. **Anatomical**: Subject-specific reference
3. **Transformation**: Links atlas to subject
4. **Functional**: Data to be processed

**Validation at each step**:
- Directory existence checked
- File existence verified
- Loading errors caught with clear messages
- savepath fields updated in structures

### Console Output

```
=== Loading Data ===

>>> Please select the ANATOMICAL data directory
>>> Please select the FUNCTIONAL data directory
>>> Please select the directory containing ALLEN BRAIN ATLAS (allen_brain_atlas.mat)

Loading Allen Brain Atlas from: /path/to/atlas
Loading anatomical data from: /path/to/run-113409-anat
Loading functional data from: /path/to/run-115047-func
Data loading complete.

=== Data Loading Complete ===
```

### Success Criteria

All data successfully loaded when:
- ✅ Allen atlas structure loaded with Regions and Histology fields
- ✅ Anatomical structure loaded with Data, funcSlice, Scale, Dim
- ✅ Transformation matrix (4×4) loaded
- ✅ PDI structure loaded with imaging data and timestamps
- ✅ All savepath fields properly set
- ✅ Ready for brain mask creation

---

## 3. Create Brain Mask

### What Happens

This section creates a binary mask identifying brain tissue voxels in the functional imaging plane. The mask excludes non-brain regions (background, skull, tissue outside cranium) to focus analysis on brain activity. This is accomplished by transforming the Allen atlas to subject space and extracting region labels for the functional slice.

### Why Brain Masking is Critical

**Problem**: Functional ultrasound signal exists everywhere in the image
- Background noise outside the brain
- Tissue signals from skull, skin, muscle
- Edge artifacts at brain boundaries
- Non-biological signals

**Solution**: Use anatomical atlas to identify true brain tissue
- Atlas defines brain boundaries precisely
- Subject-specific transformation accounts for individual anatomy
- Binary mask enables selective analysis

**Benefits**:
- **Improved statistics**: Exclude non-brain voxels from analysis
- **Reduced computation**: Process only relevant voxels
- **Cleaner visualizations**: Display only brain regions
- **Better sensitivity**: Focus on signal, ignore noise

### Processing Pipeline Overview

```
Allen Atlas (standard space)
         ↓
[Transform to subject space]
         ↓
Subject Atlas (individual space)
         ↓
[Extract functional slice]
         ↓
Region Labels (2D slice)
         ↓
[Create binary mask]
         ↓
Brain Mask (1 = brain, 0 = outside)
         ↓
[Morphological dilation]
         ↓
Final Mask (with edge padding)
```

### 3a. Transform Atlas to Subject Space

**Purpose**: Map standard Allen atlas to individual subject's anatomical coordinate system

**Function call**:
```matlab
subAtlas = Atlas2Individual(atlas, anatomic, Transf);
```

**What this function does**:

**Step 1: Linear interpolation**
- Resamples atlas to match anatomical image grid
- Ensures atlas and anatomy have same voxel dimensions
- Prepares for affine transformation

**Step 2: Affine transformation**
- Creates `affine3d` object from transformation matrix
- Inverts transformation (atlas → subject direction)
- Applies to both region labels and histology volumes
- Uses 'nearest' interpolation (preserves integer labels)

**Step 3: Optional nonlinear deformation**
- If displacement field available, applies fine-grained warping
- Accounts for local shape variations
- Typically not used for functional imaging (rigid anatomy assumption)

**Output structure**:
```matlab
subAtlas (struct)
├── Region (struct)
│   └── Data [Y × X × Z uint16]      % Region labels in subject space
└── Histology (struct)
    └── Data [Y × X × Z uint8]       % Histology in subject space
```

**Technical note: interpolate3D bug fix**

The `Atlas2Individual` function previously had a bug:
```matlab
% OLD (incorrect):
subAtlas.Region = interpolate3D(anatomic, anatomicInterp, 'nearest');

% NEW (correct):
subAtlas.Region = interpolate3D(anatomic, anatomicInterp);
```

**Why the bug occurred**:
- `interpolate3D` is a custom function (not built-in MATLAB)
- Only accepts 2 arguments (source, target)
- Already implements nearest-neighbor interpolation by default
- Someone confused it with MATLAB's `interp3` which takes method argument

**Impact of fix**:
- Function now runs without error
- Behavior unchanged (already used nearest-neighbor)
- Code is cleaner and more maintainable

### 3b. Extract Functional Slice

**Purpose**: Select the single 2D slice from 3D subject atlas that corresponds to functional imaging plane

**Slice extraction**:
```matlab
subRegions = subAtlas.Region.Data(:,:,anatomic.funcSlice(3));
```

**Coordinate system**:
- `:` (all rows) = Y dimension (anterior-posterior extent)
- `:` (all columns) = X dimension (lateral extent)
- `anatomic.funcSlice(3)` = Z dimension (dorsal-ventral depth)

**Result**: 2D array `[Y × X]` containing region labels at functional slice

**Region label interpretation**:
```
Label = 0:    Outside brain (background)
Label = 1:    Often used for unlabeled/uncertain tissue
Label > 1:    Specific brain regions (cortex, thalamus, etc.)
```

**Example extracted slice**:
```
subRegions(100, 50) = 315    → Primary visual cortex
subRegions(100, 80) = 549    → Hippocampus CA1
subRegions(50, 60) = 0       → Outside brain
```

### 3c. Create Binary Mask

**Purpose**: Convert region labels to binary classification (brain vs non-brain)

**Thresholding operation**:
```matlab
bmask = double(subRegions > 1);
```

**Logic**:
- `subRegions > 1`: Creates logical array (true/false)
- `double()`: Converts to numerical array (1.0/0.0)
- **Threshold = 1**: Excludes both background (0) and uncertain tissue (1)

**Conservative thresholding**:
- Uses `> 1` instead of `> 0` or `≥ 1`
- Excludes ambiguous voxels at brain boundaries
- Reduces false positives (non-brain labeled as brain)
- Slight reduction in coverage acceptable for cleaner mask

**Result**: Binary mask `[Y × X]` where:
- `bmask = 1`: Confident brain tissue
- `bmask = 0`: Non-brain (background or uncertain)

**Typical statistics**:
- Total voxels: ~10,000-15,000 (100×100 to 120×120 typical)
- Brain voxels: ~3,000-5,000 (30-40% of image)
- Non-brain: ~7,000-10,000 (background, edges)

### 3d. Morphological Dilation

**Purpose**: Expand mask slightly to include edge voxels that may contain brain signal

**Dilation operation**:
```matlab
dilatation_radius = 2;
se = strel('disk', dilatation_radius);
bmask = imdilate(bmask, se);
```

**What is morphological dilation?**

Image processing operation that **expands** regions:
- For each 1 (brain) voxel, sets neighboring voxels to 1
- Neighborhood defined by **structuring element** (SE)
- Disk SE with radius 2 = circular neighborhood, 2-pixel radius

**Structuring element visualization**:
```
radius = 2 disk:
     0 1 1 1 0
     1 1 1 1 1
     1 1 1 1 1
     1 1 1 1 1
     0 1 1 1 0
```

**Effect of dilation**:

Before dilation:
```
0 0 0 0 0 0
0 1 1 1 0 0
0 1 1 1 0 0
0 1 1 1 0 0
0 0 0 0 0 0
```

After dilation (radius=2):
```
1 1 1 1 1 0
1 1 1 1 1 1
1 1 1 1 1 1
1 1 1 1 1 1
1 1 1 1 1 0
```

**Why dilate?**

**1. Edge preservation**: Atlas boundary may be slightly conservative
- Registration uncertainty at brain edges
- Atlas might exclude thin cortical regions
- Blood vessels often extend to brain surface

**2. Functional signal characteristics**:
- Hemodynamic response extends slightly beyond tissue boundaries
- Point spread function of ultrasound imaging
- Want to capture peri-brain vasculature

**3. Conservative vs aggressive masking**:
- `radius = 0`: Most conservative, may miss edge activity
- `radius = 2`: Balanced, includes edge with minimal false positives
- `radius = 5`: Aggressive, includes significant non-brain tissue

**Typical outcome**:
- Adds ~200-500 voxels to mask (5-10% increase)
- Primarily at cortical surfaces and ventricle boundaries
- Minimal inclusion of truly non-brain tissue

### 3e. Store Mask in PDI Structure

**Purpose**: Add brain mask to PDI structure for use in analysis

**Storage**:
```matlab
PDI.bmask = bmask;
```

**Why store in PDI structure?**
- Self-contained: Mask travels with data
- Convenient access: Analysis scripts can use `PDI.bmask` directly
- Reproducible: Same mask used across different analyses
- Metadata: Documents which voxels were included

**Optional immediate masking**:
```matlab
% Optional: Apply mask to functional data to zero out non-brain voxels
% This is commented out to preserve full data; mask can be applied during analysis
% PDI.PDI = bsxfun(@times, PDI.PDI, bmask);
```

**Why this line is commented**:

**Preserving full data**:
- Keeps all voxels in data array
- Mask stored separately as `PDI.bmask`
- Analyst can choose when/if to apply mask
- Enables different masking strategies in different analyses

**If uncommented, would do**:
- Multiply each frame by mask
- Set non-brain voxels to zero
- Permanent modification of data array
- Cannot recover non-brain values later

**Best practice**: Store mask, apply during analysis
- More flexible
- Allows multiple masking strategies
- Can visualize full FOV vs masked
- Non-destructive workflow

### 3f. Visualize Mask Overlay

**Purpose**: Quality control visualization showing mask alignment with anatomy

**Visualization function**:
```matlab
visualize_brain_mask(subAtlas, bmask, anatomic.funcSlice(3));
```

**What this displays**:

**Figure layout**: 5 rows × 4 columns = 20 slices
- Shows all dorsal-ventral slices in subject atlas
- Grayscale: Anatomical regions
- Red overlay: Brain mask (only on functional slice)
- Semi-transparent red (alpha = 0.3)

**Purpose of multi-slice display**:
1. **Context**: See where functional slice is located in full brain
2. **Quality control**: Verify mask makes anatomical sense
3. **Slice identification**: Confirm `funcSlice(3)` is correct slice
4. **Spatial orientation**: Understand anterior-posterior, lateral extent

**Example interpretation**:

If red overlay appears on slice 17:
- ✅ Mask covers cortex, hippocampus, thalamus
- ✅ Mask excludes ventricles (mostly)
- ✅ Mask boundary follows brain contour
- ✅ No gross misalignment visible

If something looks wrong:
- ❌ Mask only covers half the brain → Registration issue
- ❌ Red on wrong slice number → `funcSlice` incorrect
- ❌ Mask includes large non-brain region → Threshold too low
- ❌ Mask misses obvious brain tissue → Threshold too high

**Closing the figure**: User can close manually after visual inspection

### Processing Parameters Summary

**Configurable parameters**:
```matlab
dilatation_radius = 2;           % Mask expansion (pixels)
threshold = 1;                   % Region label threshold (> 1 = brain)
```

**Hardcoded but well-chosen**:
- Both values represent reasonable defaults for fUSI
- Can be modified at top of section if needed
- Future enhancement: Make configurable via options structure

### Console Output

```
=== Creating Brain Mask ===
Brain mask created (dilation radius = 2)

[Visualization figure appears]

=== Brain Mask Creation Complete ===
```

### Success Criteria

Brain mask successfully created when:
- ✅ Atlas transformed to subject space
- ✅ Functional slice extracted (2D from 3D volume)
- ✅ Binary mask created with appropriate threshold
- ✅ Mask dilated to include edge voxels
- ✅ Mask stored in PDI structure
- ✅ Visualization displayed for quality control
- ✅ Mask covers brain tissue, excludes background
- ✅ Ready for motion correction

---

## 4. Rigid In-Plane Motion Correction

### What Happens

This section corrects for small head movements during functional imaging acquisition. Even with head fixation, small translations occur due to breathing, muscle relaxation, or ultrasound probe micro-movements. Motion correction aligns all frames to a common reference, ensuring that the same brain region appears at the same pixel location across time.

### Why Motion Correction is Critical

**Problem**: Head motion during acquisition
- Small translations (typically 0.5-3 pixels)
- Breathing-related motion
- Gradual drift over session
- Random micro-movements

**Impact without correction**:
- Apparent signal changes due to anatomy shifting
- Reduced statistical power (motion adds noise)
- Blurred spatial patterns
- False activations at edges

**Solution**: Rigid registration to reference
- Align each frame to common reference
- Remove motion-induced signal changes
- Improve spatial specificity
- Better statistical sensitivity

### Processing Pipeline Overview

```
All frames → Median reference
     ↓
For each frame:
  → Estimate translation (imregcorr)
  → Apply transformation (imwarp)
  → Store motion parameters
     ↓
Motion-corrected data + Motion QC plots
```

### 4a. Create Median Reference Image

**Purpose**: Establish stable reference for frame alignment

**Code**:
```matlab
ref = median(PDI.PDI, 3);
```

**Why median, not mean?**

| Metric | Advantages | Disadvantages |
|--------|------------|---------------|
| **Median** | ✅ Robust to outliers<br>✅ Not biased by artifacts<br>✅ Representative of typical anatomy | Slightly more computation |
| **Mean** | Faster computation | ❌ Sensitive to outliers<br>❌ Biased by bad frames |
| **Single frame** | No computation | ❌ May be atypical<br>❌ Subject to noise |

**Properties of good reference**:
- Represents typical brain anatomy
- High signal-to-noise ratio (averaging effect)
- Not biased toward any particular motion state
- Captures all brain structures consistently

### 4b. Estimate Frame-by-Frame Transformations

**Purpose**: Find optimal translation to align each frame with reference

**Function used**: `imregcorr`

```matlab
tform = imregcorr(PDI.PDI(:,:,k), ref, 'translation');
```

**What imregcorr does**:

**Step 1: Normalized cross-correlation**
- Slides moving image over reference at different offsets
- Calculates correlation at each offset
- Uses FFT for computational efficiency

**Formula**:
```
NCC = Σ[(I₁ - μ₁)(I₂ - μ₂)] / √[Σ(I₁ - μ₁)² · Σ(I₂ - μ₂)²]

Where:
  I₁, I₂ = pixel intensities
  μ₁, μ₂ = mean intensities
  NCC ∈ [-1, 1]
```

**Step 2: Find maximum correlation**
- Offset with highest NCC = best alignment
- Sub-pixel precision via interpolation (~0.1 pixel accuracy)

**Step 3: Return transformation object**
- `tform` is an `affine2d` object
- Contains 3×3 transformation matrix:
```matlab
tform.T = [1    0    0  ]
          [0    1    0  ]
          [Tx   Ty   1  ]
```
- `Tx` = X translation (pixels)
- `Ty` = Y translation (pixels)
- Diagonal 1's = no scaling/rotation (pure translation)

### Why Cross-Correlation for fUSI?

**Optimal for same-modality alignment**:
- ✅ All frames are PDI images (same modality)
- ✅ Assumes linear intensity relationship (valid here)
- ✅ Invariant to global brightness/contrast changes
- ✅ Focuses on spatial patterns, not absolute values

**Fast computation**:
- FFT-based implementation
- Typical frame: 50-100ms processing time
- Critical for 1000+ frames

**Industry standard**:
- Used in SPM, FSL, AFNI (neuroimaging packages)
- Well-tested and robust
- No parameter tuning needed

**Alternative metrics (not used)**:
- Mean squares: Faster but sensitive to intensity changes
- Mutual information: Better for multi-modal, overkill here
- imregtform/imregister: More flexible but slower

### 4c. Apply Transformations

**Purpose**: Shift each frame according to estimated translation

**Function used**: `imwarp`

```matlab
cPDI(:,:,k) = imwarp(PDI.PDI(:,:,k), tform, 'OutputView', imref2d(size(ref)));
```

**What imwarp does**:

**Step 1: Inverse mapping**
- For each pixel in output: find corresponding location in input
- Location = output_coord - [Tx, Ty]

**Step 2: Interpolation**
- Input locations rarely align with pixel centers
- Interpolate values from surrounding pixels
- Uses bilinear interpolation by default
- Achieves sub-pixel accuracy

**Step 3: Handle boundaries**
- Regions that shift out of view filled with 0
- Small translations: minimal boundary artifacts
- Typical motion (1-3 pixels): negligible data loss

**The OutputView parameter**:
```matlab
imref2d(size(ref))
```
- **Critical**: Ensures output has same size/coordinates as reference
- Prevents output from changing dimensions
- Maintains consistent field of view

**Example transformation**:
```
Frame shifted 2.3 pixels right, 1.7 pixels down

Before:        After:
●●●○○○        ○○●●●○
●●●○○○   →    ○○●●●○
●●●○○○        ○○●●●○
```

### 4d. Store Motion Parameters

**Purpose**: Save translation estimates for quality control and analysis

**Extraction from tform**:
```matlab
motionParams(k,1) = tform.T(3,1);  % X translation
motionParams(k,2) = tform.T(3,2);  % Y translation
```

**Storage format**:
```matlab
motionParams [nFrames × 2 double]
  Column 1: X translation (pixels, + = right, - = left)
  Column 2: Y translation (pixels, + = down, - = up)
```

**Why store motion parameters?**

**1. Quality control**:
- Visualize motion over time
- Detect excessive motion (>5 pixels problematic)
- Identify sudden jumps (animal movement)

**2. Correlation with behavior**:
- Does motion correlate with running?
- Does stimulation cause movement?
- Movement artifacts identification

**3. Documentation**:
- Reproducibility (motion characteristics)
- Method validation (correction was necessary)
- Publication figures (report statistics)

**4. Advanced analysis**:
- Regress motion out of signal
- Exclude high-motion frames
- Study motion patterns

### 4e. Motion Statistics

**Calculate total displacement**:
```matlab
totalMotion = sqrt(motionParams(:,1).^2 + motionParams(:,2).^2);
```

**Reported metrics**:
- **Mean displacement**: Average motion magnitude across session
- **Max displacement**: Largest single-frame motion
- **Std displacement**: Motion variability

**Typical values for good experiment**:
```
Mean: 0.5-2.0 pixels
Max:  1.0-4.0 pixels
Std:  0.3-1.0 pixels
```

**Concerning values**:
```
Mean: >3 pixels    → General instability
Max:  >10 pixels   → Sudden movement events
Std:  >2 pixels    → Highly variable motion
```

### 4f. Visualize Motion Parameters

**Visualization function**:
```matlab
visualize_motion_correction(PDI.time, motionParams);
```

**What this displays**:

**Plot 1: Horizontal Motion (X translation)**
- Time vs X displacement
- Identifies left-right drift
- Typical pattern: slow drift or oscillations

**Plot 2: Vertical Motion (Y translation)**
- Time vs Y displacement  
- Identifies dorsal-ventral drift
- May correlate with breathing

**Plot 3: Total Motion Magnitude**
- Time vs total displacement
- Shows overall stability
- Green dashed line = mean
- Easy identification of motion spikes

**Summary statistics box**:
- Mean, max, std displacement
- Quick assessment of data quality

**Interpretation examples**:

**Good session**:
```
Smooth curves, gradual drifts
No sudden jumps
Mean < 2 pixels
```

**Problematic session**:
```
Large spikes (animal movement)
Excessive drift (>5 pixels)
May need frame exclusion
```

### Translation-Only Registration

**Why only translation?**

**Appropriate for fUSI because**:
1. **Head is fixed**: Physical restraint during imaging
2. **Short timescales**: Minutes to hour sessions
3. **Rigid anatomy**: Brain doesn't deform significantly
4. **Prevents overfitting**: Simple model = robust

**What about rotation/scaling?**
- Rotation: Minimal in fixed-head preparation
- Scaling: Would indicate probe movement (rare)
- More parameters = risk of overfitting noise

**Limitations acknowledged**:
- Won't correct through-plane motion
- Won't correct brain deformation
- Won't correct non-rigid motion

### Processing Parameters

**Hardcoded (well-chosen)**:
```matlab
transformtype = 'translation'    % Rigid translation only
metric = 'correlation'           % Built into imregcorr
reference = median(PDI.PDI, 3)   % Median of all frames
```

**Progress monitoring**:
```matlab
waitbar updates every 100 frames  % Balance between feedback and speed
```

### Console Output

```
=== Performing Motion Correction ===

[Waitbar showing progress: "Correcting frame 1198 of 1198"]

Motion correction complete:
  Mean displacement: 1.23 pixels
  Max displacement: 3.45 pixels
  Std displacement: 0.67 pixels

[QC figure appears]

=== Motion Correction Complete ===
```

### Success Criteria

Motion correction successfully applied when:
- ✅ Reference image created from median
- ✅ Translation estimated for each frame
- ✅ All frames aligned to reference
- ✅ Motion parameters stored in PDI.motionParams
- ✅ Statistics computed and displayed
- ✅ QC visualization generated
- ✅ Typical motion ranges observed
- ✅ PDI.PDI updated with corrected data
- ✅ Ready for outlier rejection

---

## 5. Voxelwise Outlier Rejection

### What Happens

This section detects and removes extreme outlier values in individual voxel timeseries through z-score thresholding followed by temporal interpolation. Unlike frame-based rejection (which would remove entire timepoints), this voxelwise approach preserves temporal resolution while removing brief artifacts like electrical spikes or ultrasound glitches.

### Why Outlier Rejection is Critical

**Problem**: Brief artifacts in functional data
- Electrical interference spikes
- Ultrasound transducer glitches
- Random noise bursts
- Scanner artifacts

**Impact without correction**:
- Extreme values bias statistics
- False positive activations
- Reduced sensitivity to true signals
- Poor model fits in analysis

**Solution**: Voxelwise detection and temporal interpolation
- Each voxel analyzed independently
- Conservative threshold (5-sigma)
- Temporal autocorrelation enables interpolation
- Preserves all frames (no data loss)

### Processing Pipeline Overview

```
Motion-corrected data [Y × X × T]
         ↓
For each voxel:
  → Calculate z-score across time
  → Flag |z| > 5 as outlier
         ↓
Replace outliers with NaN
         ↓
Temporal interpolation
         ↓
Clean data + outlier statistics
```

### 5a. Calculate Voxelwise Z-scores

**Purpose**: Standardize each voxel's timeseries to detect extreme deviations

**Code**:
```matlab
zG = abs(zscore(PDI.PDI, 0, 3));
```

**What zscore does**:

**For each voxel independently**:
```
z-score = (value - mean) / std
```

**Parameters explained**:
- `0` flag: Use population std (divide by N, not N-1)
- `3` dimension: Compute along time dimension
- `abs()`: Take absolute value (outliers can be high or low)

**Example for one voxel**:
```matlab
Voxel (50,60) raw values:    [10.2, 10.5, 25.3, 10.9, 11.1, ...]
Mean: 11.0, Std: 1.5

Z-scores:                    [−0.53, −0.33, 9.53, −0.07, 0.07, ...]
Absolute z-scores:           [0.53,  0.33,  9.53, 0.07,  0.07, ...]
                                             ↑
                                      Outlier (>5)
```

**Result**: `zG` has same size as `PDI.PDI` [Y × X × T], each value is an absolute z-score

**Why voxelwise (not global)**:
- Different brain regions have different signal magnitudes
- Voxel-specific normalization accounts for local characteristics
- One region's outlier might be another's normal signal

### 5b. Create Outlier Mask

**Purpose**: Flag voxel-timepoints with extreme z-scores

**Code**:
```matlab
maskG = zG > std_threshold;  % threshold = 5
```

**What this creates**:
- Logical array same size as data [Y × X × T]
- `true` where |z-score| > 5
- `false` everywhere else

**Why 5-sigma threshold?**

| Threshold | Probability | Interpretation |
|-----------|-------------|----------------|
| 2-sigma | 4.6% | Too sensitive - normal variability |
| 3-sigma | 0.3% | Still catches some normal variation |
| **5-sigma** | **0.00006%** | **Only extreme artifacts** |
| 10-sigma | Negligible | May miss real artifacts |

**5-sigma rationale**:
- Conservative: Only flags genuine artifacts
- Biological signals rarely exceed ±3σ
- Balance between false positives and false negatives
- Standard in neuroimaging (SPM, FSL use similar thresholds)

**Example mask**:
```matlab
% For one frame (Y × X slice):
maskG(:,:,347) = 
[0 0 0 0 0 ...]
[0 1 0 0 0 ...]  ← One outlier at (row 2, col 2)
[0 0 0 0 0 ...]
```

**Statistics tracked**:
```matlab
numOutliers = sum(maskG(:));           % Total outliers
numTotal = numel(PDI.PDI);             % Total values
outlierRatio = numOutliers / numTotal; % Fraction rejected
```

**Typical outlier ratios**:
```
Good data:    0.001-0.005 (0.1-0.5%)
Acceptable:   0.005-0.01  (0.5-1%)
Concerning:   >0.01       (>1%)
```

### 5c. Flag Outliers as NaN

**Purpose**: Mark outlier values for interpolation

**Code**:
```matlab
PDI.PDI(maskG) = NaN;
```

**Why NaN (Not a Number)?**
- MATLAB's standard missing data indicator
- Preserves data array structure
- `fillmissing` function recognizes NaN
- Distinguishes missing from zero

**Effect on data**:
```matlab
Before:  [10.2, 10.5, 25.3, 10.9, 11.1]
         ↓
After:   [10.2, 10.5, NaN,  10.9, 11.1]
```

**Not deletion**:
- Array size unchanged
- Position information preserved
- Ready for interpolation

### 5d. Temporal Interpolation

**Purpose**: Estimate outlier values from temporal neighbors

**Code**:
```matlab
PDI.PDI = fillmissingTime(PDI.PDI, 'linear');
```

**What fillmissingTime does**:

**Step 1: Reshape to 2D**
```matlab
% Inside fillmissingTime:
X = reshape(volIn, [], sz(3));    % [Y*X × T]
```
- Converts 3D volume to 2D matrix
- Each row = one voxel's complete timeseries
- Enables efficient vectorized processing

**Step 2: Interpolate along time (dimension 2)**
```matlab
X = fillmissing(X, 'linear', 2, 'EndValues', 'nearest');
```
- `'linear'`: Linear interpolation between neighbors
- `2`: Interpolate along columns (time dimension)
- `'EndValues', 'nearest'`: Fill edge NaNs with nearest valid value

**Step 3: Reshape back to 3D**
```matlab
volOut = reshape(X, sz);    % [Y × X × T]
```

**Interpolation example**:
```
Voxel timeseries:
[10.2, 10.5, NaN, 10.9, 11.1]
              ↓
Linear interpolation:
[10.2, 10.5, 10.7, 10.9, 11.1]
              ↑
Interpolated: (10.5 + 10.9) / 2 = 10.7
```

**Why temporal (not spatial) interpolation?**

**Temporal makes sense**:
- ✅ fUSI signals have strong temporal autocorrelation
- ✅ Activity at t=347 similar to t=346 and t=348
- ✅ Outliers are brief (single timepoint)
- ✅ Each voxel's timeseries is independent

**Spatial would be wrong**:
- ❌ Different brain regions have different characteristics
- ❌ Would blur spatial patterns
- ❌ Outliers often affect single voxels only

**Why linear interpolation?**

| Method | Advantages | Disadvantages |
|--------|------------|---------------|
| **Linear** | ✅ Simple<br>✅ Fast<br>✅ Stable<br>✅ No overfitting | May not capture complex dynamics |
| Pchip | Smoother curves | Slower, can overshoot |
| Spline | Very smooth | Can create unrealistic values |

For sparse outliers (<1%), linear is optimal.

**Edge handling**:
```
If NaN at start/end of timeseries:
[NaN, 10.5, 10.7, 10.9] → [10.5, 10.5, 10.7, 10.9]
                           ↑ nearest valid value
```

### 5e. Store Rejection Parameters

**Purpose**: Document outlier rejection for reproducibility and quality control

**Code**:
```matlab
PDI.voxelFrameRjection.std = std_threshold;
PDI.voxelFrameRjection.interpMethod = 'linear';
PDI.voxelFrameRjection.ratio = outlierRatio;
```

**Stored metadata**:
```matlab
PDI.voxelFrameRjection
├── std             % 5 (z-score threshold)
├── interpMethod    % 'linear' (interpolation method)
└── ratio           % 0.0023 (fraction of outliers, e.g., 0.23%)
```

**Why store these parameters?**

**1. Reproducibility**:
- Document exact processing applied
- Enable replication of analysis
- Critical for publications

**2. Quality assessment**:
- High ratio (>1%) indicates data quality issues
- Compare across sessions/subjects
- Flag problematic datasets

**3. Method validation**:
- Verify conservative threshold used
- Document interpolation method
- Support methods section in papers

### Voxelwise vs Frame Rejection

**This approach (voxelwise)**:
- ✅ Preserves all frames
- ✅ Maintains temporal resolution
- ✅ Removes only problematic values
- ✅ Typical: 0.1-1% data affected

**Alternative (frame rejection)**:
- ❌ Removes entire timepoints
- ❌ Loses temporal samples
- ❌ Can't distinguish localized artifacts
- ❌ May remove 5-10% of frames

**When voxelwise is appropriate**:
- Outliers are sparse and random
- Artifacts affect individual voxels
- Want to preserve temporal resolution
- **This is the case for fUSI**

### Processing Parameters

**Hardcoded (well-chosen)**:
```matlab
std_threshold = 5;          % Conservative threshold
interpMethod = 'linear';    % Simple, robust interpolation
```

**Rationale**:
- 5-sigma: Standard in neuroimaging
- Linear: Optimal for sparse outliers
- No tuning needed for typical fUSI data

### Console Output

```
=== Performing Outlier Rejection ===

Detected 276 outliers (0.23% of all values)
Outlier rejection complete (threshold: 5-sigma, method: linear)

=== Outlier Rejection Complete ===
```

**Interpretation**:
```
0.1-0.5%:  Excellent data quality
0.5-1.0%:  Good, typical for fUSI
1.0-2.0%:  Acceptable, monitor quality
>2.0%:     Concerning, investigate source
```

### Success Criteria

Outlier rejection successfully applied when:
- ✅ Z-scores calculated for each voxel across time
- ✅ Outliers detected with 5-sigma threshold
- ✅ Outlier ratio is reasonable (<1-2%)
- ✅ NaN flagging completed
- ✅ Temporal interpolation applied
- ✅ Parameters stored in PDI.voxelFrameRjection
- ✅ Data ready for normalization

---

## 6. Signal Normalization (Percent Signal Change)

### What Happens

This section converts raw signal intensities to percent signal change (PSC) by normalizing each voxel's timeseries by its temporal mean. This transformation removes baseline differences between voxels and provides interpretable units for statistical analysis.

### Why Signal Normalization is Critical

**Problem**: Raw signal intensities vary across brain regions
- Different voxels have different baseline blood flow
- Absolute values not comparable across regions
- Arbitrary units (not physiologically meaningful)
- Violates GLM homogeneity assumptions

**Solution**: Normalize by temporal mean
- Each voxel scaled relative to its own baseline
- Result in percentage units (interpretable)
- Comparable magnitudes across brain
- Better statistical properties

**Benefits**:
- **Interpretable units**: "5% increase" has clear meaning
- **Comparable across voxels**: Remove baseline differences
- **Better for GLM**: More homogeneous variance
- **Standard in fMRI/fUSI**: Common practice in neuroimaging

### Processing Pipeline Overview

```
Motion-corrected, outlier-free data
         ↓
Calculate temporal mean per voxel
         ↓
PSC = (signal - mean) / mean × 100
         ↓
Percent signal change data
```

### 6a. Calculate Temporal Mean

**Purpose**: Compute baseline signal for each voxel

**Code**:
```matlab
n_Frames = size(PDI.PDI, 3);
mu = repmat(mean(PDI.PDI, 3), 1, 1, n_Frames);
```

**What this does**:

**Step 1**: Calculate mean
```matlab
mean(PDI.PDI, 3)  % [Y × X × 1]
```
- Computes temporal average for each voxel
- Result: One mean value per voxel
- This is the "baseline" signal

**Step 2**: Replicate across time
```matlab
repmat(..., 1, 1, n_Frames)  % [Y × X × T]
```
- Repeats mean value for all timepoints
- Enables element-wise operations
- Each timepoint has its voxel's mean

**Example**:
```matlab
Voxel (50,60) timeseries:     [10, 11, 12, 11, 10]
Mean:                         11
Replicated:                   [11, 11, 11, 11, 11]
```

### 6b. Apply PSC Formula

**Purpose**: Convert to percent signal change

**Formula** (LaTeX):

$$\text{PSC}(t) = \frac{S(t) - \bar{S}}{\bar{S}} \times 100$$

Where:
- $S(t)$ = Signal at time $t$
- $\bar{S}$ = Temporal mean
- $\text{PSC}(t)$ = Percent signal change

**Code**:
```matlab
PDI.PDI = (PDI.PDI - mu) ./ mu .* 100;
```

**Element-wise operations**:
1. `(PDI.PDI - mu)`: Subtract baseline (deviation from mean)
2. `./ mu`: Divide by baseline (normalize)
3. `.* 100`: Convert to percentage

**Example calculation**:
```
Voxel timeseries:    [10,  11,  12,  11,  10]
Mean (μ):            11
Deviation:           [-1,   0,   1,   0,  -1]
Normalized:          [-0.09, 0, 0.09, 0, -0.09]
PSC (%):             [-9%,  0%,  9%,  0%,  -9%]
```

**Interpretation**:
- PSC = 0: Signal at baseline
- PSC = +5: Signal 5% above baseline
- PSC = -10: Signal 10% below baseline

### 6c. Alternative: Z-score Normalization

**Commented out code**:
```matlab
% PDI.PDI = zscore(PDI.PDI, 0, 3);
```

**Z-score formula**:

$$z(t) = \frac{S(t) - \bar{S}}{\sigma}$$

Where $\sigma$ = standard deviation

**When to use z-score instead of PSC?**

| Use Case | PSC | Z-score |
|----------|-----|---------|
| **GLM analysis** | ✅ Preferred | ❌ |
| **Activation magnitude** | ✅ Interpretable | ❌ Unitless |
| **ISC analysis** | ❌ | ✅ Preferred |
| **Cross-subject comparison** | ❌ Different baselines | ✅ Standardized |
| **Preserving signal magnitude** | ✅ Yes | ❌ No |

**Why PSC for GLM?**
- Preserves magnitude information (effect sizes meaningful)
- Interpretable units (percent change)
- Variance not artificially standardized

**Why z-score for ISC?**
- Inter-subject correlation analysis
- Focus on temporal patterns, not magnitude
- Standardizes different noise levels

### Processing Parameters

**Hardcoded (well-chosen)**:
```matlab
normalization = 'PSC'  % Percent signal change (not z-score)
```

### Console Output

```
=== Converting to Percent Signal Change ===
Signal converted to percent change (baseline = 0%)
=== Percent Signal Change Complete ===
```

### Success Criteria

Signal normalization complete when:
- ✅ Temporal mean calculated for each voxel
- ✅ PSC formula applied element-wise
- ✅ Units now in percent (interpretable)
- ✅ Baseline differences removed
- ✅ Data ready for resampling

---

## 7. Temporal Resampling

### What Happens

This section resamples functional data to a consistent 5 Hz temporal resolution using linear interpolation. This standardizes the sampling rate across sessions and ensures regular time intervals required for subsequent analysis.

### Why Temporal Resampling is Critical

**Problem**: Variable or irregular sampling rates
- Different sessions may have different frame rates
- Acquisition frame rate may vary slightly over time
- GLM and filtering require uniform sampling
- Cross-session comparisons need consistent resolution

**Solution**: Resample to standard 5 Hz
- Creates new time vector at exactly 5 Hz
- Interpolates signal values at new timepoints
- Ensures uniform temporal spacing

**Benefits**:
- **Standardization**: All sessions at same rate
- **GLM compliance**: Requires regular sampling
- **Filtering**: DCT and other filters need uniform spacing
- **Comparability**: Same temporal resolution across datasets

### Processing Pipeline Overview

```
PSC-normalized data at variable rate
         ↓
Create new time vector (5 Hz)
         ↓
Linear interpolation
         ↓
Resampled data at 5 Hz
```

### 7a. Create New Time Vector

**Purpose**: Define target sampling times

**Code** (inside `resamplePDI.m`):
```matlab
PDI.time = min(PDI.time):1/frequency:max(PDI.time);
```

**What this does**:
- `min(PDI.time)`: Start time (typically 0)
- `max(PDI.time)`: End time (e.g., 240 seconds)
- `1/frequency`: Interval (1/5 = 0.2 seconds)
- Result: Regular grid of timepoints

**Example**:
```
Original time (irregular):  [0, 0.51, 1.02, 1.48, 2.01, ...]
New time (5 Hz):           [0, 0.20, 0.40, 0.60, 0.80, 1.00, ...]
```

### 7b. Linear Interpolation

**Purpose**: Estimate signal values at new timepoints

**Code** (inside `resamplePDI.m`):
```matlab
PDI.PDI(isnan(PDI.PDI)) = 0;  % Replace NaN with 0 before interpolation
PDIres = interp1(oldtime, permute(PDI.PDI,[3,1,2]), PDI.time);
PDI.PDI = permute(PDIres, [2,3,1]);
```

**What `interp1` does**:

**Step 1**: Query points determination
- For each new timepoint, find bracketing old timepoints
- Example: new time 0.45s bracketed by old times 0.40s and 0.51s

**Step 2**: Linear interpolation
```
value(t_new) = value(t1) + (t_new - t1) / (t2 - t1) × [value(t2) - value(t1)]
```

**Step 3**: Vectorized across all voxels
- `permute` reshapes to [T × Y × X] for efficient interpolation
- Interpolates all voxels simultaneously
- `permute` back to [Y × X × T]

**Example interpolation**:
```
Old times:     [1.0s,    1.5s]
Old values:    [10%,     14%]
New time:      1.2s
New value:     10% + (1.2-1.0)/(1.5-1.0) × (14%-10%) = 10% + 0.4 × 4% = 11.6%
```

**Why linear interpolation?**

| Method | Advantages | Disadvantages |
|--------|------------|---------------|
| **Linear** | ✅ Simple<br>✅ Fast<br>✅ No overshoot<br>✅ Preserves trends | Some smoothing |
| Spline | Smoother | Can overshoot, slower |
| Nearest | Fastest | Blocky, loses information |

### 7c. Update Time Stamps

**Purpose**: Replace old time vector with new regular grid

**Result**:
```matlab
PDI.time [T_new × 1]  % New, regularly-spaced timestamps
PDI.PDI [Y × X × T_new]  % Resampled data
```

**Typical change**:
```
Original: ~1.8 Hz, 1200 frames, 667 seconds → irregular spacing
Resampled: 5 Hz, 3335 frames, 667 seconds → exact 0.2s intervals
```

### Why 5 Hz?

**Rationale for 5 Hz choice**:
1. **Higher than Nyquist**: fUSI signals < 1 Hz, 5 Hz safely captures them
2. **Standard rate**: Common in fMRI/fUSI literature
3. **Not excessive**: Higher rates increase data size unnecessarily
4. **Filter compatibility**: Good for DCT and other filters

**Alternative rates**:
- 2 Hz: Sufficient for slow hemodynamics, smaller files
- 10 Hz: Overkill for fUSI (signals << 1 Hz)
- 5 Hz: Sweet spot for fUSI

### Processing Parameters

**Configurable**:
```matlab
resampling_rate = 5;  % Hz
```

**Can be changed** based on:
- Experiment design (e.g., rapid event-related)
- Original acquisition rate
- Storage constraints

### Console Output

```
=== Resampling to 5 Hz ===
Original sampling rate: 1.80 Hz
Target sampling rate: 5 Hz
Data resampled to 5 Hz (3335 frames)
=== Resampling Complete ===
```

### Success Criteria

Temporal resampling complete when:
- ✅ New time vector created at exactly 5 Hz
- ✅ Linear interpolation applied to all voxels
- ✅ Time intervals are uniform (0.2s between frames)
- ✅ Number of frames updated appropriately
- ✅ Data ready for temporal filtering

---

## 8. Temporal Highpass Filtering

### What Happens

This section removes slow signal drifts using Discrete Cosine Transform (DCT) regression. Slow drifts can arise from scanner drift, physiological changes, or other non-neural sources. Highpass filtering improves detection of task-related or stimulus-evoked responses.

### Why Temporal Highpass Filtering is Critical

**Problem**: Slow signal drifts confound analysis
- Scanner/hardware drift over time
- Slow physiological oscillations (breathing, heart rate)
- Non-neural baseline shifts
- Obscures true neural signals

**Impact without filtering**:
- False positive activations from drift
- Reduced statistical power
- Correlation with uninteresting slow changes
- Poor GLM fits

**Solution**: DCT-based highpass filter
- Removes components with period > cutoff
- Preserves faster fluctuations (neural signals)
- Based on SPM method (well-validated)

**Benefits**:
- **Removes nuisance drift**: Focus on neural signals
- **Improves GLM fits**: Better residuals
- **No edge artifacts**: Unlike Butterworth filters
- **Interpretable cutoff**: Period in seconds

### Processing Pipeline Overview

```
Resampled data at 5 Hz
         ↓
Build DCT basis (periods > cutoff)
         ↓
Regress out drift (like GLM)
         ↓
Return residuals = highpass filtered data
```

### 8a. DCT Basis Construction

**Purpose**: Create cosine basis functions representing slow drift

**Formula** (from `DCThighpass.m`):

**Number of basis functions**:
```matlab
K = floor(2 * T / (cutoff_sec * fs))
```

Where:
- T = number of timepoints
- fs = sampling frequency (Hz)
- cutoff_sec = cutoff period (seconds)

**Example calculation**:
```
T = 3335 frames
fs = 5 Hz
cutoff = 500 seconds
Scan length = 3335/5 = 667 seconds

K = floor(2 × 667 / 500) = floor(2.67) = 2 basis functions
```

**DCT basis formula**:
```matlab
C(:,k) = cos(π × (2t + 1) × k / (2T))
```

For k = 1, 2, ..., K

**What these represent**:
- Each column = one cosine with specific period
- Lower k = longer period (slower drift)
- K columns capture periods ≥ cutoff

**Visualization** (conceptual):
```
Basis 1: Slowest drift (period ~500s)
Basis 2: Next slowest (period ~250s)
...
Combined: Captures all slow drift
```

### 8b. Regression and Residuals

**Purpose**: Remove drift components from data

**Regression formula**:
```matlab
beta = (C' * C) \ (C' * Y')  % Least squares
```

**Compute residuals**:
```matlab
Yhp = Y' - C * beta  % Highpass filtered = residuals
```

**What this does**:

**Like GLM nuisance regression**:
1. Drift components = nuisance regressors
2. Fit them to data (find betas)
3. Subtract fitted drift
4. Residuals = drift-free signal

**Example**:
```
Original signal:    Contains slow drift + neural signals
DCT basis captures: Slow drift only
After regression:   Neural signals (drift removed)
```

### 8c. Filter Parameters

**Parameters explained**:

**Cutoff period (500 seconds)**:
```matlab
cutoff_in_seconds = 500
```

**What it means**:
- Removes signals with period **> 500 seconds**
- Preserves signals with period **< 500 seconds**
- Example: 500s cutoff removes 0.002 Hz and below

**Cutoff frequency equivalent**:
```
f_cutoff = 1 / cutoff_sec = 1/500 = 0.002 Hz
```

**Appropriate cutoffs**:

| Scan Length | Suggested Cutoff | Rationale |
|-------------|------------------|-----------|
| < 200s | 100s | Remove very slow drift |
| 200-500s | 200s | Moderate highpass |
| > 500s | 500s | Gentle highpass |

**Warning**: If cutoff > scan length:
```
scan_length = 240s, cutoff = 500s
K = floor(2 × 240 / 500) = 0
→ No filtering applied (cutoff too long)
```

**Why DCT instead of other filters?**

| Method | Advantages | Disadvantages |
|--------|------------|---------------|
| **DCT regression** | ✅ No edge artifacts<br>✅ Interpretable cutoff<br>✅ SPM standard<br>✅ Like GLM | Slightly complex |
| Butterworth | Smooth frequency response | Edge artifacts |
| Polynomial detrending | Simple | Less flexible |
| Moving average | Very simple | Phase shifts |

### Processing Parameters

**Configurable**:
```matlab
cutoff_in_seconds = 500  % Period cutoff (seconds)
sampling_rate = 5        % After resampling (Hz)
```

**Recommendations**:
- **Long scans (>10 min)**: 500s cutoff okay
- **Short scans (<5 min)**: Use 100-200s cutoff
- **Task-based**: Match to slowest task frequency

### Console Output

```
=== Applying Temporal Highpass Filter ===
Filter parameters:
  Cutoff period: 500 seconds
  Sampling rate: 5 Hz
Temporal highpass filtering complete
=== Highpass Filtering Complete ===
```

### Success Criteria

Temporal highpass filtering complete when:
- ✅ DCT basis constructed (K functions)
- ✅ Drift components regressed out
- ✅ Residuals computed (filtered data)
- ✅ Slow drift removed (period > cutoff)
- ✅ Fast signals preserved
- ✅ Data ready for spatial smoothing/saving

---

## 9. Spatial Smoothing

### What Happens

This section applies Gaussian smoothing to reduce high-frequency noise and improve spatial signal-to-noise ratio. Smoothing with σ=1 pixel corresponds to FWHM = 2.355 pixels, which matches the spatial spread of the hemodynamic response in fUSI.

### Why Spatial Smoothing is Critical

**Problem**: High-frequency spatial noise
- Random voxel-wise noise
- Scanner-related fluctuations
- Reduces statistical power
- Obscures true activation patterns

**Solution**: Gaussian kernel smoothing
- Averages each voxel with neighbors
- Reduces random noise
- Matches hemodynamic blur
- Improves signal-to-noise ratio

**Benefits**:
- **Noise reduction**: Random fluctuations averaged out
- **Better SNR**: Signal stands out more clearly
- **Matches physiology**: Hemodynamic response spreads ~1-2 pixels
- **Standard preprocessing**: Used in fMRI/fUSI pipelines

### Processing Pipeline Overview

```
Highpass-filtered data
         ↓
For each frame:
  → Apply Gaussian filter (σ=1)
  → Replace frame with smoothed version
         ↓
Smoothed data
```

### Gaussian Kernel

**2D Gaussian function**:

$$G(x,y) = \frac{1}{2\pi\sigma^2} e^{-\frac{x^2 + y^2}{2\sigma^2}}$$

Where σ (sigma) controls the width of the kernel.

**FWHM Relationship**:

$$\text{FWHM} = 2\sqrt{2\ln(2)} \times \sigma \approx 2.355\sigma$$

**What is FWHM?**
- Full Width at Half Maximum
- Width of Gaussian at 50% of peak height
- More intuitive measure of "spread" than σ

**Mathematical derivation**:

At center: $G(0,0) = 1$ (normalized)

At half-maximum: $G(x,0) = 0.5$

$$e^{-\frac{x^2}{2\sigma^2}} = 0.5$$

$$x = \sigma\sqrt{2\ln(2)} \approx 1.177\sigma$$

$$\text{FWHM} = 2x \approx 2.355\sigma$$

### Implementation

**Code**:
```matlab
spatial_sigma = 1;  % Gaussian kernel width (pixels)
[nY, nX, nFrames] = size(PDI.PDI);

% Apply Gaussian filter to each frame
for k = 1:nFrames
    PDI.PDI(:,:,k) = imgaussfilt(PDI.PDI(:,:,k), spatial_sigma);
end

% Store smoothing parameter
PDI.spatialSigma = spatial_sigma;
```

**What `imgaussfilt` does**:

**Step 1**: Creates Gaussian kernel
- Size: ceil(6*sigma) pixels (covers 99.7% of distribution)
- For σ=1: kernel is ~7×7 pixels
- Normalized so weights sum to 1

**Step 2**: Convolves with image
- For each pixel: weighted average of neighborhood
- Weights determined by Gaussian function
- Edge pixels handled with padding

**Example smoothing**:
```
Original (noisy):        Smoothed (σ=1):
[10, 15, 12, 11]         [11.2, 12.1, 12.0, 11.8]
[11, 25, 14, 10]    →    [12.5, 14.8, 13.2, 11.5]
[12, 13, 11, 9]          [11.8, 12.5, 11.7, 10.2]
```

### Why σ=1 Pixel?

**Appropriate for fUSI because**:

**1. Matches hemodynamic blur**:
- Blood flow changes spread ~0.1-0.2 mm
- Typical pixel size: 0.05-0.1 mm
- σ=1 pixel ≈ 0.05-0.1 mm FWHM
- Matches physiological point spread function

**2. Balance noise vs resolution**:
- Larger σ: More noise reduction, less spatial detail
- Smaller σ: Less noise reduction, preserves detail
- σ=1: Sweet spot for fUSI

**3. Standard in neuroimaging**:
- Common SPM/FSL default
- Facilitates comparison across studies
- Well-validated in fMRI literature

**Comparison of different σ values**:

| Sigma | FWHM | Smoothing Radius | Use Case |
|-------|------|------------------|----------|
| 0.5 | 1.2 px | ~1-2 pixels | High resolution, minimal smoothing |
| **1.0** | **2.4 px** | **~2-3 pixels** | **Standard fUSI (recommended)** |
| 2.0 | 4.7 px | ~4-6 pixels | Heavy smoothing, low resolution |

### Effective Smoothing Radius

**Rule of thumb**: Gaussian extends ~3σ before negligible

```matlab
effective_radius = ceil(3 * spatial_sigma)  % ~3 pixels for σ=1
```

**Interpretation**:
- σ=1 pixel affects a ~7×7 pixel neighborhood
- Central pixel weight ≈ 0.24
- Immediate neighbors ≈ 0.10-0.15 each
- Corners ≈ 0.01-0.02 each

### Frame-by-Frame Processing

**Why loop through frames?**

`imgaussfilt` is designed for 2D images, not 3D volumes. While it can handle 3D, it would smooth across time (undesirable). Frame-by-frame ensures:
- Spatial smoothing only (not temporal)
- Each frame independent
- Preserves temporal dynamics
- Clear, explicit processing

**Computational cost**:
- ~10-20ms per frame
- 3000 frames ≈ 30-60 seconds total
- Acceptable preprocessing time

### Processing Parameters

**Hardcoded (well-chosen)**:
```matlab
spatial_sigma = 1;  % pixels
```

**Can be modified** based on:
- Image resolution (higher res → larger σ)
- Analysis goals (ROI vs whole-brain)
- Noise characteristics (more noise → larger σ)

### Console Output

```
=== Applying Spatial Smoothing ===
Smoothing parameters:
  Sigma: 1.0 pixels
  FWHM: 2.35 pixels
  Effective smoothing radius: ~3 pixels
Spatial smoothing complete
=== Spatial Smoothing Complete ===
```

### Success Criteria

Spatial smoothing complete when:
- ✅ Gaussian kernel applied to each frame
- ✅ Smoothing parameter stored in PDI.spatialSigma
- ✅ Noise reduced while preserving spatial features
- ✅ Data ready for saving

---

## 10. Save Preprocessed Data

### What Happens

This section saves the fully preprocessed PDI data to the functional data directory with the filename `prepPDI.mat`. All preprocessing metadata is preserved, creating a self-contained file ready for statistical analysis.

### Why Proper Data Saving is Critical

**Purpose**: Create analysis-ready dataset
- Preserve all preprocessing steps
- Document processing parameters
- Enable reproducible analysis
- Self-contained data file

**What's saved**:
- Preprocessed imaging data (PDI.PDI)
- All original metadata (time, Dim, stimInfo, etc.)
- Processing parameters:
  - Brain mask (PDI.bmask)
  - Motion parameters (PDI.motionParams)
  - Outlier rejection info (PDI.voxelFrameRjection)
  - Smoothing parameters (PDI.spatialSigma)

### Output File

**Filename**: `prepPDI.mat`

**Location**: Same directory as input PDI.mat

**Example paths**:
```
Input:  Data_analysis/run-115047-func/PDI.mat
Output: Data_analysis/run-115047-func/prepPDI.mat
```

### File Contents

**Complete PDI structure**:
```matlab
PDI (struct)
├── PDI [Y × X × T double]            % Preprocessed data (% signal change)
├── time [T × 1 double]               % Regular timestamps at 5 Hz
├── bmask [Y × X logical]             % Brain mask
├── motionParams [T × 2 double]       % Motion correction (X,Y translation)
├── voxelFrameRjection (struct)       % Outlier rejection metadata
│   ├── std (5)
│   ├── interpMethod ('linear')
│   └── ratio (e.g., 0.0023)
├── spatialSigma (1)                  % Smoothing parameter
├── Dim (struct)                      % Dimension metadata
├── stimInfo [table]                  % Experimental events (preserved)
├── wheelInfo [table]                 % Running wheel (preserved)
├── gsensorInfo [table]               % Head motion sensor (preserved)
└── savepath                          % Output directory
```

### Save Function: parsave

**Why use `parsave` instead of regular `save`?**

**Code**:
```matlab
parsave(output_path, PDI);
```

**Definition** (in `src/parsave.m`):
```matlab
function parsave(fname, PDI)
    save(fname, 'PDI');
end
```

**Reasons for this approach**:

**1. Parallel processing safety**:
- Regular `save` can fail in `parfor` loops
- `parsave` wraps save in a function
- Ensures each worker has isolated save operation
- No file collision in parallel execution

**2. Future-proofing**:
- Easy to add compression: `save(fname, 'PDI', '-v7.3')`
- Can add error handling
- Centralized save logic

**3. Consistency**:
- Same save method across all preprocessing scripts
- Easier to maintain

### Processing Summary

**Console output includes comprehensive summary**:

```
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

**What this tells you**:
- Confirmation of successful completion
- Output filename (for verification)
- Final data dimensions
- All 10 processing steps confirmed

### Data Transformations Summary

**Raw → Preprocessed**:

```
Input:  PDI.mat
  - Raw signal (arbitrary units)
  - Variable sampling (~1.8 Hz)
  - Motion artifacts
  - Outliers present
  - Slow drift
  - High-frequency noise

Output: prepPDI.mat
  - Percent signal change (interpretable units)
  - Regular sampling (5 Hz)
  - Motion corrected
  - Outliers interpolated
  - Drift removed (highpass)
  - Noise reduced (smoothed)
```

### File Size Considerations

**Typical sizes**:
```
Input PDI.mat:     ~50-100 MB (1200 frames)
Output prepPDI.mat: ~120-200 MB (3335 frames at 5 Hz)
```

**Why larger**:
- More frames (resampling to 5 Hz increases temporal samples)
- Additional metadata (motion params, mask, etc.)
- Still reasonable for modern storage

**Compression options** (if needed):
```matlab
save(output_path, 'PDI', '-v7.3', '-nocompression');  % Faster
save(output_path, 'PDI', '-v7.3');  % Compressed (slower, smaller)
```

### Verification Steps

**After saving, verify**:

```matlab
% Load and check
load('prepPDI.mat');

% Verify key fields
assert(isfield(PDI, 'bmask'), 'Missing brain mask');
assert(isfield(PDI, 'motionParams'), 'Missing motion parameters');
assert(isfield(PDI, 'voxelFrameRjection'), 'Missing outlier info');
assert(PDI.spatialSigma == 1, 'Unexpected smoothing parameter');

% Check dimensions
assert(size(PDI.PDI, 3) > 3000, 'Fewer frames than expected');

% Check sampling rate
dt = mean(diff(PDI.time));
assert(abs(dt - 0.2) < 0.001, 'Not 5 Hz sampling');
```

### Console Output

```
=== Saving Preprocessed Data ===
Output location: /path/to/Data_analysis/run-115047-func/prepPDI.mat
Saving preprocessed data...
Preprocessed data saved successfully
=== Preprocessing Complete ===

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

### Success Criteria

Preprocessing complete when:
- ✅ Output file saved to correct location
- ✅ All preprocessing metadata included
- ✅ File size reasonable (~100-200 MB)
- ✅ Can be loaded successfully
- ✅ Ready for statistical analysis
- ✅ 10/10 processing steps confirmed

---

# Summary

This preprocessing pipeline implements a complete **10-step preprocessing workflow**:

**Step 1: Handle Input Arguments**
- Flexible path input (direct or interactive)
- Sequential uigetdir prompts with terminal messages
- Mixed mode support (some args provided, some prompted)
- No hardcoded paths or subject indexing

**Step 2: Load All Required Data**
- Allen brain atlas (reference coordinate system)
- Anatomical scan (subject-specific anatomy)
- Transformation matrix (atlas-to-subject registration)
- Functional data (PDI to be preprocessed)
- Centralized loading with validation

**Step 3: Create Brain Mask**
- Transform atlas to subject space
- Extract functional slice from 3D volume
- Create binary mask (threshold > 1)
- Morphological dilation (radius = 2)
- Store mask in PDI structure
- Quality control visualization

**Step 4: Motion Correction**
- Median reference frame creation
- Frame-by-frame rigid translation estimation (imregcorr)
- Transformation application (imwarp)
- Motion parameter storage and visualization
- Cross-correlation-based alignment (optimal for fUSI)
- Sub-pixel precision (~0.1 pixel)

**Step 5: Outlier Rejection**
- Voxelwise z-score calculation (independent per voxel)
- Conservative 5-sigma threshold
- NaN flagging of outliers
- Temporal linear interpolation (not spatial)
- Ratio tracking (typical: 0.1-1%)
- Preserves all frames (no data loss)

**Step 6: Signal Normalization**
- Percent signal change (PSC) conversion
- Formula: PSC(t) = (S(t) - mean(S)) / mean(S) × 100
- Removes baseline differences between voxels
- Interpretable units for GLM analysis
- Alternative z-score normalization (commented, for ISC)

**Step 7: Temporal Resampling**
- Resample to 5 Hz (0.2s intervals)
- Linear interpolation between timepoints
- Standardizes sampling rate across sessions
- Required for DCT filtering and GLM

**Step 8: Temporal Highpass Filtering**
- DCT-based regression (SPM method)
- Cutoff: 500 seconds (removes drift with period > 500s)
- No edge artifacts
- Preserves fast neural signals

**Step 9: Spatial Smoothing**
- Gaussian kernel (σ = 1 pixel, FWHM = 2.355 pixels)
- Frame-by-frame smoothing with `imgaussfilt`
- Reduces high-frequency noise
- Improves signal-to-noise ratio
- Matches hemodynamic blur

**Step 10: Save Preprocessed Data**
- Output as `prepPDI.mat` in functional directory
- Includes all preprocessing metadata
- Uses `parsave` for parallel safety
- Complete processing summary displayed

## Key Architecture Features

**1. Function-Based Design**
- Not a script - proper MATLAB function
- Accepts optional input arguments
- Enables batch and parallel processing

**2. Modular Helper Functions**
- load_anat_and_func.m: Centralized data loading
- visualize_brain_mask.m: Separate visualization
- Atlas2Individual.m: Atlas transformation
- Single responsibility per function

**3. No Subject Indexing**
- Processes one subject per call
- No isub variables or cell array indexing
- Clean, simple code
- Parallel-ready architecture

**4. Enhanced Documentation**
- Clear section headers and progress messages
- Inline comments explain the "why"
- Function documentation headers
- Technical documentation (this file)

**5. Flexible Input Handling**
- Works with any directory structure
- No hardcoded paths
- Interactive or scripted use
- Platform-independent (macOS terminal prompts)

## Key Principles

- **Flexible execution**: Interactive or scripted modes
- **Clear documentation**: Code explains what and why
- **Modular architecture**: Reusable, maintainable components
- **Progress feedback**: Console messages track stages
- **Quality control**: Visualization for mask verification
- **Non-destructive**: Mask stored separately, not applied
- **Future-ready**: Prepared for remaining preprocessing steps

The current implementation establishes the foundation for complete preprocessing, with clean architecture and clear documentation that will support adding the remaining processing steps.

---
