# Technical Notes

**Last Updated**: 2026-02-08

## General Implementation Notes

### Python Environment Setup
```python
# Key dependencies
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import plotly.graph_objects as go
from plotly.subplots import make_subplots

# Nilearn for GLM
from nilearn.glm.first_level import make_first_level_design_matrix, FirstLevelModel
from nilearn.glm import compute_contrast

# For HRF modeling
from nilearn.glm.first_level import spm_hrf, glover_hrf
```

---

## Design Matrix Creation

### Key Nilearn Function
`make_first_level_design_matrix` is the core function for building design matrices.

**Parameters to consider**:
- `frame_times`: Array of frame acquisition times (in seconds)
- `events`: DataFrame with columns ['onset', 'duration', 'trial_type']
- `hrf_model`: 'spm', 'glover', 'spm + derivative', etc.
- `drift_model`: 'cosine', 'polynomial', None
- `high_pass`: High-pass filter cutoff (in seconds)
- `add_regs`: Additional regressors (nuisance, motion, etc.)
- `add_reg_names`: Names for additional regressors

**Example**:
```python
design_matrix = make_first_level_design_matrix(
    frame_times=frame_times,
    events=events_df,
    hrf_model='spm',
    drift_model='cosine',
    high_pass=128
)
```

---

## GLM Fitting

### Approach 1: Using FirstLevelModel
```python
# For compatibility with nilearn's FirstLevelModel
# Need to convert ROI time series to pseudo-nifti format
# OR use manual GLM fitting (see Approach 2)

fmri_glm = FirstLevelModel(
    t_r=t_r,
    hrf_model='spm',
    drift_model='cosine',
    high_pass=128
)
```

### Approach 2: Manual GLM Fitting (Likely Better for ROI-level)
Since we're fitting at ROI level, direct least squares may be simpler:

```python
from numpy.linalg import lstsq

# For each ROI
roi_signal = roi_timeseries[roi_id]  # Shape: (n_timepoints,)
X = design_matrix.values  # Shape: (n_timepoints, n_regressors)

# Fit GLM using ordinary least squares
betas, residuals, rank, s = lstsq(X, roi_signal, rcond=None)

# Fitted signal
fitted = X @ betas

# Residuals
resids = roi_signal - fitted

# Standard errors and statistics
residual_variance = np.sum(resids**2) / (len(roi_signal) - len(betas))
design_variance = np.linalg.inv(X.T @ X).diagonal()
se_betas = np.sqrt(residual_variance * design_variance)
t_values = betas / se_betas

# Z-values (approximate for large n)
from scipy.stats import t as t_dist
df = len(roi_signal) - len(betas)
p_values = 2 * (1 - t_dist.cdf(np.abs(t_values), df))
z_values = norm.ppf(1 - p_values/2) * np.sign(t_values)
```

---

## Contrasts

### Defining Contrasts
Contrasts are linear combinations of beta estimates.

**Example contrasts**:
```python
# Simple effect of condition A
contrast_A = np.array([1, 0, 0, ...])  # 1 for A, 0 for others

# A > B
contrast_A_vs_B = np.array([1, -1, 0, ...])

# Average of A and B
contrast_avg = np.array([0.5, 0.5, 0, ...])
```

**Computing contrast**:
```python
contrast_value = contrast @ betas
contrast_se = np.sqrt((contrast @ design_variance) * residual_variance)
contrast_t = contrast_value / contrast_se
```

---

## Plotly Interactive Figures

### FigureWidget for Interactivity
```python
# Create figure
fig = go.FigureWidget()

# Add heatmap for z-map
fig.add_trace(go.Heatmap(
    z=z_map,
    colorscale='RdBu_r',
    zmid=0
))

# Add click callback
def on_click(trace, points, state):
    if len(points.point_inds) > 0:
        x = points.xs[0]
        y = points.ys[0]
        # Determine ROI from coordinates
        roi_id = roi_atlas[int(y), int(x)]
        # Update diagnostic plots
        update_diagnostics(roi_id)

fig.data[0].on_click(on_click)
```

