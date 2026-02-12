# GLM Notes

**Last Updated**: 2026-02-08

## General Linear Model (GLM) Overview

### Basic Equation
```
Y = X β + ε

Where:
- Y: observed signal (n_timepoints × 1)
- X: design matrix (n_timepoints × n_regressors)
- β: parameter estimates / betas (n_regressors × 1)
- ε: residuals / error term (n_timepoints × 1)
```

### Estimation
Ordinary Least Squares (OLS) solution:
```
β̂ = (X'X)⁻¹ X'Y
```

---

## FSL-style GLM Components

### 1. Task/Event Regressors
- **Event onsets and durations** → boxcar functions
- **Convolution with HRF** → expected BOLD/hemodynamic response
- Multiple task conditions → multiple regressors

### 2. Hemodynamic Response Function (HRF)

**Canonical HRF**:
- Models the stereotypical hemodynamic response
- Peak around 5-6 seconds post-stimulus
- Undershoot around 15 seconds
- Returns to baseline

**Common HRF models**:
- SPM canonical HRF (double gamma)
- Glover HRF
- FSL's gamma HRF (FLOBS)

**Temporal Derivatives** (optional):
- Captures variability in HRF timing
- Adds a derivative of the canonical HRF as additional regressor
- Increases model flexibility

### 3. Temporal Filtering / Drift Removal

**High-pass filtering**:
- Removes slow drifts (scanner drift, physiological)
- FSL default: 100s cutoff
- Implemented via discrete cosine transform (DCT) basis set

**Drift model options in nilearn**:
- `'cosine'`: DCT-based high-pass filter (recommended)
- `'polynomial'`: polynomial detrending
- `None`: no detrending

### 4. Nuisance Regressors

**Motion parameters**:
- 6 motion parameters (3 translation, 3 rotation)
- Sometimes derivatives and squares (24 parameters total)

**Physiological noise**:
- White matter signal
- CSF signal
- Global signal (controversial)

**For fUSI**:
- May not have motion correction
- Consider other sources of noise

---

## Contrasts

### Definition
A contrast is a linear combination of parameter estimates:
```
c'β

Where:
- c: contrast vector (n_regressors × 1)
- β: parameter estimates
```

### Common Contrasts

**Main effect of condition A**:
```python
# If condition A is the first regressor
c = [1, 0, 0, ...]  # All zeros except position of A
```

**Difference between conditions (A > B)**:
```python
c = [1, -1, 0, ...]  # +1 for A, -1 for B, 0 for others
```

**Average of conditions**:
```python
c = [0.5, 0.5, 0, ...]  # Average A and B
```

**F-contrasts** (multiple contrasts tested jointly):
- Test multiple hypotheses simultaneously
- More complex, not needed initially

---

## Statistical Inference

### T-statistics
```
t = c'β / SE(c'β)

Where:
SE(c'β) = √(σ² · c'(X'X)⁻¹c)
σ² = residual variance = Σ(residuals²) / (n - p)
n = number of timepoints
p = number of regressors
```

### Z-statistics
For large n, t-distribution approximates normal:
```
z ≈ t  (for large df)
```

Or exact conversion:
```python
from scipy.stats import t, norm
p_value = 2 * (1 - t.cdf(abs(t_stat), df))
z_score = norm.ppf(1 - p_value/2) * sign(t_stat)
```

### P-values
```python
from scipy.stats import t as t_dist
p = 2 * (1 - t_dist.cdf(abs(t_value), df))
```

---

## Model Diagnostics

### 1. Residual Plots
**Residuals vs Time**:
- Check for patterns (should be random)
- Systematic patterns indicate model misspecification
- Autocorrelation suggests temporal structure not captured

**Residuals vs Fitted Values**:
- Check for heteroscedasticity (non-constant variance)
- Should show no pattern

**Residual Histogram**:
- Check normality assumption
- Should be approximately Gaussian

### 2. Model Fit Quality

**R² (coefficient of determination)**:
```python
R² = 1 - (SS_residual / SS_total)
SS_residual = Σ(residuals²)
SS_total = Σ((Y - mean(Y))²)
```

**Adjusted R²**:
Accounts for number of regressors:
```python
R²_adj = 1 - ((1-R²) * (n-1) / (n-p-1))
```

### 3. Design Matrix Quality

**Condition Number**:
- Measures multicollinearity
- High condition number (>30) indicates problems
```python
cond_number = np.linalg.cond(X)
```

**Variance Inflation Factor (VIF)**:
- Quantifies collinearity for each regressor
- VIF > 10 indicates high collinearity

**Correlation Matrix**:
- Visualize correlations between regressors
- High correlations (>0.8) are problematic

---

## Temporal Filtering Considerations

### Why Filter?
- Scanner drift (slow signal changes)
- Physiological noise (breathing, heartbeat)
- Head motion effects

