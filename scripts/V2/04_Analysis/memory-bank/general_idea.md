project_plan = """
# ROI-based fUSI GLM Exploration Project

## Goal
Build an exploratory, notebook-based workflow (no full app yet) to:
- preprocess fUSI data using fMRI-style concepts
- fit GLMs at the ROI level
- interactively explore results by clicking ROIs on slice-wise maps
- visualize model fits, parameters, and residuals

The design should stay flexible to allow rapid experimentation with:
- predictor construction
- HRF choices
- derivatives, drifts, and nuisance regressors
- alternative GLM formulations

---

## Phase 1 — Core Modeling (pure Python, no UI)

### 1. Data preparation
- Load fUSI data (3D/4D: x, y, slice, time)
- Load or define ROI atlas / label map
- For each ROI:
  - extract voxel time series
  - compute the average ROI signal

### 2. Predictor construction
- Write modular Python functions:
  - task/event predictors
  - HRF convolution
  - temporal derivatives (optional)
  - cosine drifts / high-pass components
  - nuisance regressors (if any)
- Keep predictors explicit and configurable

### 3. Design matrix creation
- Use Nilearn utilities where helpful:
  - `make_first_level_design_matrix`
  - HRF models, drift handling
- Store:
  - full design matrix
  - regressor names
  - contrasts (optional)

### 4. ROI-wise GLM fitting
- For each ROI:
  - fit GLM on averaged ROI signal
  - estimate:
    - betas (PEs)
    - residuals
    - fitted signal (full linear combination)
    - z-values (or t-values)
- Store results in a structured object (dict / DataFrame):
  - indexed by ROI ID

---

## Phase 2 — Map Generation

### 5. ROI-level statistical maps
- Project ROI-wise statistics back to voxel space:
  - all voxels in an ROI share the same value
- Generate:
  - z-maps (per contrast)
- Organize maps by slice

---

## Phase 3 — Interactive Notebook Visualization (no app framework)

### 6. Interactive slice viewer
- Use Plotly `FigureWidget`
- Display z-map as a heatmap
- Add:
  - slice selector (buttons or slider)
- Ensure slice index is tracked

### 7. ROI click interaction
- Attach `.on_click()` callback to the z-map figure
- On click:
  - determine clicked voxel
  - map voxel → ROI ID (slice-aware)
  - ignore background clicks

---

## Phase 4 — Linked Diagnostics (updated on ROI click)

### 8. Model fit visualization
- Separate `FigureWidget`:
  - plot raw ROI signal
  - overlay single fitted model curve
    - full linear combination of all predictors
- Optional:
  - plot individual predictor contributions (partial fits)

### 9. Residual diagnostics
- Plot residuals vs time (primary diagnostic)
- Optionally:
  - residual histogram
  - residuals vs fitted values

### 10. Parameter summaries
- Bar plot of beta estimates (per predictor)
- Table showing:
  - predictor name
  - beta (PE)
  - standard error
  - z-value
- Use Plotly tables or pandas display

---

## Phase 5 — Workflow Philosophy

### Design principles
- No Dash / Streamlit app initially
- Everything runs in:
  - Jupyter or Colab notebook
- Emphasis on:
  - flexibility
  - clarity
  - rapid iteration

### Why this approach
- Avoid premature UI complexity
- Easy to change models and predictors
- Direct access to intermediate results
- Interactive exploration still possible via Plotly

---

## Phase 6 — Future Extensions (optional)

- Add caching for heavy computations
- Add contrast selection UI
- Add ROI selection dropdown as alternative to clicking
- Convert notebook logic into:
  - Dash app (Shiny-like, explicit callbacks)
- Improve diagnostics:
  - autocorrelation of residuals
  - prewhitening strategies

---

## Final Outcome
A powerful, interactive, notebook-based ROI GLM exploration tool that:
- mirrors FSL-style modeling concepts
- is tailored to fUSI data
- remains flexible enough for methodological research
- can later be promoted to a full web app if needed
"""
