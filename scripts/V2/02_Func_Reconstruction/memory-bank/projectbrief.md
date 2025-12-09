# Project Brief: RAW_2_MAT Refactoring

> **Note**: This documentation reflects the refactoring work completed in `02_Functional_Reconstruction/` with sample data located in `sample_data/`. The main script is `do_reconstruct_functional.m` (which contains the `RAW_2_MAT()` function for backward compatibility).

## Project Overview
Refactor the monolithic RAW_2_MAT.m (493 lines) into a modular, configurable pipeline with per-experiment JSON configuration.

## Core Problems Being Solved
1. Hard-coded TTL channel assignments that vary per experiment
2. Hard-coded file patterns and threshold values
3. Monolithic structure with mixed responsibilities
4. Difficult to modify, extend, or reuse components
5. No transparency about what data is found/missing

## Solution Design

### Minimal Configuration Approach
- **Single config file per experiment**: `experiment_config.json` in data folder
- **Config contains only**: TTL channel assignments (the main variable)
- **Everything else auto-detected**: File presence, behavioral data availability
- **Clear terminal output**: Show what's configured, what's found, what's missing

### Modular Architecture
```
02_Functional_Reconstruction/
├── do_reconstruct_functional.m    - Main script (contains RAW_2_MAT function)
├── experiment_config_template.json - Configuration template
├── README.md                      - User documentation
└── src/
    ├── io/          - File loading (PDI, TTL, behavioral data)
    ├── processing/  - Signal processing (edge detection, frame reconciliation)
    ├── sync/        - Timeline synchronization and alignment
    ├── events/      - Stimulation event extraction
    ├── assembly/    - PDI structure building and saving
    └── utils/       - Config parsing, path generation, printing
```

### Key Features
1. Config file travels with experimental data
2. Helpful error if config missing (shows template in terminal)
3. Terminal output with ✓/✗ indicators for found/missing data
4. Auto-detection of stimulation types and behavioral data
5. Graceful degradation for optional data

## Success Criteria
- User can run: `PDI = RAW_2_MAT()` (or `do_reconstruct_functional()`) and select data folder
- Script loads per-experiment config for TTL channels
- Clear terminal feedback about data found/missing
- Output PDI.mat matches original script's format
- Easy to modify channel assignments without code changes

## Sample Data Location
Sample data for testing is located at:
```
sample_data/
└── Data_collection/
    └── run-115047-func/
        ├── experiment_config.json
        ├── DAQ.csv, TTL*.csv
        ├── VisualStimulation.csv
        ├── RunningWheel.csv, GSensor.csv
        └── FUSI_data/
```

Output will be saved to:
```
sample_data/Data_analysis/run-115047-func/PDI.mat
```
