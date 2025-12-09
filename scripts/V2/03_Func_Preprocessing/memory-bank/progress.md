# Progress Tracking: fUSI Preprocessing Refactoring

## Overall Status
**Phase**: Initialization Complete
**Progress**: 0% of implementation (planning phase)
**Last Updated**: December 9, 2025

## What Works ✅

### Current Preprocessing Pipeline (Preprocessing_DEV.m)
All functionality is working and has been analyzed:

1. ✅ **Data Loading**
   - Loads functional scan (PDI.mat)
   - Loads anatomical scan (anatomic.mat)
   - Loads transformation matrix (Transformation.mat)
   - Loads Allen brain atlas

2. ✅ **Brain Mask Creation**
   - Transforms Allen atlas to subject space
   - Extracts functional slice
   - Creates binary mask from regions
   - Applies morphological dilation
   - Includes visualization for QC

3. ✅ **Motion Correction**
   - Rigid in-plane translation correction
   - Uses median reference
   - Per-frame registration with progress indication

4. ✅ **Outlier Rejection**
   - Voxelwise z-score thresholding (σ > 5)
   - NaN flagging and linear interpolation
   - Tracks rejection ratio for QC

5. ✅ **Signal Normalization**
   - Converts to percent signal change
   - Formula: (signal - mean) / mean × 100

6. ✅ **Temporal Resampling**
   - Resamples to 5Hz using resamplePDI function

7. ✅ **Highpass Filtering**
   - DCT-based filtering (order 5, cutoff 500)

8. ✅ **Spatial Smoothing**
   - Gaussian kernel (σ=1)
   - Applied frame-by-frame

9. ✅ **Data Saving**
   - Saves preprocessed PDI structure
   - Uses parsave for parallel safety

### Supporting Infrastructure
- ✅ Helper functions in src/ directory (all functional)
- ✅ Path management via Datapath_DEV.m (working but needs replacement)
- ✅ Sample data available for testing

## What's Left to Build 🔨

### Phase 1: Planning & Design (Current)
- [x] Initialize memory bank
- [x] Document current system
- [x] Analyze requirements
- [ ] Get user approval on approach
- [ ] Define function signature
- [ ] Plan input validation strategy
- [ ] Plan error handling approach
- [ ] Decide on visualization handling

### Phase 2: Core Refactoring
- [ ] Create new function file (e.g., preprocess_fusi.m)
- [ ] Implement input argument handling
  - [ ] Accept anatPath and funcPath as inputs
  - [ ] Add uigetdir fallback when args not provided
  - [ ] Validate paths exist
- [ ] Remove isub indexing
- [ ] Convert cell array path access to direct strings
- [ ] Add path management (addpath for src/)
- [ ] Implement atlas loading strategy
- [ ] Preserve all preprocessing steps

### Phase 3: Documentation & Enhancement
- [ ] Add comprehensive function header documentation
- [ ] Add inline comments explaining each preprocessing step
- [ ] Document input parameters
- [ ] Document output structure
- [ ] Add usage examples

### Phase 4: Validation & Testing
- [ ] Test with sample data (run-113409-anat, run-115047-func)
- [ ] Verify output matches current Preprocessing_DEV.m
- [ ] Test with uigetdir mode (no input args)
- [ ] Test with provided paths mode
- [ ] Verify all preprocessing steps produce same results

### Phase 5: Optional Enhancements
- [ ] Separate visualization into QC function
- [ ] Add options structure for configurable parameters
- [ ] Implement input validation and error handling
- [ ] Add QC metrics return value
- [ ] Create wrapper function for batch/parallel processing

## Known Issues 🐛
None currently - existing code is functional.

## Evolution of Decisions

### Initial State (Pre-Refactoring)
- **Architecture**: Script-based with Datapath_DEV.m lookup
- **Subject Handling**: Cell arrays with isub indexing (loop remnant)
- **Flexibility**: Limited - requires modifying Datapath_DEV.m
- **Reusability**: Low - not a callable function

### Target State (Post-Refactoring)
- **Architecture**: Function-based with direct path inputs
- **Subject Handling**: Single subject per call (parallel-ready)
- **Flexibility**: High - any paths can be provided or selected
- **Reusability**: High - callable from scripts or parallel workers

### Open Questions
1. Function return value: PDI structure, QC metrics, or nothing?
2. Visualization: Inside function, separate function, or remove?
3. Atlas loading: Inside function, parameter, or global?
4. Error handling: How verbose? Fail fast or continue?

## Next Milestone
**Target**: Develop detailed refactoring plan with user approval
**Deliverable**: Function signature design and implementation approach
**Blockers**: Awaiting user direction

## Notes
- All preprocessing functionality is preserved (no feature changes)
- Focus is on structure and usability improvements
- Sample data available in sample_data/ for testing
- Alternative pipeline code in Preprocessing_DEV.m shows ongoing methods research
