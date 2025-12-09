# Product Context: fUSI Preprocessing Pipeline

## Why This Project Exists

### Current Pain Points
1. **Rigid Path Management**: The current `Preprocessing_DEV.m` relies on `Datapath_DEV.m` with hardcoded paths and condition strings ('VisualTest', 'ShockTest')
2. **Non-Reusable Structure**: The script was designed for loop-based batch processing but now processes single subjects with remnant `isub` indexing
3. **Limited Flexibility**: Cannot easily process arbitrary subject data without modifying `Datapath_DEV.m`
4. **Unclear Preprocessing Steps**: While functional, the pipeline lacks comprehensive documentation of what each step accomplishes

### Problems We're Solving
- Make the preprocessing pipeline more flexible and reusable
- Enable easy processing of new subjects without code modification
- Prepare infrastructure for parallel processing across subjects
- Improve code clarity and maintainability
- Facilitate understanding of each preprocessing step's purpose

## How It Should Work

### Desired User Experience

#### Input Flexibility
```matlab
% Option 1: Provide paths directly
preprocess_fusi(anat_path, func_path)

% Option 2: Interactive selection (no arguments)
preprocess_fusi()  % Opens uigetdir dialogs
```

#### Processing Flow
1. **Input Acquisition**: Accept or prompt for anatomical and functional data paths
2. **Data Loading**: Load PDI.mat (functional), anatomic.mat, Transformation.mat
3. **Brain Mask Creation**: Use Allen atlas to create region mask for functional slice
4. **Motion Correction**: Rigid in-plane correction using median reference
5. **Outlier Handling**: Voxelwise outlier detection and interpolation
6. **Signal Conversion**: Convert to percent signal change
7. **Resampling**: Downsample to 5Hz
8. **Filtering**: Apply temporal highpass filter
9. **Smoothing**: Apply spatial Gaussian smoothing
10. **Save**: Store preprocessed data as prepPDI.mat

### Key User Benefits
- **Flexibility**: Process any subject by providing paths
- **Ease of Use**: Interactive mode for exploratory analysis
- **Clarity**: Well-documented steps explain what happens to the data
- **Scalability**: Single-subject design enables easy parallelization
- **Maintainability**: Clear structure makes future modifications easier

## User Goals

### Primary Goals
1. Preprocess fUSI data from anatomical and functional scans
2. Apply standardized preprocessing pipeline consistently
3. Understand what each preprocessing step does to the data

### Secondary Goals
1. Process multiple subjects efficiently (future parallel implementation)
2. Easily adapt pipeline for new subjects/datasets
3. Debug preprocessing issues by understanding each step

## Expected Outcomes
- Clean, well-documented preprocessing function
- Flexible input handling (arguments or UI selection)
- Preserved functionality with improved structure
- Foundation for parallel processing implementation
- Better understanding of preprocessing pipeline for all users
