# fUSI GLM Analysis Pipeline

**Version 2.0 - Ultra-Simplified Architecture**  
**Last Updated**: 2026-02-12

## Overview

A clean, transparent GLM analysis pipeline for fUSI data. Each model is defined in just 2 lines of code, making it easy to understand, modify, and extend.

## Core Philosophy

**"One line per model - super simple!"**

```matlab
res = glm('M1', Y, stim);
all_results.M1.betas = remap_betas(res.betas, data.bmask);
```

## Quick Start

1. Make sure `prepPDI.mat` is in the current directory
2. Run the main script:
   ```matlab
   do_analysis_methods_paper
   ```
3. Access results:
   ```matlab
   all_results.M1.betas  % [p x ny x nz] beta maps
   all_results.M2.betas  % [p x ny x nz] beta maps
   ```

## Important: Beta Map Organization

⚠️ **The intercept is ALWAYS the LAST beta** ⚠️

For any model with `p` predictors:
- `betas(1, :, :)` = first predictor
- `betas(2, :, :)` = second predictor
- `betas(p, :, :)` = p-th predictor
- `betas(end, :, :)` = **intercept (always last)**

Example:
```matlab
% Model with stimulus only
res = glm('M1', Y, stim);
% betas(1, :, :) = stimulus beta
% betas(2, :, :) = intercept

% Model with 3 predictors
res = glm('M2', Y, [stim, wheel, hrf_conv(stim.*wheel, TR)]);
% betas(1, :, :) = stimulus beta
% betas(2, :, :) = wheel beta
% betas(3, :, :) = interaction beta
% betas(4, :, :) = intercept (LAST!)
```

## Available Functions

### Core Functions

#### `create_predictors(data)`
Creates basic stimulus and wheel speed predictors from prepPDI data.
```matlab
[stim, wheel] = create_predictors(data);
```

#### `prepare_data_matrix(PDI, bmask)`
Reshapes 3D fUSI data to 2D matrix for GLM fitting.
```matlab
Y = prepare_data_matrix(data.PDI, data.bmask);  % [T x V]
```

#### `glm(model_name, Y, X)`
Fits GLM to all voxels. **Automatically adds intercept.**
```matlab
res = glm('M1', Y, stim);
% res.betas [p+1 x V] - includes intercept as last row
% res.model_name - 'M1'
```

#### `remap_betas(betas, bmask)`
Remaps betas from vector format to 2D spatial format.
```matlab
betas_2D = remap_betas(res.betas, data.bmask);  % [p x ny x nz]
```

### Transformation Functions

#### `hrf_conv(predictor, TR)`
Applies canonical HRF convolution (SPM double-gamma).
```matlab
stim_hrf = hrf_conv(stim, TR);
```

**HRF Parameters:**
- Peak response: ~6 seconds
- Undershoot: ~16 seconds
- Normalized to unit area

#### `get_stationary_stim(stim, wheel, threshold)`
Extracts stimulus during low wheel speed (default: 5 cm/s).
```matlab
stim_stationary = get_stationary_stim(stim, wheel, 5.0);
```

#### `remove_PC1(Y)`
Removes first principal component (global signal).
```matlab
Y_clean = remove_PC1(Y);
```

## Example Models

### Basic Models

```matlab
% MODEL 1: Stimulus only
res = glm('M1', Y, stim);
all_results.M1.betas = remap_betas(res.betas, data.bmask);

% MODEL 2: Stationary stimulus
stim_stat = get_stationary_stim(stim, wheel, 5.0);
res = glm('M2', Y, stim_stat);
all_results.M2.betas = remap_betas(res.betas, data.bmask);
```

### Advanced Models

