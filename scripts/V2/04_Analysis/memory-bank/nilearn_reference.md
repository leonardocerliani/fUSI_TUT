# Nilearn Quick Reference

**Last Updated**: 2026-02-08

This document provides quick reference for key nilearn functions relevant to our fUSI GLM project.

---

## Design Matrix Creation

### `make_first_level_design_matrix`

**Purpose**: Create a design matrix for first-level GLM analysis.

**Location**: `nilearn.glm.first_level.make_first_level_design_matrix`

**Key Parameters**:
```python
from nilearn.glm.first_level import make_first_level_design_matrix

design_matrix = make_first_level_design_matrix(
    frame_times,           # Array of frame acquisition times (seconds)
    events=None,           # DataFrame with ['onset', 'duration', 'trial_type']
    hrf_model='glover',    # HRF model: 'spm', 'glover', 'spm + derivative', etc.
    drift_model='cosine',  # Drift model: 'cosine', 'polynomial', None
    high_pass=0.01,        # High-pass filter cutoff (Hz) or period (seconds if > 1)
    drift_order=1,         # Order for polynomial drift (if drift_model='polynomial')
    fir_delays=None,       # For FIR models
    add_regs=None,         # Additional regressors (n_scans × n_regs array)
    add_reg_names=None,    # Names for additional regressors
    min_onset=-24          # Minimum onset time (for HRF convolution)
)
```

**Returns**: `pandas.DataFrame` with shape (n_scans, n_regressors)

**Events DataFrame Format**:
```python
events = pd.DataFrame({
    'onset': [10.0, 30.0, 50.0],      # Event onset times (seconds)
    'duration': [2.0, 2.0, 2.0],      # Event durations (seconds)
    'trial_type': ['condA', 'condB', 'condA']  # Condition labels
})
```

**Example**:
```python
import pandas as pd
import numpy as np
from nilearn.glm.first_level import make_first_level_design_matrix

# Parameters
n_scans = 200
t_r = 0.5
frame_times = np.arange(n_scans) * t_r

# Events
events = pd.DataFrame({
    'onset': [10, 30, 50, 70],
    'duration': [2, 2, 2, 2],
    'trial_type': ['task', 'task', 'task', 'task']
})

# Create design matrix
design_matrix = make_first_level_design_matrix(
    frame_times=frame_times,
    events=events,
    hrf_model='spm',
    drift_model='cosine',
    high_pass=128  # 128 seconds cutoff
)

print(design_matrix.columns)  # ['task', 'drift_1', 'drift_2', ..., 'constant']
```

---

## HRF Models

### Available HRF Models

**Location**: `nilearn.glm.first_level`

**1. Canonical HRFs**:
```python
from nilearn.glm.first_level import spm_hrf, glover_hrf

# SPM canonical HRF
hrf_spm = spm_hrf(tr=0.5, oversampling=50)

# Glover HRF
hrf_glover = glover_hrf(tr=0.5, oversampling=50)
```

**2. HRF Models in `make_first_level_design_matrix`**:
- `'spm'`: SPM canonical HRF
- `'glover'`: Glover HRF
- `'spm + derivative'`: SPM HRF + temporal derivative
- `'glover + derivative'`: Glover HRF + temporal derivative
- `'spm + derivative + dispersion'`: SPM HRF + temporal and dispersion derivatives
- `'fir'`: Finite Impulse Response (flexible, data-driven)

**Parameters**:
```python
spm_hrf(
    tr,                    # Repetition time (seconds)
    oversampling=50,       # Temporal oversampling factor
    time_length=32.,       # HRF length (seconds)
    onset=0.              # Onset time (seconds)
)
```

**Example**:
```python
import matplotlib.pyplot as plt
from nilearn.glm.first_level import spm_hrf, glover_hrf

tr = 0.5
t = np.arange(0, 32, tr)

hrf_spm = spm_hrf(tr=tr, oversampling=1)
hrf_glover = glover_hrf(tr=tr, oversampling=1)

plt.plot(t, hrf_spm, label='SPM')
plt.plot(t, hrf_glover, label='Glover')
plt.legend()
plt.xlabel('Time (s)')
plt.ylabel('Response')
plt.title('HRF Models')
```

---

## FirstLevelModel

### `FirstLevelModel` Class

**Purpose**: High-level interface for first-level GLM analysis with neuroimaging data.

**Location**: `nilearn.glm.first_level.FirstLevelModel`

**Note**: For ROI-level analysis, manual GLM fitting may be simpler. This class is optimized for voxel-wise analysis with NIfTI images.