### Linking Multiple Plots
Keep references to multiple FigureWidgets and update them in callbacks:
```python
# Global or class-level storage
plot_refs = {
    'z_map': fig_zmap,
    'timeseries': fig_ts,
    'residuals': fig_resid,
    'betas': fig_betas
}

def update_diagnostics(roi_id):
    # Update each plot
    plot_refs['timeseries'].data[0].y = roi_results[roi_id]['signal']
    plot_refs['timeseries'].data[1].y = roi_results[roi_id]['fitted']
    # ... etc
```

---

## Data Structure for Results

### Recommended Structure
Store results in nested dictionaries or pandas DataFrames:

```python
# Dictionary approach
roi_results = {}
for roi_id in roi_ids:
    roi_results[roi_id] = {
        'betas': betas,
        'se_betas': se_betas,
        't_values': t_values,
        'z_values': z_values,
        'signal': roi_signal,
        'fitted': fitted_signal,
        'residuals': residuals,
        'contrast_values': {
            'contrast_A': value,
            'contrast_B': value,
        }
    }

# DataFrame approach (for parameter estimates)
results_df = pd.DataFrame({
    'roi_id': [],
    'regressor': [],
    'beta': [],
    'se': [],
    't_value': [],
    'z_value': [],
})
```

---

## Slice-wise Visualization

### Organizing Data by Slice
```python
# ROI atlas: (x, y, slice)
# Results: indexed by ROI ID

# For a given slice
slice_idx = 5
slice_roi_map = roi_atlas[:, :, slice_idx]

# Create z-map for this slice
z_map_slice = np.zeros_like(slice_roi_map, dtype=float)
for roi_id in np.unique(slice_roi_map):
    if roi_id == 0:  # Background
        continue
    mask = slice_roi_map == roi_id
    z_map_slice[mask] = roi_results[roi_id]['contrast_values']['main_effect']
```

---

## Performance Considerations

### Caching Heavy Computations
- Design matrix creation: once per analysis
- GLM fitting: once per ROI (store results)
- Map generation: once per slice per contrast (store results)

### When to Recompute
- New events/predictors → rebuild design matrix
- New design matrix → refit all GLMs
- New contrast → recompute contrast values (fast, don't need to refit)

---

## Error Handling

### Common Issues
1. **Singular design matrix**: Check for collinear regressors
2. **Mismatched dimensions**: Verify frame_times matches data length
3. **Missing ROI labels**: Handle background (label=0) appropriately
4. **Numerical instability**: Consider scaling/normalizing predictors

---

## Testing Strategy

### Unit Tests
- Test design matrix creation with known inputs
- Test GLM fitting with synthetic data (known betas)
- Test contrast computation

### Integration Tests
- Full pipeline with synthetic data
- Verify recovered parameters match ground truth

---

## Useful Code Snippets

### Extract ROI Time Series
```python
def extract_roi_timeseries(data_4d, roi_atlas):
    """
    Extract average time series for each ROI.
    
    Parameters
    ----------
    data_4d : ndarray, shape (x, y, slice, time)
    roi_atlas : ndarray, shape (x, y, slice)
    
    Returns
    -------
    roi_ts : dict
        roi_id -> timeseries array (n_timepoints,)
    """
    roi_ts = {}
    roi_ids = np.unique(roi_atlas)
    roi_ids = roi_ids[roi_ids != 0]  # Exclude background
    
    for roi_id in roi_ids:
        mask = roi_atlas == roi_id
        # Average across voxels in ROI
        roi_ts[roi_id] = data_4d[mask].mean(axis=0)
    
    return roi_ts
```

### Generate Frame Times
```python
def generate_frame_times(n_scans, t_r):
    """Generate frame acquisition times."""
    return np.arange(n_scans) * t_r
```

---

## Notes on fUSI vs fMRI

### Key Differences
1. **Temporal Resolution**: fUSI can be much faster (2-5 Hz) vs fMRI (~0.5 Hz)
2. **Spatial Coverage**: fUSI typically covers fewer slices but higher resolution
3. **Hemodynamics**: May differ from BOLD, needs empirical validation
4. **SNR**: Different noise characteristics

### Implications for GLM
- May need different drift models (faster oscillations?)
- HRF shape may differ
- Autocorrelation structure may differ (affects prewhitening)

These are hypotheses to test with real data.
