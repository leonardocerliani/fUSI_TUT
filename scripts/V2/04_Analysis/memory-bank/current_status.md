# Current Status - GLM Analysis Pipeline

**Last Updated**: 2026-02-13 3:20 PM

## ✅ Version 3.0 Complete - Full Statistics & Interactive Visualization

### Major Accomplishments Today (Feb 13)

#### 1. **Full Statistics Implementation**
Enhanced GLM to compute comprehensive statistics:
- ✅ **R²** - Model fit (variance explained)
- ✅ **η²** - Effect size per predictor (partial eta-squared)
- ✅ **Z-scores** - Standardized coefficients  
- ✅ **p-values** - Two-tailed significance tests
- ✅ Memory-optimized (residuals not stored)

#### 2. **Spatial Remapping Function**
Created `remap_glm_results()` to remap ALL statistics to spatial format:
- Converts betas, R², eta², Z, p from [T × V] to [ny × nz]
- Reuses existing `remap_betas()` function
- Clean, maintainable ~35 lines of code

#### 3. **Correlation Analysis**
Implemented `simple_corr()` for direct Pearson correlation:
- Computes correlation map (r)
- Computes effect size (eta² = r²)
- Spatially remapped output [ny × nz]
- Used for M1_corr and M2_corr

#### 4. **Paper-Accurate Stationary Selection**
Created `get_stationary_trials()` implementing exact paper method:
- **Trial-level filtering** (not frame-level)
- Uses original stimInfo (startTime, endTime) and wheelInfo data
- Criterion: "trials where wheel velocity exceeded 2 cm/s for < 200ms"
- Calculates cumulative movement duration per trial
- Keeps/discards entire trials
- Replaced old `get_stationary_stim()` in main analysis

#### 5. **Interactive Visualization**
Built `view_glm_results()` - interactive viewer for exploring results:
- **Left panel**: Multiple eta² maps (one per predictor)
- **Right panel**: Voxel timeseries + model fit + predictors
- **Click interaction**: Click first eta² map to explore voxels
- **Dynamic layout**: Adapts to number of predictors
- **Fixed plot sizes**: Consistent across all models
- Shows predictors as they appear in model (post-HRF)

### Complete Pipeline Features

```matlab
% Run full analysis
do_analysis_methods_paper

% Explore results interactively
view_glm_results(all_results, data, 'M1');
view_glm_results(all_results, data, 'M3');
view_glm_results(all_results, data, 'M3_PC1_removed');
```

## Current Implementation

### Three Core Models

**Model 1: Stimuli While Stationary**
```matlab
stim_stationary = get_stationary_trials(data, 20.0, 200);
M1_predictors = stim_stationary;
M1_labels = {'stim_stationary'};
glm_estimate = glm('M1', Y, M1_predictors, M1_labels);
all_results.M1 = remap_glm_results(glm_estimate, data.bmask);
all_results.M1.X = [M1_predictors, ones(T,1)];  % For viewer
```

**Model 2: All Stimuli (HRF)**
```matlab
M2_predictors = hrf_conv(stim, TR);
M2_labels = {'stim_hrf'};
glm_estimate = glm('M2', Y, M2_predictors, M2_labels);
all_results.M2 = remap_glm_results(glm_estimate, data.bmask);
all_results.M2.X = [M2_predictors, ones(T,1)];
```

**Model 3: Full Model**
```matlab
M3_predictors = [hrf_conv(stim, TR), wheel, hrf_conv(wheel, TR), hrf_conv(stim.*wheel, TR)];
M3_labels = {'stim_hrf', 'running', 'running_hrf', '(stim*running)_hrf'};
glm_estimate = glm('M3', Y, M3_predictors, M3_labels);
all_results.M3 = remap_glm_results(glm_estimate, data.bmask);
all_results.M3.X = [M3_predictors, ones(T,1)];
```

### Variations
Each model also computed with:
- **PC1 removal**: `M1_PC1_removed`, `M2_PC1_removed`, `M3_PC1_removed`
- **Correlation**: `M1_corr`, `M2_corr` (simple Pearson correlation)

