# Next Steps

**Last Updated**: 2026-02-08

## Immediate Priorities

### 1. Set Up Development Environment
- [ ] Create requirements.txt or environment.yml with dependencies:
  - numpy, pandas
  - nilearn, nibabel
  - matplotlib, plotly
  - scipy, scikit-learn
  - jupyter
- [ ] Create initial Jupyter notebook structure

### 2. Create Synthetic Data Generator
- [ ] Define synthetic fUSI data parameters:
  - Dimensions: (x, y, slices, time)
  - Typical fUSI spatial resolution (~100-150 μm)
  - Temporal resolution (~2-5 Hz typical for fUSI)
- [ ] Create synthetic ROI atlas/label map
- [ ] Generate synthetic task/event timing
- [ ] Add realistic noise characteristics

### 3. Implement Phase 1 - Core Modeling
**Priority**: Get a minimal working GLM pipeline with synthetic data
- [ ] Load/prepare synthetic data
- [ ] Create simple event predictor
- [ ] Convolve with canonical HRF (using nilearn)
- [ ] Build basic design matrix
- [ ] Fit GLM on one ROI
- [ ] Verify parameter estimates make sense

## Short-term Goals (Next Session)
Focus on getting a working end-to-end pipeline with synthetic data, even if minimal.

## Questions to Address
- What TR (repetition time) should we use for synthetic data? (fUSI is typically faster than fMRI)
- How many ROIs should the synthetic atlas contain?
- What task design? (block design, event-related, or both?)

## Dependencies Needed
See technical_notes.md for specific nilearn functions we'll use.