### High-pass Filtering
**Cutoff selection**:
- Should be longer than slowest task effect
- FSL default: 100s (0.01 Hz)
- For block designs with slow blocks: use longer cutoff

**Implementation**:
```python
# Via nilearn
design_matrix = make_first_level_design_matrix(
    frame_times=frame_times,
    events=events,
    hrf_model='spm',
    drift_model='cosine',
    high_pass=100  # cutoff in seconds
)
```

### Low-pass Filtering
- Less common in fMRI/fUSI GLM
- HRF convolution acts as implicit low-pass filter
- Explicit low-pass filtering can be done pre-processing

---

## Temporal Autocorrelation & Prewhitening

### The Problem
fMRI/fUSI data often has temporal autocorrelation:
- Residuals at time t are correlated with residuals at t-1
- Violates OLS assumption of independent errors
- Leads to invalid standard errors

### Solutions

**1. Pre-whitening (FSL approach)**:
- Estimate autocorrelation structure
- Transform data to remove autocorrelation
- Refit GLM on whitened data

**2. Sandwich estimator**:
- Adjust standard errors post-hoc
- Don't modify data or betas

**3. Ignore (if conservative)**:
- Standard errors may be underestimated
- More false positives

**For this project**:
- Start without prewhitening
- Examine residual autocorrelation
- Add prewhitening if needed

---

## Model Selection & Comparison

### Questions to Consider
1. Which HRF model? (canonical, Glover, derivatives?)
2. Which drift model? (cosine, polynomial?)
3. Which nuisance regressors to include?

### Criteria
- **Residual structure**: fewer patterns = better
- **Interpretability**: simpler models preferred
- **BIC/AIC**: penalize model complexity
- **Cross-validation**: out-of-sample prediction

---

## fUSI-Specific Considerations

### Differences from fMRI

**1. Temporal Resolution**:
- fUSI: 0.2-0.5s (2-5 Hz)
- fMRI: 2-3s (~0.5 Hz)
- **Implication**: May capture faster dynamics

**2. HRF Shape**:
- fUSI measures cerebral blood volume (CBV)
- BOLD measures blood oxygenation
- HRF shape may differ
- **Action**: Empirically validate HRF with real data

**3. Noise Characteristics**:
- Different sources of noise
- May have different autocorrelation structure
- **Action**: Examine residuals with real data

**4. Drift**:
- Faster acquisition may have different drift properties
- **Action**: Experiment with different drift models

---

## Validation with Synthetic Data

### Ground Truth Recovery
With synthetic data, we know true β values:

```python
# Generate with known beta
true_beta_task = 2.0

# Fit GLM
estimated_beta_task = fitted_betas[0]

# Check recovery
recovery_error = estimated_beta_task - true_beta_task
percent_error = 100 * recovery_error / true_beta_task

# Should be small (< 5% with good SNR)
```

### What to Check
- [ ] Betas recovered within expected error range
- [ ] Standard errors reasonable
- [ ] T-statistics/Z-scores make sense
- [ ] Residuals appear random (white noise)
- [ ] R² indicates good model fit

---

## Common Issues & Solutions

### Issue: Singular Design Matrix
**Symptom**: `LinAlgError` during inversion
**Causes**:
- Collinear regressors
- Constant regressor (no variance)
- Too many regressors for data length

**Solutions**:
- Remove correlated regressors
- Check for zero-variance regressors
- Reduce model complexity

### Issue: Poor Model Fit
**Symptom**: Low R², large residuals
**Causes**:
- Missing important predictors
- Wrong HRF model
- High noise level

**Solutions**:
- Add missing regressors
- Try different HRF
- Check data quality

### Issue: Residual Structure
**Symptom**: Patterns in residual plots
**Causes**:
- Temporal autocorrelation
- Missing slow drifts
- Unmodeled task effects

**Solutions**:
- Add prewhitening
- Adjust drift model
- Revise task regressors

---

## Reference Implementations

### FSL FEAT
- Gold standard for fMRI GLM
- Uses pre-whitening (FILM)
- Sophisticated drift removal
- Cluster correction for multiple comparisons

### SPM
- Alternative to FSL
- Different HRF parameterization
- Canonical + derivatives standard

### Nilearn
- Python implementation
- Closely follows SPM approach
- Good for our purposes

---

## Future Extensions

### Hierarchical Models
- Model multiple subjects
- Random effects analysis
- Population-level inference

### Non-parametric Statistics
- Permutation testing
- Bootstrap confidence intervals
- More robust to violations

### Regularization
- Ridge regression (L2)
- LASSO (L1)
- Useful with many regressors

---

## Key Takeaways

1. **GLM is flexible**: Can model various experimental designs
2. **Design matrix is critical**: Quality determines inference quality
3. **Diagnostics are essential**: Always check residuals and model fit
4. **fUSI may differ from fMRI**: Validate assumptions with real data
5. **Start simple**: Add complexity only when needed
