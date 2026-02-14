# fUSI GLM Analysis Pipeline

**Version 3.0 - Full Statistics & Interactive Visualization**  
**Last Updated**: 2026-02-13

## Overview

A complete GLM analysis pipeline for fUSI data with comprehensive statistics, interactive visualization, and paper-accurate methods. Supports multiple models with automatic computation of effect sizes, significance tests, and visual exploration.

## Quick Start

1. Make sure `prepPDI.mat` is in the current directory
2. Run the main analysis:
   ```matlab
   do_analysis_methods_paper
   ```
3. Explore results interactively:
   ```matlab
   view_glm_results(all_results, data, 'M1');
   view_glm_results(all_results, data, 'M3');
   ```

## Key Features

### ✅ Complete Statistics
- **Beta coefficients** - Parameter estimates
- **R²** - Model fit (variance explained)
- **η²** - Effect size per predictor
- **Z-scores** - Standardized coefficients
- **p-values** - Statistical significance (two-tailed)

### ✅ Interactive Visualization
- Click eta² maps to explore voxel timeseries
- See model fit overlaid on signal
- View all predictors (HRF-convolved as used in model)
- Multiple eta² maps for multi-predictor models

### ✅ Paper-Accurate Methods
- Trial-based stationary stimulus selection
- "Trials where wheel velocity exceeded 2 cm/s for < 200ms"
- Uses original high-resolution wheelInfo data

## Main Analysis Models

The pipeline fits 3 core models with variations:

### Model 1: Stimuli While Stationary
```matlab
stim_stationary = get_stationary_trials(data, 20.0, 200);
glm('M1', Y, stim_stationary);
```
- Only includes trials with minimal movement
- Paper criterion: wheel > 20 mm/s for < 200ms

### Model 2: All Stimuli (HRF)
```matlab
glm('M2', Y, hrf_conv(stim, TR));
```
- All stimulus trials
- HRF-convolved for hemodynamic response

### Model 3: Full Model
```matlab
glm('M3', Y, [hrf_conv(stim, TR), wheel, hrf_conv(wheel, TR), hrf_conv(stim.*wheel, TR)]);
```
- Stimulus (HRF)
- Running (raw)
- Running hemodynamic response (HRF)
- Interaction between stimulus and running (HRF)

### Variations
Each model also computed with:
- **PC1 removal** (`M1_PC1_removed`, etc.) - Global signal regression
- **Simple correlation** (`M1_corr`, `M2_corr`) - Direct Pearson correlation

## Core Functions

### GLM Analysis

#### `glm(model_name, Y, X, predictor_labels)`
Fits GLM with comprehensive statistics.

**Inputs:**
- `model_name` - string identifier (e.g., 'M1')
- `Y` - [T × V] data matrix
- `X` - [T × p] design matrix
- `predictor_labels` - {1 × p} cell array of predictor names

**Outputs (struct):**
- `.betas` - [p+1 × V] parameter estimates (intercept last)
- `.R2` - [1 × V] model fit (variance explained)
- `.eta2` - [p+1 × V] effect size per predictor
- `.Z` - [p+1 × V] z-scores
- `.p` - [p+1 × V] p-values (two-tailed)
- `.predictor_labels` - {1 × p+1} includes 'intercept'
- `.model_name` - string

**Example:**
```matlab
M1_predictors = stim_stationary;
M1_labels = {'stim_stationary'};
glm_estimate = glm('M1', Y, M1_predictors, M1_labels);
```

#### `remap_glm_results(glm_estimate, bmask)`
Remaps all GLM statistics to spatial format.

**Inputs:**
- `glm_estimate` - struct from glm()
- `bmask` - [ny × nz] brain mask

**Outputs (struct):**
- `.betas` - [p+1 × ny × nz]
- `.R2` - [1 × ny × nz]
- `.eta2` - [p+1 × ny × nz]
- `.Z` - [p+1 × ny × nz]
- `.p` - [p+1 × ny × nz]
- `.predictor_labels`, `.model_name`

**Example:**
```matlab
all_results.M1 = remap_glm_results(glm_estimate, data.bmask);
```

### Correlation Analysis

#### `simple_corr(predictor, Y, bmask)`
Computes Pearson correlation and effect size.

**Outputs (struct):**
- `.r` - [ny × nz] correlation map
- `.eta2` - [ny × nz] effect size (r²)

**Example:**
```matlab
all_results.M1_corr = simple_corr(stim_stationary, Y, data.bmask);
```