### Results Structure

```matlab
all_results.M1:
  .betas              [2 × ny × nz]
  .R2                 [1 × ny × nz]
  .eta2               [2 × ny × nz]
  .Z                  [2 × ny × nz]
  .p                  [2 × ny × nz]
  .predictor_labels   {'stim_stationary', 'intercept'}
  .model_name         'M1'
  .X                  [T × 2]  % Design matrix for viewer

all_results.M3:
  .betas              [5 × ny × nz]
  .R2                 [1 × ny × nz]
  .eta2               [5 × ny × nz]
  .Z                  [5 × ny × nz]
  .p                  [5 × ny × nz]
  .predictor_labels   {'stim_hrf', 'running', 'running_hrf', '(stim*running)_hrf', 'intercept'}
  .model_name         'M3'
  .X                  [T × 5]

all_results.M1_corr:
  .r                  [ny × nz]  % Correlation
  .eta2               [ny × nz]  % Effect size (r²)
```

## Functions Available

### Analysis Functions
1. **`glm(model_name, Y, X, predictor_labels)`** - Full GLM with all statistics
2. **`remap_glm_results(glm_estimate, bmask)`** - Remap all stats to space
3. **`simple_corr(predictor, Y, bmask)`** - Pearson correlation + effect size

### Predictor Creation
4. **`create_predictors(data)`** - Frame-aligned stim & wheel
5. **`get_stationary_trials(data, speed_thresh, duration_thresh)`** - Paper method (trial-based)
6. **`get_stationary_stim(stim, wheel, threshold)`** - Legacy (frame-based)
7. **`hrf_conv(predictor, TR)`** - SPM canonical HRF convolution

### Data Preparation
8. **`prepare_data_matrix(PDI, bmask)`** - Reshape to [T × V]
9. **`remove_PC1(Y)`** - Global signal regression
10. **`remap_betas(betas, bmask)`** - Helper for spatial remapping

### Visualization
11. **`view_glm_results(all_results, data, model_name)`** - Interactive viewer

## Important Technical Notes

### 1. Wheel Speed Units
⚠️ **wheelInfo.wheelspeed is in mm/s, NOT cm/s**

Paper says "2 cm/s" but data is in mm/s:
```matlab
% Paper criterion: 2 cm/s
% Actual threshold: 20 mm/s (equivalent)
stim_stationary = get_stationary_trials(data, 20.0, 200);
```

**How we discovered this:**
- Initial threshold of 2.0 resulted in 0 valid trials
- wheelInfo summary: median=163, max=505
- Clearly not cm/s given those values
- Changed to 20.0 (mm/s equivalent) → reasonable trial selection

### 2. Design Matrix Storage
For viewer to work, must store design matrix `.X` in results:
```matlab
all_results.M1.X = [M1_predictors, ones(T,1)];
all_results.M1_PC1_removed.X = [M1_predictors, ones(T,1)];  // Required!
```

Without `.X`, viewer throws error: "Unrecognized field name 'X'"

### 3. Viewer Limitations
- **Works for**: GLM models (M1, M2, M3, and PC1-removed versions)
- **Doesn't work for**: Correlation results (M1_corr, M2_corr)
- For correlations, use `imagesc()` directly:
  ```matlab
  figure; imagesc(all_results.M1_corr.r); colorbar; title('Correlation');
  ```

### 4. Memory Optimization
Residuals NOT stored in GLM results:
- Would be [T × V] per model (~116 MB for typical dataset)
- All other statistics computed without storing residuals
- Residuals computation commented out in `glm.m`

## Files Created/Modified Today

### New Files
- ✅ `src/remap_glm_results.m` - Remap all statistics to space
- ✅ `src/simple_corr.m` - Correlation analysis
- ✅ `src/get_stationary_trials.m` - Paper-accurate trial selection
- ✅ `src/view_glm_results.m` - Interactive visualization

