# Active Context: Current Work Focus

## Current Session Status
**Date**: March 20, 2026
**Phase**: Documentation System - COMPLETE ✅
**Mode**: Production-Ready with Three-Tiered Documentation

## Major Accomplishments

### 1. Complete 10-Step Preprocessing Pipeline ✅
Implemented full preprocessing workflow in `do_preprocessing.m`:
1. **Handle Input Arguments**: Flexible path selection (interactive/direct)
2. **Load All Required Data**: Centralized loading with validation
3. **Create Brain Mask**: Atlas-based with QC visualization
4. **Motion Correction**: Rigid translation with QC plots
5. **Outlier Rejection**: Voxelwise 5-sigma with interpolation
6. **Signal Normalization**: Percent signal change conversion
7. **Temporal Resampling**: Uniform 5 Hz sampling
8. **Temporal Highpass Filter**: DCT-based drift removal (500s cutoff)
9. **Spatial Smoothing**: Gaussian filter (σ=1 pixel, FWHM=2.355px)
10. **Save Preprocessed Data**: Output as prepPDI.mat with metadata

### 2. Modular Architecture ✅
Created 7 helper functions in `src/`:
- `load_anat_and_func.m`: Centralized data loading with path validation
- `Atlas2Individual.m`: Atlas transformation (bug fix applied)
- `visualize_brain_mask.m`: QC visualization of mask overlay
- `visualize_motion_correction.m`: QC plots for motion parameters
- `resamplePDI.m`: Temporal resampling to target frequency
- `DCThighpass.m`: DCT-based highpass filtering
- `fillmissingTime.m`: Temporal interpolation of NaN values
- `parsave.m`: Parallel-safe save wrapper

### 3. Three-Tiered Documentation System ✅
Created complete documentation hierarchy with cross-links:

**Level 1: User Guide (README_FUNC_PREPROCESSING.md)**
- Quick start and usage examples
- Troubleshooting guide
- Directory structure overview
- Mermaid pipeline diagram
- **Links to**: Walkthrough and technical docs

**Level 2: Code Walkthrough (docs/README_preprocessing_walkthrough.md)** [NEW]
- Step-by-step explanation of each processing section
- Code snippets with annotations
- Processing flow diagrams
- Dependencies for each step
- **Links to**: Technical documentation for deeper details

**Level 3: Technical Documentation (docs/FUNC_PREPROCESSING_TECH_DOCUMENT.md)**
- ~100-page complete implementation reference
- Detailed algorithms and mathematical formulas
- Design rationale for each decision
- Parameter tuning guidelines
- **Links to**: User guide and walkthrough for navigation

**Documentation Features**:
- ✅ Progressive disclosure (start simple, drill down as needed)
- ✅ Cross-linking (one-way: top → middle → deep)
- ✅ Consistent structure across all levels
- ✅ Emoji indicators for quick navigation (📖 📝 🔧)
- ✅ Based on reconstruction pipeline template

### 4. Key Improvements Over Original
- ❌ Removed `isub` indexing (no subject loops)
- ✅ Added flexible input handling (interactive + direct)
- ✅ Implemented complete pipeline (all 10 steps)
- ✅ Enhanced QC with automatic visualizations
- ✅ Modular architecture (7 focused helper functions)
- ✅ Parallel-processing ready (single-subject calls)
- ✅ Self-documenting (all parameters saved in output)

## Current Work Focus: COMPLETED

### Latest Accomplishment (March 20, 2026)
**Documentation System Finalized**

Removed redundant files and established clear documentation hierarchy:
- ❌ Deleted `align_timing_to_frames.m` - not used in production workflow
- ❌ Deleted `README_TIMING_ALIGNMENT.md` - functionality in analysis folder
- ❌ Deleted `example_align_timing.m` - redundant demo file
- ✅ Created `docs/README_preprocessing_walkthrough.md` - middle documentation layer
- ✅ Added cross-links to all three documentation files
- ✅ Clarified timing alignment happens in `04_Analysis/src/create_predictors.m`

**Rationale**: The `align_timing_to_frames.m` function duplicated functionality already implemented in the analysis pipeline's `create_predictors()` function, which handles all timing alignment plus additional features (unit conversion, stationary trial selection). Keeping both created confusion about which to use.

## Active Decisions & Considerations