**Key Parameters**:
```python
from nilearn.glm.first_level import FirstLevelModel

fmri_glm = FirstLevelModel(
    t_r=None,                    # Repetition time (seconds)
    slice_time_ref=0.5,          # Slice timing reference
    hrf_model='glover',          # HRF model
    drift_model='cosine',        # Drift model
    high_pass=0.01,              # High-pass filter
    drift_order=1,               # Polynomial drift order
    fir_delays=None,             # FIR delays
    min_onset=-24,               # Minimum onset
    mask_img=None,               # Mask image
    target_affine=None,          # Target affine
    target_shape=None,           # Target shape
    smoothing_fwhm=None,         # Smoothing kernel FWHM
    memory=None,                 # Caching
    memory_level=1,              # Caching level
    standardize=False,           # Standardize data
    signal_scaling=0,            # Signal scaling
    noise_model='ar1',           # Noise model: 'ar1', 'ols'
    verbose=0,                   # Verbosity
    n_jobs=1,                    # Parallel jobs
    minimize_memory=True         # Memory optimization
)
```

**Key Methods**:
```python
# Fit model
fmri_glm.fit(run_imgs, events=events, confounds=confounds)

# Compute contrast
z_map = fmri_glm.compute_contrast('task', output_type='z_score')

# Get design matrices
design_matrices = fmri_glm.design_matrices_
```

---

## Contrast Computation

### Manual Contrast Computation

For ROI-level analysis, we'll likely compute contrasts manually:

```python
import numpy as np
from scipy.stats import t as t_dist, norm

def compute_contrast(betas, design_matrix, contrast_vector, residuals):
    """
    Compute contrast statistics.
    
    Parameters
    ----------
    betas : array, shape (n_regressors,)
        Parameter estimates
    design_matrix : array, shape (n_scans, n_regressors)
        Design matrix
    contrast_vector : array, shape (n_regressors,)
        Contrast weights
    residuals : array, shape (n_scans,)
        Model residuals
    
    Returns
    -------
    dict with keys:
        - effect: contrast effect size
        - variance: contrast variance
        - t_stat: t-statistic
        - z_stat: z-statistic (approximate)
        - p_value: two-tailed p-value
    """
    # Contrast effect
    effect = contrast_vector @ betas
    
    # Residual variance
    n_scans = len(residuals)
    n_regressors = len(betas)
    df = n_scans - n_regressors
    residual_var = np.sum(residuals**2) / df
    
    # Design matrix variance
    X = design_matrix
    design_var = np.linalg.inv(X.T @ X)
    
    # Contrast variance
    contrast_var = residual_var * (contrast_vector @ design_var @ contrast_vector)
    
    # Standard error
    se = np.sqrt(contrast_var)
    
    # T-statistic
    t_stat = effect / se
    
    # P-value
    p_value = 2 * (1 - t_dist.cdf(np.abs(t_stat), df))
    
    # Z-statistic (approximate for large df)
    z_stat = norm.ppf(1 - p_value/2) * np.sign(t_stat)
    
    return {
        'effect': effect,
        'variance': contrast_var,
        'se': se,
        't_stat': t_stat,
        'z_stat': z_stat,
        'p_value': p_value,
        'df': df
    }
```

---

## Plotting Utilities

### `plot_design_matrix`

**Purpose**: Visualize the design matrix.

**Location**: `nilearn.plotting.plot_design_matrix`

```python
from nilearn.plotting import plot_design_matrix

plot_design_matrix(
    design_matrix,        # Design matrix (DataFrame or array)
    rescale=True,        # Rescale regressors for visualization
    ax=None              # Matplotlib axes
)
```

**Example**:
```python
from nilearn.plotting import plot_design_matrix
import matplotlib.pyplot as plt

fig, ax = plt.subplots(figsize=(10, 6))
plot_design_matrix(design_matrix, ax=ax)
plt.tight_layout()
plt.show()
```

---

## Utility Functions

### Creating Frame Times

```python
def create_frame_times(n_scans, t_r, start_time=0):
    """Create array of frame acquisition times."""
    return start_time + np.arange(n_scans) * t_r
```

### Checking Design Matrix Quality

```python
def check_design_matrix(design_matrix):
    """
    Check design matrix for common issues.
    
    Returns dict with diagnostics.
    """
    X = design_matrix.values if hasattr(design_matrix, 'values') else design_matrix
    
    # Condition number
    cond_number = np.linalg.cond(X)
    
    # Correlation matrix
    corr_matrix = np.corrcoef(X.T)
    max_corr = np.max(np.abs(corr_matrix - np.eye(len(corr_matrix))))
    
    # Rank
    rank = np.linalg.matrix_rank(X)
    
    return {
        'condition_number': cond_number,
        'max_correlation': max_corr,
        'rank': rank,
        'n_regressors': X.shape[1],
        'n_scans': X.shape[0],
        'is_full_rank': rank == X.shape[1]
    }
```