### Modified Files
- ✅ `src/glm.m` - Added R², eta², Z, p-values computation
- ✅ `do_analysis_methods_paper.m` - All 3 models + variations, stores .X fields
- ✅ `README.md` - Comprehensive v3.0 documentation
- ✅ `memory-bank/current_status.md` - THIS FILE

## Testing Status

- [x] All functions implemented
- [x] GLM with full statistics tested
- [x] Viewer tested with M1, M2, M3
- [x] Viewer tested with PC1-removed models
- [x] Paper method for stationary trials tested
- [x] Wheel speed units issue resolved (mm/s)
- [x] Correlation analysis tested
- [x] All documentation updated

## Known Issues & Solutions

### ✅ Resolved
1. **"Rank deficient" warning in M1**
   - Cause: No valid stationary trials (threshold too low)
   - Solution: Changed from 2.0 to 20.0 (mm/s not cm/s)

2. **"Unrecognized field name 'X'" in viewer**
   - Cause: PC1-removed models missing .X field
   - Solution: Store .X for all models including PC1-removed

3. **Viewer cramped plots in M3**
   - Cause: Relative subplot sizing
   - Solution: Switched to absolute positioning with fixed plot sizes

4. **Image upside down in viewer**
   - Cause: Y-axis flip with 'YDir','normal'
   - Solution: Removed flip, used axis square

### None Currently
All known issues resolved!

## Next Steps

### Immediate (For Next Session)

1. **Finalize Analysis**
   - Run full analysis on all subjects
   - Save results for each subject
   - Document any subject-specific issues

2. **Group-Level Analysis**
   - Combine results across subjects
   - Compute group averages
   - Statistical testing (t-tests, permutations)

3. **Publication Figures**
   - Create figures showing:
     - eta² maps for each model
     - Example voxel timeseries
     - Model comparison (R² across models)
     - Stationary vs all stimuli effects

### Future Enhancements

#### Optional Statistics
- **Contrasts**: Compare predictors within/across models
- **FWE correction**: Multiple comparison correction
- **Cluster analysis**: Find significant clusters

#### Additional Analyses  
- **ROI analysis**: Extract values from regions of interest
- **Searchlight**: Local pattern analysis
- **Connectivity**: Functional connectivity with seed regions

#### Automation
- **Multi-subject pipeline**: Batch process all subjects
- **Quality control**: Automated QC checks and reports
- **Results export**: Export to NIfTI or other formats

## Session Summary (Feb 13, 2026)

### Morning (11:05 AM)
- Added predictor labels to GLM function
- Simplified architecture (v2.1)

### Afternoon (12:00 - 3:20 PM)
- **Major expansion to v3.0**
- Implemented full statistics (R², eta², Z, p)
- Created remap_glm_results function
- Built interactive viewer with multiple eta² maps
- Implemented paper-accurate stationary trial selection
- Added simple correlation analysis
- Resolved wheel speed units issue (mm/s vs cm/s)
- Fixed all viewer issues
- Completed comprehensive documentation

**Result**: Fully functional analysis pipeline with statistics, visualization, and paper-accurate methods!

## Design Principles Maintained

1. **Simplicity** - Clear function signatures
2. **Completeness** - Full statistical output
3. **Efficiency** - Vectorized computations
4. **Memory-conscious** - Residuals not stored
5. **Spatial preservation** - All results remapped to 2D
6. **Interactivity** - Visual exploration of results
7. **Reproducibility** - Paper-accurate methods
8. **Documentation** - Comprehensive README and memory bank

## Contact/Continuation

When resuming work:
1. ✅ Read this file first (current_status.md)
2. ✅ Review README.md for complete documentation
3. ✅ Check do_analysis_methods_paper.m for current implementation
4. ✅ All functions tested and working
5. ✅ Ready for production analysis!

---

**Pipeline Status**: ✅ **PRODUCTION READY**

All core functionality implemented, tested, and documented. Ready for full analysis on all subjects and manuscript figure generation.
