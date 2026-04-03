# System Patterns: fUSI Pipeline CLI Launcher

## Architecture Overview

```
fusi_pipeline_launcher('run-115047')
    │
    ├─→ load_run_info(runID)
    │   ├─ Read fUSI_data_location.csv
    │   ├─ Find matching row
    │   └─ Construct all paths
    │
    ├─→ check_reconstruction_ready(runInfo)
    │   └─ Check Data_collection files
    │
    ├─→ check_preprocessing_ready(runInfo)
    │   ├─ Check functional Data_analysis files
    │   └─ Check anatomical Data_analysis files
    │
    ├─→ check_analysis_ready(runInfo)
    │   └─ Check prepPDI.mat exists
    │
    ├─→ display_status_menu(runID, status)
    │   ├─ Show checkboxes for each stage
    │   ├─ Get user selection
    │   └─ Validate selection
    │
    └─→ Execute selected stage
        ├─ Stage 02: do_reconstruct_functional(datapath, savepath)
        ├─ Stage 03: do_preprocessing(anatPath, funcPath, atlasPath)
        └─ Stage 04: do_analysis_*(prepPDI_path)
```

## Design Patterns

### 1. Data Structure Pattern
Each run is represented by a struct with all necessary paths:

```matlab
runInfo = struct(
    'experiment', 'MethodsPaper',
    'project_id', 'sub-methods02',
    'func_run', 'run-115047',
    'session_id', 'ses-231215',
    'anatomic_run', 'run-113409',
    'data_root', '/data03/fUSIMethodsPaper',
    'paths', struct(
        'func_collection', '...',
        'func_analysis', '...',
        'anat_collection', '...',
        'anat_analysis', '...',
        'atlas', '...'
    )
);
```

### 2. File Checking Pattern
Each stage checker returns a struct:

```matlab
status = struct(
    'ready', true/false,
    'missing_files', {...},  % List of missing files
    'message', 'Ready to run' or 'Missing: ...'
);
```

### 3. Menu Display Pattern
Status is aggregated and presented consistently:

```matlab
stages = {
    struct('name', 'Functional Reconstruction', 'ready', true, 'id', 1),
    struct('name', 'Functional Preprocessing', 'ready', false, 'id', 2),
    struct('name', 'Analysis: MethodPaper', 'ready', false, 'id', 3)
};
```

## Key Abstractions

### Path Construction
All path construction happens in `load_run_info.m`:
- Single source of truth for path patterns
- Easy to update if directory structure changes
- Consistent across all stages

### File Existence Checking
Pattern used in all checker functions:
```matlab
function status = check_files(basePath, requiredFiles)
    missing = {};
    for i = 1:length(requiredFiles)
        if ~exist(fullfile(basePath, requiredFiles{i}), 'file')
            missing{end+1} = requiredFiles{i};
        end
    end
    status.ready = isempty(missing);
    status.missing_files = missing;
end
```

### Wildcard Handling
For files like `TTL*.csv`:
```matlab
files = dir(fullfile(basePath, 'TTL*.csv'));
if isempty(files)
    % File missing
end
```

## Error Handling Strategy

### 1. Run Not Found
```matlab
if isempty(runInfo)
    error('Run ID "%s" not found in fUSI_data_location.csv', runID);
end
```

### 2. CSV File Missing
```matlab
csvPath = fullfile(pwd, 'fUSI_data_location.csv');
if ~exist(csvPath, 'file')
    error('CSV file not found: %s\nPlease create fUSI_data_location.csv', csvPath);
end
```

### 3. Invalid Stage Selection
```matlab
if selectedStage < 0 || selectedStage > numStages
    error('Invalid selection. Please choose 0-%d', numStages);
end
```

### 4. Dependencies Not Met
```matlab
if selectedStage == 2 && ~status.preprocessing.ready
    fprintf('\nCannot run preprocessing. Missing files:\n');
    for i = 1:length(status.preprocessing.missing_files)
        fprintf('  - %s\n', status.preprocessing.missing_files{i});
    end
    return;
end
```

## Extensibility Patterns

### Adding New Analysis Types
The system auto-detects analysis directories:

```matlab
% Find all 04_Analysis_* directories
analysisRoot = fullfile(pwd, '..');
analysisDirs = dir(fullfile(analysisRoot, '04_Analysis_*'));

% For each directory, create a stage
for i = 1:length(analysisDirs)
    analysisName = strrep(analysisDirs(i).name, '04_Analysis_', '');
    stages{end+1} = struct(...
        'name', ['Analysis: ' analysisName], ...
        'type', 'analysis', ...
        'dir', analysisDirs(i).name ...
    );
end
```

### CSV Evolution
If CSV columns change, only `load_run_info.m` needs updating. All other functions use the `runInfo` struct which provides a stable interface.

## Component Relationships

### Data Flow
```
CSV File → load_run_info → runInfo struct → Checker functions → Status structs → Menu display → Execution
```

### Dependencies
```
fusi_pipeline_launcher.m (main)
    ↓ calls
lib/load_run_info.m (CSV parsing)
    ↓ provides runInfo to
lib/check_*_ready.m (file checking)
    ↓ provides status to
lib/display_status_menu.m (UI)
    ↓ returns selection to
fusi_pipeline_launcher.m (execution)
```

## Separation of Concerns

1. **CSV Reading**: Only in `load_run_info.m`
2. **Path Construction**: Only in `load_run_info.m`
3. **File Checking**: Separate function per stage
4. **User Interface**: Only in `display_status_menu.m`
5. **Execution**: Only in main launcher
6. **Pipeline Logic**: In original stage scripts (02, 03, 04)

This separation makes the system:
- Easy to test (each component independently)
- Easy to maintain (changes isolated to specific files)
- Easy to extend (add new stages without modifying core logic)
