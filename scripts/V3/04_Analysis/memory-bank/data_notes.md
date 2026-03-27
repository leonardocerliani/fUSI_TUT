# Data Notes

**Last Updated**: 2026-02-08

## Synthetic Data Specifications

### Overview
Starting with synthetic data to develop and validate the pipeline before working with real fUSI data.

---

## Synthetic fUSI Data Structure

### Dimensions
```python
# Proposed synthetic data dimensions
x = 50  # pixels
y = 50  # pixels
n_slices = 5  # brain slices
n_timepoints = 200  # temporal samples

# Shape: (50, 50, 5, 200)
```

### Temporal Parameters
```python
# fUSI typical acquisition parameters
TR = 0.5  # seconds (2 Hz acquisition - typical for fUSI)
# Compare to fMRI: TR typically 2-3 seconds

total_duration = n_timepoints * TR  # 100 seconds
```

### Spatial Resolution
- fUSI typically: 100-150 μm in-plane resolution
- For synthetic data: pixel size is arbitrary
- Focus on realistic ROI structure

---

## Synthetic ROI Atlas

### Design Principles
```python
# Simple ROI structure for initial testing
n_rois = 10  # Start with 10 ROIs per slice

# ROI properties:
# - Label 0: background
# - Labels 1-10: ROIs in slice 0
# - Labels 11-20: ROIs in slice 1
# - etc.

# ROI shapes:
# - Roughly circular/elliptical (realistic)
# - Non-overlapping within slice
# - Varying sizes (realistic)
```

### Implementation Notes
- Can use `scipy.ndimage.label` for connected components
- Or manually place circular ROIs with known centers
- Each ROI should have multiple voxels (e.g., 20-50 voxels each)

---

## Synthetic Signal Generation

### Ground Truth Model
```python
# For each ROI, generate signal:
# Y = β₁ * task_predictor + β₂ * drift + noise

# Task signal
beta_task = 2.0  # effect size (arbitrary units)
task_signal = beta_task * convolved_task_predictor

# Drift (slow fluctuations)
beta_drift = varies_by_roi
drift_signal = beta_drift * drift_regressor

# Noise
noise_level = 0.5  # relative to signal
noise = np.random.normal(0, noise_level, n_timepoints)

# Full signal
roi_signal = baseline + task_signal + drift_signal + noise
```

### Task Design for Synthetic Data
**Option 1: Block Design**
```python
# Simple ON-OFF blocks
# Example: 10 seconds ON, 10 seconds OFF, repeated
block_duration = 10  # seconds
n_blocks = 5
```

**Option 2: Event-Related Design**
```python
# Brief events with variable ISI
event_duration = 2  # seconds
n_events = 20
# Random or regular ISI
```

**Decision**: Start with block design (easier to validate)

### Signal-to-Noise Ratio
```python
# Define realistic SNR
signal_amplitude = 2.0
noise_std = 0.5
SNR = signal_amplitude / noise_std  # = 4.0

# Can vary SNR across ROIs to test robustness
```

---

## Real fUSI Data (Future)

### Expected Format
**To be determined based on actual data**

Likely formats:
1. MATLAB files (.mat)
2. NumPy arrays (.npy)
3. HDF5 files (.h5)
4. NIfTI files (.nii/.nii.gz) - if converted

### Expected Preprocessing
**To be determined**

Typical fUSI preprocessing may include:
- Motion correction
- Temporal filtering
- Spatial smoothing (?)
- Baseline correction
- Registration to atlas

### Data Collection Parameters
**To be filled in when working with real data**

- Subject/session information
- Acquisition parameters (TR, resolution, etc.)
- Task design details
- Number of runs/sessions

---

## Data Validation Checklist

### Synthetic Data
- [ ] Verify dimensions are correct
- [ ] Check that ROI labels are contiguous and unique
- [ ] Verify no overlapping ROIs
- [ ] Confirm signal has expected temporal structure
- [ ] Check SNR is realistic
- [ ] Verify HRF convolution produces expected shape

### Real Data (Future)
- [ ] Verify data loads correctly
- [ ] Check dimensions match expectations
- [ ] Identify and handle missing data
- [ ] Check for artifacts or outliers
- [ ] Verify alignment with ROI atlas
- [ ] Validate timing information

---

## Data Storage and Organization

### Synthetic Data Files
```
data/
├── synthetic/
│   ├── fusi_data_synthetic.npy      # (50, 50, 5, 200)
│   ├── roi_atlas_synthetic.npy       # (50, 50, 5)
│   ├── events_synthetic.csv          # task timing
│   └── metadata_synthetic.json       # TR, dimensions, etc.
```

### Real Data Files (Future)
```
data/
├── real/
│   ├── subject_01/
│   │   ├── run_01/
│   │   │   ├── fusi_data.???
│   │   │   ├── events.csv
│   │   │   └── metadata.json
│   └── roi_atlas.???
```

---

## Data Loading Functions

### Synthetic Data Loader
```python
def load_synthetic_data():
    """Load synthetic fUSI data and ROI atlas."""
    data = np.load('data/synthetic/fusi_data_synthetic.npy')
    atlas = np.load('data/synthetic/roi_atlas_synthetic.npy')
    events = pd.read_csv('data/synthetic/events_synthetic.csv')
    
    with open('data/synthetic/metadata_synthetic.json', 'r') as f:
        metadata = json.load(f)
    
    return {
        'data': data,
        'atlas': atlas,
        'events': events,
        'tr': metadata['tr'],
        'n_slices': metadata['n_slices']
    }
```

### Real Data Loader (Template)
```python
def load_real_data(subject_id, run_id):
    """Load real fUSI data - TBD based on actual format."""
    # To be implemented
    pass
```

---

## Data Quality Metrics

### Metrics to Track
1. **Temporal SNR (tSNR)**
   - Mean signal / temporal std
   - Computed per ROI
   
2. **Framewise Displacement** (if motion data available)
   - Track motion artifacts

3. **Signal Drift**
   - Linear or polynomial trend strength
   - Before and after detrending

4. **Noise Autocorrelation**
   - Check temporal structure in residuals
   - Informs prewhitening strategy

---

## Notes and Observations

### Synthetic Data
- Ground truth is known, making validation straightforward
- Can systematically vary parameters (SNR, effect size, etc.)
- Useful for testing edge cases

### Real Data (Future)
- Will add notes here as we learn about the data
- Expected challenges: noise characteristics, motion, drift

---

## References for fUSI Data

**To be added**: Links to papers describing fUSI data characteristics
- Typical SNR ranges
- Hemodynamic response properties
- Noise characteristics
