# Current Status - GLM Analysis Pipeline

**Last Updated**: 2026-02-12 12:44 PM

## What Was Accomplished Today

### Version 2.0 - Ultra-Simplified Architecture

We completely restructured the GLM analysis pipeline to be as simple and transparent as possible.

## Key Changes from Previous Version

### 1. Simplified glm() Function
- **Old**: `glm(Y, X, regressor_names)` 
- **New**: `glm(model_name, Y, X)` - takes model name, automatically adds intercept

### 2. New remap_betas() Function
- Converts betas from [p × V] back to [p × ny × nz] spatial format
- Uses bmask to place values in correct locations
- Non-brain voxels set to NaN

### 3. Streamlined Main Script
- No file dialog - loads prepPDI.mat directly
- Always creates both Y and Y_PC1_removed
- Minimal console output
- Two example models: M1 (stimulus), M2 (stationary stimulus)
- Clean structure: 2 lines per model (fit + remap)

### 4. Silent Helper Functions
Removed all verbose console output from:
- create_predictors.m
- prepare_data_matrix.m
- remove_PC1.m
- get_stationary_stim.m

## Current Implementation

### Main Script Structure
```matlab
% Load data
load('prepPDI.mat');

% Create predictors
[stim, wheel] = create_predictors(data);
TR = median(diff(data.time));

% Prepare data matrices
Y = prepare_data_matrix(data.PDI, data.bmask);
Y_PC1_removed = remove_PC1(Y);

% Fit models (2 lines each!)
all_results = struct();

res = glm('M1', Y, stim);
all_results.M1.betas = remap_betas(res.betas, data.bmask);

stim_stationary = get_stationary_stim(stim, wheel, 5.0);
res = glm('M2', Y, stim_stationary);
all_results.M2.betas = remap_betas(res.betas, data.bmask);
```

### Results Format
```matlab
all_results.M1.betas       % [2 x ny x nz] - predictor + intercept
all_results.M2.betas       % [2 x ny x nz] - predictor + intercept
```

## Functions Available

### Core Functions
1. `create_predictors(data)` - Creates stim & wheel predictors
2. `prepare_data_matrix(PDI, bmask)` - Reshapes to [T x V]
3. `glm(model_name, Y, X)` - Fits GLM (auto-adds intercept)
4. `remap_betas(betas, bmask)` - Maps back to [p x ny x nz]

### Transformation Functions
5. `hrf_conv(predictor, TR)` - Canonical HRF convolution
6. `get_stationary_stim(stim, wheel, threshold)` - Stationary periods
7. `remove_PC1(Y)` - Remove global signal

## Testing Status

- [x] All functions implemented
- [x] Console output minimized
- [x] Main script simplified
- [ ] Tested with real prepPDI.mat data
- [ ] Results validated

## Next Steps

### Immediate (Next Session)
1. **Test with real data** - Run do_analysis_methods_paper.m
2. **Verify results** - Check beta dimensions and values
3. **Add more models** as needed

### Future Enhancements Roadmap

#### High Priority
1. **Add Drift and Motion Parameters**
   - Include optional drift regressors (DCT basis)
   - Include motion parameters from preprocessing
   - Proposed syntax: `res = glm('M1', Y, stim, 'drift', true, 'motion', data.motionParams);`

2. **Expand Results Statistics**
   - Currently returns only betas
   - Add: R², η², Z-statistics, t-statistics, residuals, fitted values
   - Keep as optional to avoid memory issues with large datasets

3. **Explicit Predictor Naming**
   - Pass predictor names to glm()
   - Store names in results struct
   - Critical for complex models with many predictors
   - Proposed: `res = glm('M1', Y, [stim, wheel], 'names', {'stimulus', 'wheel'});`

#### Medium Priority
4. **Optimize Stationary Threshold**
   - Currently hardcoded at 5 cm/s
   - Investigate optimal threshold empirically
   - Consider ROC analysis or cross-validation

5. **Visualization Function**
   - Create `plot_betas(results)` function
   - Display all betas in subplots with predictor labels
   - Auto-adjust layout based on number of predictors

#### Low Priority (Automation)
6. **Command-Line Arguments**
   - Pass arguments to main script for batch processing
   - Proposed: `do_analysis_methods_paper('subject', '01', 'models', {'M1', 'M2'})`

7. **Subject Lookup Table**
   - Map subject IDs to prepPDI file paths
   - Create subjects.csv with ID → path mapping
   - Auto-find data files based on subject ID

## Files Modified Today

### New Files
- `src/remap_betas.m` - NEW

### Modified Files
- `src/glm.m` - Simplified signature with model_name
- `do_analysis_methods_paper.m` - Completely rewritten
- `src/create_predictors.m` - Removed console output
- `src/prepare_data_matrix.m` - Removed console output
- `src/remove_PC1.m` - Removed console output
- `src/get_stationary_stim.m` - Removed console output

### Documentation Updated
- `memory-bank/matlab_implementation.md` - Updated for v2
- `memory-bank/current_status.md` - THIS FILE

## Known Issues

None currently. Ready for testing.

## Notes for Future Development

### Possible Additional Models to Implement
```matlab
% M3: HRF'd stimulus
res = glm('M3', Y, hrf_conv(stim, TR));

% M4: Stimulus + wheel
res = glm('M4', Y, [stim, wheel]);

% M5: Full model with interaction
res = glm('M5', Y, [hrf_conv(stim, TR), wheel, hrf_conv(stim.*wheel, TR)]);

% M6: Stationary vs running (separate predictors)
stim_stat = get_stationary_stim(stim, wheel, 5.0);
stim_run = stim - stim_stat;
res = glm('M6', Y, [stim_stat, stim_run]);

% M7: With PC1 removed
res = glm('M7_PC1removed', Y_PC1_removed, stim);
```

### Potential Features to Add
- **Visualization**: Functions to display beta maps as heatmaps
- **ROI analysis**: Extract betas from specific brain regions
- **Contrasts**: Compare betas between conditions
- **Model comparison**: Compare R² across models
- **Save/Load**: Functions to save and load all_results

## Design Principles Maintained

1. **Simplicity** - Each model is 2 lines of code
2. **Transparency** - Clear what each model includes
3. **Flexibility** - Easy to add new models
4. **Minimal output** - Only essential information printed
5. **Spatial preservation** - Betas remapped to original 2D space

## Contact/Continuation

When resuming work:
1. Read this file first
2. Review `do_analysis_methods_paper.m` 
3. Check `memory-bank/matlab_implementation.md` for details
4. Test with prepPDI.mat