### Predictor Creation

#### `create_predictors(data)`
Creates frame-aligned stimulus and wheel speed predictors.

```matlab
[stim, wheel] = create_predictors(data);
```

#### `get_stationary_trials(data, speed_threshold, duration_threshold)`
**Paper method** for trial-based stationary selection.

**Inputs:**
- `data` - struct with stimInfo, wheelInfo
- `speed_threshold` - speed limit (default: 20 mm/s = 2 cm/s)
- `duration_threshold` - max movement duration (default: 200 ms)

**Outputs:**
- `stim_stationary` - [T × 1] stimulus during valid trials

**Example:**
```matlab
stim_stationary = get_stationary_trials(data, 20.0, 200);
```

**Method:**
- For each stimulus trial, calculate total duration where wheel > threshold
- Keep trial if movement duration < 200ms
- Discard trial otherwise

#### `hrf_conv(predictor, TR)`
Applies SPM canonical HRF (double-gamma).

```matlab
stim_hrf = hrf_conv(stim, TR);
```

### Data Preparation

#### `prepare_data_matrix(PDI, bmask)`
Reshapes 3D fUSI data to 2D matrix.

```matlab
Y = prepare_data_matrix(data.PDI, data.bmask);  % [T × V]
```

#### `remove_PC1(Y)`
Removes first principal component (global signal).

```matlab
Y_PC1_removed = remove_PC1(Y);
```

## Interactive Visualization

### `view_glm_results(all_results, data, model_name)`

Interactive viewer for exploring GLM results.

**Features:**
- **Left**: Multiple eta² maps (one per predictor)
- **Right Top**: Voxel signal vs model fit with R²
- **Right Bottom**: All predictors (normalized)
- **Interaction**: Click first eta² map to explore voxels

**Usage:**
```matlab
% View any GLM model
view_glm_results(all_results, data, 'M1');
view_glm_results(all_results, data, 'M2');
view_glm_results(all_results, data, 'M3');
view_glm_results(all_results, data, 'M3_PC1_removed');

% Correlation results (use imagesc instead)
figure; imagesc(all_results.M1_corr.r); colorbar; title('M1 Correlation');
figure; imagesc(all_results.M1_corr.eta2); colorbar; title('M1 Effect Size');
```

**What You See:**
- **M1**: 1 eta² map (stationary stimulus)
- **M2**: 1 eta² map (stimulus HRF)
- **M3**: 4 eta² maps (stimulus, running, running HRF, interaction)

**Interaction:**
1. Click on first eta² map (predictor of interest)
2. Top right shows: Raw signal (blue) + Model fit (red)
3. Bottom right shows: All predictors as they appear in model

## Results Structure

```matlab
all_results
├── M1                      % Stationary stimuli
│   ├── betas [2 × ny × nz]           % [stim_stationary, intercept]
│   ├── R2 [1 × ny × nz]
│   ├── eta2 [2 × ny × nz]
│   ├── Z [2 × ny × nz]
│   ├── p [2 × ny × nz]
│   ├── predictor_labels {'stim_stationary', 'intercept'}
│   ├── model_name 'M1'
│   └── X [T × 2]                     % Design matrix (for viewer)
│
├── M1_PC1_removed          % Same structure, PC1-removed data
├── M1_corr                 % Correlation analysis
│   ├── r [ny × nz]                   % Correlation map
│   └── eta2 [ny × nz]                % Effect size
│
├── M2                      % All stimuli (HRF)
│   └── ... (same structure as M1)
│
├── M2_PC1_removed
├── M2_corr
│
├── M3                      % Full model
│   ├── betas [5 × ny × nz]           % [stim_hrf, running, running_hrf, interaction_hrf, intercept]
│   ├── R2 [1 × ny × nz]
│   ├── eta2 [5 × ny × nz]
│   ├── Z [5 × ny × nz]
│   ├── p [5 × ny × nz]
│   ├── predictor_labels {'stim_hrf', 'running', 'running_hrf', '(stim*running)_hrf', 'intercept'}
│   ├── model_name 'M3'
│   └── X [T × 5]
│
└── M3_PC1_removed
```

## File Organization