```matlab
% Calculate TR
TR = median(diff(data.time));

% MODEL 3: HRF'd stimulus
res = glm('M3', Y, hrf_conv(stim, TR));
all_results.M3.betas = remap_betas(res.betas, data.bmask);

% MODEL 4: Stimulus + Wheel
res = glm('M4', Y, [stim, wheel]);
all_results.M4.betas = remap_betas(res.betas, data.bmask);

% MODEL 5: HRF'd with interaction
interaction_hrf = hrf_conv(stim .* wheel, TR);
res = glm('M5', Y, [hrf_conv(stim, TR), wheel, interaction_hrf]);
all_results.M5.betas = remap_betas(res.betas, data.bmask);

% MODEL 6: Stationary vs Running (separate)
stim_stat = get_stationary_stim(stim, wheel, 5.0);
stim_run = stim - stim_stat;
res = glm('M6', Y, [stim_stat, stim_run]);
all_results.M6.betas = remap_betas(res.betas, data.bmask);

% MODEL 7: With PC1 removed
res = glm('M7_PC1removed', Y_PC1_removed, stim);
all_results.M7_PC1removed.betas = remap_betas(res.betas, data.bmask);

% MODEL 8: Derivative of wheel speed
wheel_deriv = [0; diff(wheel)];
res = glm('M8', Y, [stim, wheel, wheel_deriv]);
all_results.M8.betas = remap_betas(res.betas, data.bmask);
```

## Pipeline Structure

### Main Script Flow

```matlab
% 1. Load data
load('prepPDI.mat');

% 2. Create predictors
[stim, wheel] = create_predictors(data);
TR = median(diff(data.time));

% 3. Prepare data matrices
Y = prepare_data_matrix(data.PDI, data.bmask);
Y_PC1_removed = remove_PC1(Y);  % Always created

% 4. Fit models (2 lines each!)
all_results = struct();

res = glm('M1', Y, stim);
all_results.M1.betas = remap_betas(res.betas, data.bmask);

% Add more models as needed...
```

### Results Structure

```matlab
all_results
├── M1
│   └── betas [2 x ny x nz]  % [stim, intercept]
├── M2
│   └── betas [2 x ny x nz]  % [stim_stationary, intercept]
└── M3
    └── betas [2 x ny x nz]  % [stim_hrf, intercept]
```

## File Organization

```
04_Analysis/
├── do_analysis_methods_paper.m    # Main analysis script
├── prepPDI.mat                    # Preprocessed data
├── README.md                      # This file
├── src/
│   ├── create_predictors.m        # Create stim & wheel
│   ├── prepare_data_matrix.m      # Reshape PDI to Y
│   ├── glm.m                      # Fit GLM
│   ├── remap_betas.m             # Remap to 2D space
│   ├── hrf_conv.m                # HRF convolution
│   ├── get_stationary_stim.m     # Stationary periods
│   └── remove_PC1.m              # Remove global signal
└── memory-bank/                   # Documentation
    ├── current_status.md          # Latest status
    └── matlab_implementation.md   # Technical details
```

## Tips & Tricks

### Quick Testing
```matlab
% Test a model without saving
res = glm('test', Y, hrf_conv(stim, TR));
mean(res.betas(1, :))  % Mean beta for predictor
```

### Accessing Specific Betas
```matlab
% Get stimulus beta (first predictor)
stim_beta = all_results.M1.betas(1, :, :);

% Get intercept (always last)
intercept = all_results.M1.betas(end, :, :);

% Visualize a beta map
imagesc(squeeze(all_results.M1.betas(1, :, :)));
colorbar;
title('Stimulus Beta Map');
```

### Combining Predictors
```matlab
% Z-score continuous predictors
wheel_z = zscore(wheel);

% Create interaction
interaction = stim .* wheel;

% Multiple predictors
res = glm('M_multi', Y, [stim, wheel_z, interaction]);
```

## Current Limitations

- Results contain only betas (no R², t-stats, etc.)
- No drift regressors or motion parameters
- No predictor names stored in results
- Manual model definition required

See "Future Enhancements" below for planned improvements.

## Future Enhancements

### High Priority