---

## Common Patterns

### Pattern 1: Basic GLM Pipeline

```python
# 1. Create frame times
frame_times = np.arange(n_scans) * t_r

# 2. Create design matrix
design_matrix = make_first_level_design_matrix(
    frame_times=frame_times,
    events=events_df,
    hrf_model='spm',
    drift_model='cosine',
    high_pass=128
)

# 3. Fit GLM (manual)
from numpy.linalg import lstsq

X = design_matrix.values
y = roi_signal

betas, residuals_sum, rank, s = lstsq(X, y, rcond=None)
fitted = X @ betas
residuals = y - fitted

# 4. Compute statistics
n_scans = len(y)
n_regressors = len(betas)
df = n_scans - n_regressors

residual_var = np.sum(residuals**2) / df
design_var = np.linalg.inv(X.T @ X).diagonal()
se_betas = np.sqrt(residual_var * design_var)
t_values = betas / se_betas

# 5. Compute contrast
contrast = np.array([1, 0, 0, ...])  # First regressor
contrast_result = compute_contrast(betas, X, contrast, residuals)
```

### Pattern 2: Multiple ROIs

```python
# Initialize storage
roi_results = {}

# Extract ROI time series
for roi_id in roi_ids:
    roi_mask = (roi_atlas == roi_id)
    roi_signal = data_4d[roi_mask].mean(axis=0)
    
    # Fit GLM
    X = design_matrix.values
    betas, _, _, _ = lstsq(X, roi_signal, rcond=None)
    fitted = X @ betas
    residuals = roi_signal - fitted
    
    # Compute statistics
    # ... (as above)
    
    # Store results
    roi_results[roi_id] = {
        'signal': roi_signal,
        'betas': betas,
        'se_betas': se_betas,
        't_values': t_values,
        'fitted': fitted,
        'residuals': residuals
    }
```

### Pattern 3: Visualizing Design Matrix

```python
# Plot design matrix
from nilearn.plotting import plot_design_matrix
import matplotlib.pyplot as plt

fig, axes = plt.subplots(1, 2, figsize=(14, 6))

# Full design matrix
plot_design_matrix(design_matrix, ax=axes[0])
axes[0].set_title('Full Design Matrix')

# Correlation matrix
corr = design_matrix.corr()
im = axes[1].imshow(corr, cmap='RdBu_r', vmin=-1, vmax=1)
axes[1].set_title('Regressor Correlations')
plt.colorbar(im, ax=axes[1])

plt.tight_layout()
plt.show()
```

---

## Tips & Tricks

### High-pass Filter Period vs Frequency
```python
# Nilearn accepts either:
# 1. Frequency (Hz) if high_pass < 1
high_pass = 0.01  # 0.01 Hz

# 2. Period (seconds) if high_pass >= 1
high_pass = 100  # 100 seconds (equivalent to 0.01 Hz)
```

### Adding Custom Regressors
```python
# Create additional regressors (e.g., motion parameters)
motion_params = np.random.randn(n_scans, 6)  # 6 motion parameters

design_matrix = make_first_level_design_matrix(
    frame_times=frame_times,
    events=events,
    hrf_model='spm',
    drift_model='cosine',
    high_pass=128,
    add_regs=motion_params,
    add_reg_names=['tx', 'ty', 'tz', 'rx', 'ry', 'rz']
)
```

### Handling Edge Cases
```python
# Check for empty events
if events is None or len(events) == 0:
    # Create baseline design (just drift + constant)
    design_matrix = make_first_level_design_matrix(
        frame_times=frame_times,
        drift_model='cosine',
        high_pass=128
    )

# Check for constant regressors
for col in design_matrix.columns:
    if design_matrix[col].std() == 0:
        print(f"Warning: {col} has zero variance")
```

---

## Troubleshooting

### Issue: Singular Matrix Error
```python
# Check condition number
cond = np.linalg.cond(design_matrix.values)
if cond > 30:
    print(f"Warning: High condition number ({cond:.1f})")
    print("Design matrix may be ill-conditioned")
```

### Issue: NaN in Results
```python
# Check for NaN in inputs
assert not np.any(np.isnan(roi_signal)), "NaN in signal"
assert not np.any(np.isnan(design_matrix.values)), "NaN in design matrix"
```

### Issue: Very Large/Small Betas
```python
# Consider scaling regressors
X_scaled = (X - X.mean(axis=0)) / X.std(axis=0)
# But remember to use unscaled for interpretation!
```
