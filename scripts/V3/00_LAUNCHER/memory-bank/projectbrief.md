# Project Brief: fUSI Pipeline CLI Launcher

## Purpose
Create a command-line interface (CLI) launcher that orchestrates the complete fUSI image reconstruction and analysis pipeline. The launcher provides a unified entry point for running different pipeline stages on specific experimental runs.

## Core Requirements

### 1. Run Selection
- Accept a run ID (e.g., `run-115047`) as input
- Look up run information from a CSV database (`fUSI_data_location.csv`)
- Construct appropriate file paths for both data collection and analysis directories

### 2. Pipeline Stage Management
The launcher manages three main pipeline stages:
- **Stage 02**: Functional Reconstruction (raw data → PDI.mat)
- **Stage 03**: Functional Preprocessing (PDI.mat → prepPDI.mat)
- **Stage 04**: Analysis (prepPDI.mat → analysis results)

### 3. File Availability Checking
For each pipeline stage, the launcher must:
- Check whether required input files exist
- Display checkbox status ([X] ready, [ ] not ready)
- Only allow execution of stages where dependencies are met

### 4. User Interface
Present a clear CLI menu showing:
```
run-115047
[X] functional reconstruction
[ ] functional preprocessing
[ ] analysis: MethodPaper

Which step do you want to run?
1 - Functional Reconstruction
2 - Functional Preprocessing
3 - Analysis: MethodPaper
0 - Exit
```

### 5. Execution
Execute the selected pipeline stage by calling the appropriate MATLAB function with correct paths.

## Design Principles

1. **Iterative Development**: Build step-by-step, testing each component
2. **Modular Architecture**: Separate functions for loading data, checking files, displaying menu
3. **Extensibility**: Easy to add new analysis types (04_Analysis_*)
4. **Clear Feedback**: Informative console output at each step
5. **Data Independence**: CSV-based configuration, not hardcoded paths

## Key Constraints

- Run ID format: Always `run-XXXXXX`
- CSV location: `000_LAUNCHER/fUSI_data_location.csv`
- Atlas location: `allen_brain_atlas/` (one level up from 000_LAUNCHER)
- Data structure: Follows Data_collection / Data_analysis convention

## Success Criteria

1. User can launch any pipeline stage by providing a run ID
2. File availability is automatically checked and displayed
3. Incorrect stages cannot be executed (missing dependencies)
4. New analysis types can be added without modifying core launcher logic
5. Clear error messages when run ID not found or files missing