### Key Questions to Address (Future)
1. **Function Name**: What should the refactored function be called?
   - Options: `preprocess_fusi`, `fusiPreprocess`, `preprocessPDI`
   
2. **Input Arguments**: Function signature design
   - `function PDI = preprocess_fusi(anatPath, funcPath, options)`
   - Or: `function preprocess_fusi(anatPath, funcPath)` (saves directly)

3. **Return Values**: What should the function return?
   - Option A: Return preprocessed PDI structure
   - Option B: Save only (no return), like current
   - Option C: Return PDI + QC metrics structure

4. **Visualization**: How to handle the brain mask visualization?
   - Option A: Remove from main function
   - Option B: Optional parameter to enable/disable
   - Option C: Separate QC visualization function

5. **Atlas Loading**: Where should `allen_brain_atlas.mat` be loaded?
   - Option A: Inside function (every call)
   - Option B: Pass as parameter (for batch processing efficiency)
   - Option C: Load once in wrapper, pass to function

6. **Error Handling**: What validation is needed?
   - Check paths exist
   - Check required files present (PDI.mat, anatomic.mat, Transformation.mat)
   - Validate atlas structure

### Design Preferences (To Confirm with User)
- **Modularity**: Separate preprocessing logic from visualization
- **Flexibility**: Support both interactive and programmatic use
- **Efficiency**: Prepare for parallel processing
- **Clarity**: Add comprehensive comments explaining each step

## Important Patterns & Learnings

### Processing Pipeline Pattern
The preprocessing follows a strict sequential order where each step depends on the previous:
1. Data loading → 2. Masking → 3. Motion correction → 4. Outlier handling → 
5. Normalization → 6. Resampling → 7. Filtering → 8. Smoothing → 9. Saving

**Critical**: Order cannot be changed without affecting results

### Path Management Pattern
Current system uses cell arrays for multi-subject support:
```matlab
subDataPath = {path1, path2, ...}
subAnatPath = {path1, path2, ...}
```
But processes with `isub` indexing. Target: single-subject function call.

### Data Structure Pattern
PDI structure accumulates metadata during processing:
- Initial: PDI.PDI, PDI.savepath
- After masking: adds PDI.bmask
- After outlier rejection: adds PDI.voxelFrameRjection
- After smoothing: adds PDI.spatialSigma

This progressive enrichment should be preserved.

### Alternative Pipeline Insight
Commented code at bottom shows experimentation with:
- LocalThreshold vs z-score outlier detection
- Z-score vs percent-change normalization
- Different save locations

This suggests the "optimal" preprocessing is still being determined.

## Project Insights

### Code Archaeology
1. **Loop Remnants**: `isub=1` and cell array indexing suggest batch processing past
2. **Dual Save Paths**: Assignment of `savepath` to both PDI and anatomic structures seems redundant but preserved
3. **Commented Alternative**: Substantial alternative pipeline suggests ongoing methods development
4. **Empty File**: `do_preprocessing.m` is empty - may be intended as future wrapper

### Technical Observations
1. **Memory Efficient**: Pre-allocates arrays (cPDI) before motion correction
2. **Progress Feedback**: Uses waitbar for long operations (good UX)
3. **Visualization**: Creates detailed QC figure showing mask overlay
4. **Dimension Quirk**: Comment notes X,Z dimensions differ between anatomic.funcSlice and anatomic/subAtlas - potential future investigation

### Dependencies Management
Helper functions in `src/` are critical but analysis shows they're simple focused utilities. This is good design - main script orchestrates, utilities do one thing well.

## What's Working Well
- Clear sequential pipeline structure
- Comprehensive preprocessing steps (all 10 steps implemented)
- Helper function modularity (7 focused utilities)
- Progress indication for long operations
- QC visualization capability
- **Three-tiered documentation system** (new)
- Clean separation: preprocessing vs analysis timing work

## Current Blockers
None - preprocessing pipeline and documentation are production-ready.

## Notes for Future Sessions
After memory reset, the refactoring task involves:
1. Converting script to function with flexible input handling
2. Removing `isub` indexing patterns
3. Adding input validation and error handling
4. Improving documentation of each preprocessing step
5. Maintaining all existing functionality
6. Preparing structure for parallel processing

The memory bank is now initialized and ready to guide implementation.
