# Project Brief: fUSI Preprocessing Pipeline Refactoring

## Project Overview
Refactoring and improving the MATLAB preprocessing pipeline for functional ultrasound imaging (fUSI) data. The project focuses on restructuring the main preprocessing script while maintaining all existing functionality and improving code clarity.

## Core Objectives

### 1. Refactor Input Handling
- **Current**: Uses `Datapath_DEV.m` function with hardcoded paths and condition strings
- **Target**: Accept anatomical and functional data paths as input parameters
- **Fallback**: If paths not provided, use `uigetdir` for user selection
- **Goal**: More flexible, reusable preprocessing function

### 2. Remove Loop-Based Subject Indexing
- **Current**: Uses `isub` variable for indexing subjects (remnant from loop structure)
- **Target**: Single-subject processing per script execution
- **Future**: Enable parallel processing with subject lists/dictionaries
- **Rationale**: Cleaner code, better for parallel execution

### 3. Improve Code Understanding
- Document what each preprocessing step does
- Clarify the purpose of each section
- Make the pipeline more transparent and maintainable

## Constraints & Considerations

### Data Handling
- Large binary files exist (fUS_block_PDI_float.bin) - avoid reading these
- CSV/TSV files should only be read partially (first 20 lines max)
- Sample data available in `sample_data/` directory

### Existing Functionality Must Remain
All preprocessing steps are already working and must be preserved:
1. Load functional scan (PDI.mat)
2. Load anatomical scan (anatomic.mat, Transformation.mat)
3. Create brain mask from Allen atlas
4. Rigid in-plane motion correction
5. Voxelwise outlier rejection/interpolation
6. Percent signal change conversion
7. Resampling to 5Hz
8. Temporal highpass filtering
9. Spatial smoothing
10. Save preprocessed data

## Key Files
- `Preprocessing_DEV.m` - Main preprocessing script (to be refactored)
- `Datapath_DEV.m` - Path definition function (to be replaced/modified)
- `src/` directory - Helper functions (Atlas2Individual, DCThighpass, fillmissingTime, parsave, PDIfilter, resamplePDI)
- `allen_brain_atlas.mat` - Atlas data (referenced but not in sample_data)

## Success Criteria
1. Preprocessing function accepts anat/func paths as inputs or uses uigetdir
2. No `isub` indexing variable in refactored code
3. All preprocessing functionality preserved and working
4. Code is clearer and better documented
5. Prepared for future parallel processing implementation