1. **Add Drift and Motion Parameters**
   - Include optional drift regressors (DCT basis)
   - Include motion parameters from preprocessing
   - Usage: `res = glm('M1', Y, stim, 'drift', true, 'motion', data.motionParams);`

2. **Expand Results Statistics**
   Currently returns only betas. Should add:
   - R² (coefficient of determination)
   - η² (partial eta-squared, effect size)
   - Z-statistics
   - t-statistics
   - Residuals
   - Fitted values
   
3. **Explicit Predictor Naming**
   - Pass predictor names to glm()
   - Store names in results
   - Critical for complex models
   - Usage: `res = glm('M1', Y, [stim, wheel], 'names', {'stimulus', 'wheel'});`
   - Results: `all_results.M1.predictor_names = {'stimulus', 'wheel', 'intercept'}`

### Medium Priority

4. **Optimize Stationary Threshold**
   - Currently hardcoded at 5 cm/s
   - Investigate optimal threshold empirically
   - Consider ROC analysis or cross-validation
   - Possibly make threshold data-dependent

5. **Visualization Function**
   - Create `plot_betas(results)` function
   - Display all betas in subplots with labels
   - Include predictor names and model info
   - Usage: `plot_betas(all_results.M3);`

### Low Priority (Automation)

6. **Command-Line Arguments**
   - Pass arguments to main script
   - Enable batch processing
   - Usage: `do_analysis_methods_paper('subject', '01', 'models', {'M1', 'M2'})`

7. **Subject Lookup Table**
   - Map subject IDs to prepPDI paths
   - Simplify multi-subject analysis
   - Create `subjects.csv` with ID → path mapping
   - Usage: `do_analysis_methods_paper('subject', '01')` finds path automatically

## Technical Notes

### GLM Implementation
- Uses MATLAB's backslash operator (`X \ Y`) for efficiency
- Vectorized across all voxels simultaneously
- Typical dataset (3652 timepoints × 14220 voxels): ~2-5 seconds per model

### HRF Model
SPM canonical double-gamma HRF:
```
hrf(t) = (t^a1 * exp(-t/b1)) / (b1^a1 * Γ(a1+1))
       - c * (t^a2 * exp(-t/b2)) / (b2^a2 * Γ(a2+1))

where:
  a1 = 6  (time to peak, seconds)
  b1 = 1  (dispersion)
  a2 = 16 (time to undershoot)
  b2 = 1  (dispersion)
  c = 1/6 (ratio undershoot/peak)
```

### Data Dimensions
- PDI: [ny × nz × T] spatial × time
- Y: [T × V] timepoints × brain voxels
- X: [T × p] design matrix (before intercept)
- betas: [p+1 × V] parameters (intercept is last)
- betas_2D: [p+1 × ny × nz] remapped to space

## Requirements

- MATLAB R2016b or later
- No special toolboxes required
- prepPDI.mat with required fields:
  - `PDI` [ny × nz × T]
  - `time` [1 × T]
  - `stimInfo` table
  - `wheelInfo` table
  - `bmask` [ny × nz]

## Troubleshooting

### Common Issues

**"Expected 'data' struct in prepPDI.mat"**
- Make sure your .mat file has a variable called `data`

**"TR (repetition time) must be provided"**
- Remember: `hrf_conv(stim, TR)` needs both arguments
- Calculate TR: `TR = median(diff(data.time));`

**"Dimension mismatch"**
- Make sure all predictors have same length as Y
- Check: `length(stim) == size(Y, 1)`

**"Out of memory"**
- For very large datasets, process in chunks
- Or use PC1-removed data (smaller)

## Contributing

Found a bug or have a suggestion? 
- Document in `memory-bank/current_status.md`
- Update this README
- Test thoroughly before committing

## Version History

- **v2.0** (2026-02-12): Ultra-simplified architecture, 2-line models
- **v1.0** (2026-02-08): Initial implementation

---

**Questions?** Check `memory-bank/current_status.md` for latest updates and `memory-bank/matlab_implementation.md` for technical details.
