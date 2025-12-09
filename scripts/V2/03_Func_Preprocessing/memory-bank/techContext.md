# Technical Context: fUSI Preprocessing

## Technologies Used

### Primary Language
- **MATLAB**: Core processing environment
- **Version**: Not specified (should be recent for imregcorr, imgaussfilt functions)

### Required MATLAB Toolboxes
Based on functions used in the code:

1. **Image Processing Toolbox**
   - `imregcorr` - Image registration using correlation
   - `imwarp` - Image warping with geometric transformations
   - `imref2d` - 2D spatial reference object
   - `imgaussfilt` - Gaussian filtering
   - `imdilate` - Morphological dilation
   - `strel` - Structuring element creation

2. **Statistics and Machine Learning Toolbox**
   - `zscore` - Z-score standardization
   - Statistical operations

3. **Base MATLAB**
   - File I/O (`load`, `save`)
   - Array operations
   - Visualization (`figure`, `imagesc`, `tiledlayout`)

## Development Setup

### Directory Structure
```
03_Func_Preprocessing/
├── .clinerules              # Cline AI configuration
├── Preprocessing_DEV.m      # Main script (to be refactored)
├── Datapath_DEV.m          # Path definition function
├── do_preprocessing.m      # Empty placeholder
├── memory-bank/            # Project documentation
├── src/                    # Helper functions
│   ├── Atlas2Individual.m
│   ├── DCThighpass.m
│   ├── fillmissingTime.m
│   ├── parsave.m
│   ├── PDIfilter.m
│   └── resamplePDI.m
├── dependencies/           # External dependencies (not explored)
└── sample_data/           # Test/example data
    ├── Data_collection/   # Raw acquisition data
    └── Data_analysis/     # Processed data
```

### Data Organization
```
Data_analysis/
└── sub-{id}/
    └── ses-{date}/
        ├── run-{time}-anat/
        │   ├── anatomic.mat
        │   ├── anatomic_2_atlas.mat
        │   ├── anatomic_2_atlas.nii
        │   └── Transformation.mat
        └── run-{time}-func/
            └── PDI.mat
```

### Required External Data
- **allen_brain_atlas.mat**: Must be in working directory or path
  - Contains Allen Brain Atlas reference data
  - Structure with Region.Data field (3D labeled volume)

## Technical Constraints

### Memory Requirements
- **Large Arrays**: PDI.PDI is 3D array [Y, X, Time]
  - Typical size: ~100x100x1000+ timepoints
  - Memory footprint: Depends on acquisition parameters
- **Motion Correction**: Creates full copy of data (cPDI)
- **Processing**: Peak memory ~2-3x input data size

### Performance Considerations
- **Motion Correction**: Most time-intensive step
  - Per-frame registration (waitbar used for progress)
  - Can take several minutes for long acquisitions
- **Spatial Smoothing**: Frame-by-frame processing
- **Resampling**: Temporal interpolation across all voxels

### File I/O Constraints
- **Binary Files**: Large raw data files (fUS_block_PDI_float.bin)
  - Should NOT be read directly for analysis
  - Already converted to .mat format
- **CSV/TSV Files**: Behavioral/timing data
  - Can be large, read selectively if needed

## Dependencies

### Custom Functions (src/)
All functions must be in MATLAB path or src/ directory:

1. **Atlas2Individual.m**
   - Input: atlas, anatomic, Transf
   - Output: Subject-specific atlas structure
   - Critical for brain mask creation

2. **DCThighpass.m**
   - Input: data, order, cutoff
   - Output: Highpass filtered data
   - DCT-based detrending

3. **fillmissingTime.m**
   - Input: data (with NaN), method
   - Output: Interpolated data
   - Temporal interpolation along 3rd dimension

4. **parsave.m**
   - Input: filename, variable
   - Output: Saved .mat file
   - Enables parallel-safe saving

5. **resamplePDI.m**
   - Input: PDI structure, target frequency
   - Output: Resampled PDI structure
   - Handles temporal resampling

6. **PDIfilter.m** (optional)
   - Input: PDI, filter type
   - Output: Filtered PDI
   - Alternative filtering approach

### External Dependencies
- **dependencies/** directory (contents not yet explored)
- **Allen Brain Atlas**: External neuroscience resource
  - Must be downloaded/available separately
  - Standard reference for mouse brain anatomy

## Tool Usage Patterns

### MATLAB Path Management
```matlab
% Current approach (implicit)
% Functions in src/ must be in path

% Better approach for function:
addpath('src');  % Add helper functions to path
```

### File Loading Pattern
```matlab
% Current pattern
load([path filesep 'filename.mat']);

% Extracts all variables into workspace
% PDI, anatomic, Transf structures
```

### Saving Pattern
```matlab
% Uses parsave for parallel safety
parsave([path filesep 'prepPDI.mat'], PDI);
```

### Progress Indication
```matlab
% Waitbar for long operations
h = waitbar(0, 'Message...');
% ... processing in loop
waitbar(progress, h, sprintf('Frame %d of %d', k, n));
close(h);
```

### Visualization Pattern
```matlab
% Tiledlayout for multi-panel figures
figure('Position', [100 100 1200 900]);
t = tiledlayout(5,4, 'Padding', 'compact', 'TileSpacing', 'compact');
for i = 1:numSlices
    nexttile;
    imagesc(...);
end
```

## Development Workflow

### Current Workflow
1. Modify `Datapath_DEV.m` to set subject paths
2. Run `Preprocessing_DEV.m` as script
3. View figures for quality control
4. Check output in Data_analysis directory

### Target Workflow
1. Call preprocessing function with paths or let it prompt
2. Function processes single subject
3. Optional: Return QC metrics/figures
4. Scaled up: Call function in parallel for multiple subjects

## Technical Debt

### Current Issues
1. **Path Management**: Hardcoded in Datapath_DEV.m
2. **Script vs Function**: Not modular, can't be called programmatically
3. **Global State**: Uses `isub` variable unnecessarily
4. **Mixed Concerns**: Visualization mixed with processing
5. **Documentation**: Limited inline comments explaining steps

### Future Improvements
1. Convert to proper function with input arguments
2. Separate visualization into optional QC function
3. Add input validation and error handling
4. Consider returning QC metrics structure
5. Enable parallel processing framework
