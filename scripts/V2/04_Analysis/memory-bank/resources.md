# Resources

**Last Updated**: 2026-02-08

## Official Documentation

### Nilearn
- **Main Documentation**: https://nilearn.github.io/stable/index.html
- **GLM Tutorial**: https://nilearn.github.io/stable/glm/index.html
- **First Level Model**: https://nilearn.github.io/stable/modules/generated/nilearn.glm.first_level.FirstLevelModel.html
- **Design Matrix**: https://nilearn.github.io/stable/modules/generated/nilearn.glm.first_level.make_first_level_design_matrix.html
- **Examples**: https://nilearn.github.io/stable/auto_examples/index.html#general-linear-model

### Plotly
- **Documentation**: https://plotly.com/python/
- **FigureWidget**: https://plotly.com/python/figurewidget/
- **Heatmaps**: https://plotly.com/python/heatmaps/
- **Callbacks**: https://plotly.com/python/interactive-html-export/

### NumPy & SciPy
- **NumPy Documentation**: https://numpy.org/doc/stable/
- **SciPy Stats**: https://docs.scipy.org/doc/scipy/reference/stats.html

### Pandas
- **Documentation**: https://pandas.pydata.org/docs/
- **DataFrames**: https://pandas.pydata.org/docs/reference/frame.html

---

## fMRI Analysis Resources

### FSL Documentation
- **FSL Main**: https://fsl.fmrib.ox.ac.uk/fsl/fslwiki
- **FEAT (fMRI Analysis)**: https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FEAT
- **GLM Theory**: https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/GLM

### Books & Courses

**"Handbook of Functional MRI Data Analysis" (Poldrack et al.)**
- Chapter on GLM
- Design matrix construction
- Statistical inference

**"Functional Magnetic Resonance Imaging" (Huettel et al.)**
- Comprehensive fMRI textbook
- Chapters on experimental design and analysis

**Dartmouth fMRI Course**
- Online lectures and materials
- Good introductory resource

---

## fUSI-Specific Resources

### Review Papers
**To be added**: Key papers on fUSI methodology
- Functional ultrasound imaging overview
- Comparison with fMRI
- Data acquisition and preprocessing

### Technical Papers
**To be added**: Papers on fUSI data analysis
- GLM applications to fUSI
- Hemodynamic response in fUSI
- Noise characteristics

---

## Python & Jupyter Resources

### Jupyter Notebooks
- **Documentation**: https://jupyter-notebook.readthedocs.io/
- **Widgets**: https://ipywidgets.readthedocs.io/
- **Best Practices**: Various blog posts on reproducible notebooks

### Python Best Practices
- **PEP 8**: Python style guide
- **Type Hints**: For code clarity
- **Docstrings**: NumPy/Google style

---

## Statistical Resources

### GLM & Linear Models
- **An Introduction to Statistical Learning** (James et al.)
  - Chapter 3: Linear Regression
  - Free PDF available online

- **The Elements of Statistical Learning** (Hastie et al.)
  - More advanced treatment
  - Free PDF available online

### Multiple Comparisons
- **False Discovery Rate (FDR)**
  - Benjamini-Hochberg procedure
  - Controls expected proportion of false positives

- **Family-Wise Error Rate (FWER)**
  - Bonferroni correction
  - More conservative than FDR

- **Cluster-based Inference**
  - Used in FSL/SPM
  - Random field theory

---

## Code Examples & Tutorials

### Nilearn GLM Examples
1. **Simple GLM Example**
   - https://nilearn.github.io/stable/auto_examples/04_glm_first_level/plot_first_level_model_details.html

2. **Design Matrix Visualization**
   - https://nilearn.github.io/stable/auto_examples/04_glm_first_level/plot_design_matrix.html

3. **Contrast Computation**
   - https://nilearn.github.io/stable/auto_examples/04_glm_first_level/plot_first_level_details.html

### Plotly Interactive Examples
1. **FigureWidget Tutorial**
   - Interactive plots in Jupyter
   - Callback examples

