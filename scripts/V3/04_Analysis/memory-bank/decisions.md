# Key Decisions

**Last Updated**: 2026-02-08

## Architectural Decisions

### Decision: Use Jupyter Notebook Instead of Web App Initially
**Date**: 2026-02-08  
**Status**: Confirmed

**Rationale**:
- Faster iteration and experimentation
- Direct access to intermediate results
- Easier to modify models and predictors on the fly
- Still allows interactive exploration via Plotly FigureWidget
- Can be promoted to Dash app later if needed

**Trade-offs**:
- Less polished UI initially
- Requires running notebook server
- But: fits better with exploratory research phase

---

### Decision: ROI-level Analysis (not voxel-wise)
**Date**: 2026-02-08  
**Status**: Confirmed per project plan

**Rationale**:
- fUSI data structure benefits from ROI aggregation
- Reduces computational burden
- Still provides slice-wise visualization
- More interpretable for typical fUSI applications

**Implementation**:
- Average signal within each ROI
- Fit GLM on averaged signal
- Project results back to voxel space for visualization

---

### Decision: Use Nilearn for GLM Implementation
**Date**: 2026-02-08  
**Status**: Confirmed

**Rationale**:
- Mature, well-tested GLM implementation
- FSL-style HRF models available
- Built-in design matrix utilities
- Good documentation and examples
- Active community

**Key Nilearn Components**:
- `nilearn.glm.first_level.make_first_level_design_matrix`
- `nilearn.glm.first_level.FirstLevelModel`
- HRF models (spm, glover, etc.)

---

### Decision: Start with Synthetic Data
**Date**: 2026-02-08  
**Status**: Confirmed

**Rationale**:
- Ground truth known for validation
- Easier to debug issues
- Can test edge cases
- Faster iteration without data loading overhead

**Plan**:
- Create simple synthetic data generator
- Include known signal + noise
- Verify GLM recovers known parameters
- Then move to real data

---

## Technical Decisions

### Decision: Use Plotly for Interactive Visualization
**Date**: 2026-02-08  
**Status**: Confirmed

**Rationale**:
- Works well in Jupyter notebooks
- FigureWidget supports callbacks without app framework
- Good interactivity (hover, click, zoom)
- Publication-quality outputs possible

**Alternative Considered**: matplotlib with mpl_connect
- Less interactive
- Harder to link multiple plots

---

## Data Structure Decisions

### Decision: fUSI Data Format
**Date**: 2026-02-08  
**Status**: To be determined based on real data

**Options**:
1. NIfTI format (4D: x, y, slice, time)
   - Pro: Standard format, nilearn compatible
   - Con: May need conversion from native fUSI format
2. NumPy arrays
   - Pro: Flexible, easy to work with
   - Con: No metadata, manual tracking needed
3. Custom format
   - Pro: Preserve fUSI-specific metadata
   - Con: More work to integrate with nilearn

**Current Plan**:
- Start with NumPy arrays for synthetic data
- Decide on real data format later

---

## To Be Decided

### HRF Model Choice
**Status**: To be decided

**Options**:
- Canonical HRF (SPM/FSL style)
- Glover HRF
- Custom HRF for fUSI hemodynamics?

**Notes**:
- fUSI may have different hemodynamic response than BOLD fMRI
- May need to explore empirically with real data
- Start with canonical, then adapt

### Prewhitening Strategy
**Status**: To be decided

**Notes**:
- fMRI typically has temporal autocorrelation
- Does fUSI have similar issues?
- Decide after examining real data residuals

### High-pass Filter Cutoff
**Status**: To be decided

**Notes**:
- fMRI typically uses 128s or 100s cutoff
- fUSI TR may be different
- Decide based on experimental design and TR