```
04_Analysis/
├── do_analysis_methods_paper.m    # Main analysis script
├── prepPDI.mat                    # Preprocessed data
├── README.md                      # This file
├── src/
│   ├── create_predictors.m        # Frame-aligned predictors
│   ├── prepare_data_matrix.m      # Reshape PDI → Y matrix
│   ├── glm.m                      # Fit GLM with full statistics
│   ├── remap_glm_results.m        # Remap all stats to space
│   ├── remap_betas.m             # Helper for spatial remapping
│   ├── simple_corr.m             # Correlation analysis
│   ├── get_stationary_trials.m    # Paper method (trial-based)
│   ├── get_stationary_stim.m     # Legacy (frame-based)
│   ├── hrf_conv.m                # HRF convolution
│   ├── remove_PC1.m              # Global signal regression
│   └── view_glm_results.m        # Interactive viewer
└── memory-bank/                   # Documentation
    ├── current_status.md          # Project status
    └── ...
```

## Important Notes

### Beta Map Organization
⚠️ **The intercept is ALWAYS the LAST beta** ⚠️

```matlab
% M1 (1 predictor + intercept)
all_results.M1.betas(1, :, :)    % Stimulus beta
all_results.M1.betas(2, :, :)    % Intercept

% M3 (4 predictors + intercept)
all_results.M3.betas(1, :, :)    % Stimulus (HRF)
all_results.M3.betas(2, :, :)    % Running
all_results.M3.betas(3, :, :)    % Running (HRF)
all_results.M3.betas(4, :, :)    % Interaction (HRF)
all_results.M3.betas(5, :, :)    % Intercept (LAST)
```

### Wheel Speed Units
⚠️ **Wheel speed is in mm/s, not cm/s** ⚠️

The paper mentions "2 cm/s" but data is in mm/s:
```matlab
% Paper: 2 cm/s threshold
% Code: 20 mm/s threshold (equivalent)
stim_stationary = get_stationary_trials(data, 20.0, 200);
```

### Memory Optimization
Residuals are NOT stored (they're ~T × V × 8 bytes per model). All other statistics are computed but residuals are commented out in `glm.m` to save memory.

## Statistics Formulas

### R² (Model Fit)
```
R² = 1 - (SS_residual / SS_total)
```
Proportion of variance explained by the model.

### η² (Effect Size)
```
η² = SS_effect / (SS_effect + SS_residual)
```
Partial eta-squared for each predictor.

### Z-score
```
Z = beta / SE(beta)
SE(beta) = sqrt(diag(inv(X'X)) * sigma²)
sigma² = SS_residual / df
```

### P-value
```
p = 2 * (1 - Φ(|Z|))
```
Two-tailed test using normal approximation.

## Technical Details

### GLM Implementation
- Uses MATLAB backslash operator (`X \ Y`)
- Vectorized across all voxels
- Typical: ~2-5 seconds per model (3652 timepoints × 14220 voxels)

### HRF Model
SPM canonical double-gamma:
- Peak: ~6 seconds (a1=6, b1=1)
- Undershoot: ~16 seconds (a2=16, b2=1)
- Ratio: c = 1/6
- Normalized to unit area

### Data Dimensions
- PDI: [ny × nz × T]
- Y: [T × V] brain voxels × time
- X: [T × p] design matrix
- betas: [p+1 × V] or [p+1 × ny × nz]

## Requirements

- MATLAB R2016b or later
- No special toolboxes required
- prepPDI.mat with fields:
  - `PDI` [ny × nz × T]
  - `time` [1 × T]
  - `stimInfo` table (startTime, endTime)
  - `wheelInfo` table (time, wheelspeed in mm/s)
  - `bmask` [ny × nz]

## Troubleshooting

**"Unrecognized field name 'X'"**
- For PC1-removed models, ensure `.X` field is stored
- Add: `all_results.M1_PC1_removed.X = [M1_predictors, ones(T,1)];`

**"Rank deficient" warning**
- Occurs when no valid stationary trials found
- Check wheel speed threshold (should be 20 mm/s, not 2 mm/s)
- Verify wheelInfo.wheelspeed units

**"Valid trials: 0"**
- Units mismatch: Use 20 mm/s for 2 cm/s threshold
- Or threshold too low for your data

**Viewer doesn't work for correlation results**
- Use `imagesc()` directly for `M1_corr`, `M2_corr`
- Viewer only works for GLM models (M1, M2, M3, and PC1-removed versions)

## Version History

- **v3.0** (2026-02-13): Full statistics, interactive viewer, paper-accurate methods
- **v2.0** (2026-02-12): Ultra-simplified architecture
- **v1.0** (2026-02-08): Initial implementation

---

**Questions?** Check `memory-bank/current_status.md` for latest updates.