2. **Heatmap with Click Events**
   - Relevant for our ROI selection

---

## GitHub Repositories

### Nilearn
- **Repository**: https://github.com/nilearn/nilearn
- **Issues**: Check for known issues and solutions
- **Discussions**: Community Q&A

### Related Projects
**To be added**: Other fUSI analysis projects
- Similar analysis pipelines
- Synthetic data generators
- Visualization tools

---

## Papers to Read

### fUSI Methodology
- [ ] **Paper 1**: [Title TBD] - fUSI overview
- [ ] **Paper 2**: [Title TBD] - fUSI vs fMRI comparison
- [ ] **Paper 3**: [Title TBD] - fUSI hemodynamics

### GLM in Neuroimaging
- [ ] Friston et al. (1995) - Statistical parametric maps in functional imaging
- [ ] Worsley & Friston (1995) - Analysis of fMRI time-series revisited
- [ ] Lindquist (2008) - The statistical analysis of fMRI data

### HRF Modeling
- [ ] Glover (1999) - Deconvolution of impulse response in event-related BOLD fMRI
- [ ] Handwerker et al. (2004) - Variation of BOLD hemodynamic responses

---

## Tools & Software

### Development Tools
- **VS Code**: IDE with Jupyter support
- **Git**: Version control
- **Conda/Mamba**: Environment management

### Python Packages (Core)
```
numpy>=1.20
pandas>=1.3
scipy>=1.7
matplotlib>=3.4
plotly>=5.0
nilearn>=0.10
nibabel>=3.2
scikit-learn>=1.0
jupyter>=1.0
ipywidgets>=7.6
```

### Optional Packages
```
seaborn  # Additional plotting
pingouin # Statistical tests
statsmodels # Alternative GLM implementation
```

---

## Online Communities

### Forums & Q&A
- **Neurostars**: https://neurostars.org/ (neuroimaging Q&A)
- **Stack Overflow**: Python/scientific computing questions
- **Nilearn Discussions**: GitHub discussions

### Social Media
- **Twitter/X**: #fMRI, #neuroimaging, #Python
- **Mastodon**: Neuroscience communities

---

## Related Projects & Inspiration

### fMRI Analysis Tools
- **SPM**: MATLAB-based, industry standard
- **FSL**: C++-based, very popular
- **AFNI**: Another major fMRI tool
- **Nilearn**: Python, what we're using

### Interactive Neuroimaging Viewers
- **Papaya**: Web-based viewer
- **BrainBox**: Collaborative annotation
- **Nilearn Plotting**: Built-in visualization tools

---

## Datasets (for Future Reference)

### Public fMRI Datasets
- **OpenNeuro**: https://openneuro.org/
- **Human Connectome Project**
- **Various task fMRI datasets**

### fUSI Datasets
**To be added**: Publicly available fUSI datasets
- May be limited due to newness of technique
- Consider creating synthetic data repository

---

## Bookmarks & Quick Links

### Frequently Used
- [ ] Nilearn GLM documentation
- [ ] Plotly FigureWidget examples
- [ ] NumPy linear algebra functions
- [ ] Pandas DataFrame operations

### This Project
- [ ] Project GitHub repository (if applicable)
- [ ] Data storage location
- [ ] Results/figures directory

---

## Notes

### Useful Commands
```bash
# Create new conda environment
conda create -n fusi_glm python=3.9

# Install packages
pip install numpy pandas matplotlib plotly nilearn jupyter

# Launch Jupyter
jupyter notebook
```

### Keyboard Shortcuts (Jupyter)
- `Shift + Enter`: Run cell
- `Esc + A`: Insert cell above
- `Esc + B`: Insert cell below
- `Esc + D + D`: Delete cell
- `Esc + M`: Change to markdown
- `Esc + Y`: Change to code

---

## To Explore

- [ ] Nilearn plotting utilities for interactive plots
- [ ] Alternative GLM implementations (statsmodels)
- [ ] Advanced HRF modeling techniques
- [ ] Multi-subject analysis frameworks
- [ ] Bayesian approaches to GLM
