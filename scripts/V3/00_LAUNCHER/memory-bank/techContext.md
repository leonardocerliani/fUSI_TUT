# Technical Context: fUSI Pipeline CLI Launcher

## Technology Stack

### Language
- **MATLAB** (R2020a or later recommended)
- Standard MATLAB functions only (no special toolboxes required for launcher)

### File Formats
- **CSV**: Run database (comma-separated, UTF-8)
- **MAT**: MATLAB data files (binary)
- **JSON**: Configuration files (for reconstruction stage)

## Development Environment

### File Structure
```
000_LAUNCHER/
├── fusi_pipeline_launcher.m          # Main entry point
├── fUSI_data_location.csv            # Run database
├── lib/                               # Helper functions
│   ├── load_run_info.m
│   ├── check_reconstruction_ready.m
│   ├── check_preprocessing_ready.m
│   ├── check_analysis_ready.m
│   └── display_status_menu.m
└── memory-bank/                       # Documentation
```

### Dependencies

**MATLAB Path Requirements**:
The launcher automatically adds necessary paths:
```matlab
% Add lib directory to path
addpath(fullfile(pwd, 'lib'));

% Add pipeline stage directories when executing
addpath(fullfile(pwd, '..', '02_Func_Reconstruction'));
addpath(fullfile(pwd, '..', '03_Func_Preprocessing'));
```

**External Dependencies** (for pipeline stages, not launcher):
- Image Processing Toolbox (for preprocessing)
- Statistics Toolbox (for preprocessing)
- Custom utilities in `Utilities/` directory

## CSV File Specification

### Format
```csv
experiment,func_run,session_id,anatomic_run,data_root
MethodsPaper,run-115047,ses-231215,run-113409,/data03/fUSIMethodsPaper
```

### Rules
1. **Header row**: Must be present, exact column names required
2. **Encoding**: UTF-8
3. **Line endings**: Unix (LF) or Windows (CRLF) both supported
4. **No empty lines**: Between data rows
5. **No quotes**: Unless path contains commas (unlikely)

### Column Specifications

| Column | Format | Example | Required |
|--------|--------|---------|----------|
| experiment | String | MethodsPaper | Yes |
| func_run | run-XXXXXX | run-115047 | Yes |
| session_id | ses-XXXXXX | ses-231215 | Yes |
| anatomic_run | run-XXXXXX | run-113409 | Yes |
| data_root | Absolute path | /data03/fUSIMethodsPaper | Yes |

## Path Construction Details

### Platform Compatibility
The launcher uses `fullfile()` which automatically handles:
- Forward slashes on Unix/macOS
- Backslashes on Windows
- Path separator differences

### Path Templates
```matlab
% Functional Data Collection
fullfile(data_root, session_id, func_run, 'Data_collection')

% Functional Data Analysis
fullfile(data_root, session_id, func_run, 'Data_analysis')

% Anatomical Data Collection
fullfile(data_root, session_id, anatomic_run, 'Data_collection')

% Anatomical Data Analysis
fullfile(data_root, session_id, anatomic_run, 'Data_analysis')

% Atlas (relative to launcher location)
fullfile(pwd, '..', 'allen_brain_atlas')
```

## File Checking Implementation

### Basic File Check
```matlab
if exist(fullfile(basePath, filename), 'file')
    % File exists
end
```

### Wildcard Pattern Check
```matlab
files = dir(fullfile(basePath, 'TTL*.csv'));
if ~isempty(files)
    % At least one matching file exists
    ttlFile = files(1).name;  % Use first match
end
```

### Directory Check
```matlab
if exist(fullfile(basePath, 'FUSI_data'), 'dir')
    % Directory exists
end
```

### Alternative Files (OR logic)
```matlab
hasDAQ = exist(fullfile(basePath, 'DAQ.csv'), 'file') || ...
         exist(fullfile(basePath, 'NIDAQ.csv'), 'file');
```

## CSV Reading Implementation

### Using readtable
```matlab
csvPath = fullfile(pwd, 'fUSI_data_location.csv');
data = readtable(csvPath, 'Delimiter', ',');

% Find matching row
idx = strcmp(data.func_run, runID);
if any(idx)
    row = data(idx, :);
    runInfo.experiment = row.experiment{1};
    runInfo.func_run = row.func_run{1};
    % etc.
end
```

### Error Handling
```matlab
try
    data = readtable(csvPath);
catch ME
    error('Failed to read CSV file: %s\n%s', csvPath, ME.message);
end
```

## User Input Handling

### Menu Selection
```matlab
fprintf('\nWhich step do you want to run?\n');
for i = 1:length(stages)
    fprintf('%d - %s\n', i, stages{i}.name);
end
fprintf('0 - Exit\n\n');

choice = input('Enter your choice: ');

% Validate
if isempty(choice) || choice < 0 || choice > length(stages)
    error('Invalid choice');
end
```

## Integration Points

### Stage 02: Reconstruction
```matlab
% Function signature
PDI = do_reconstruct_functional(datapath, savepath)

% Launcher calls
datapath = runInfo.paths.func_collection;
savepath = runInfo.paths.func_analysis;
do_reconstruct_functional(datapath, savepath);
```

### Stage 03: Preprocessing
```matlab
% Function signature
do_preprocessing(anatPath, funcPath, atlasPath)

% Launcher calls
anatPath = runInfo.paths.anat_analysis;
funcPath = runInfo.paths.func_analysis;
atlasPath = runInfo.paths.atlas;
do_preprocessing(anatPath, funcPath, atlasPath);
```

### Stage 04: Analysis (Future)
```matlab
% Expected signature (to be determined)
do_analysis_MethodPaper(prepPDI_path)

% Launcher would call
prepPDI_path = fullfile(runInfo.paths.func_analysis, 'prepPDI.mat');
do_analysis_MethodPaper(prepPDI_path);
```

## Performance Considerations

### File Checking Speed
- File existence checks are fast (milliseconds)
- No need to load actual data during checking
- Directory listings cached by OS

### CSV Reading
- Small file (<1000 runs): negligible overhead
- Loaded once per launcher invocation
- No need for optimization

### Path Operations
- All path construction done upfront
- No repeated string operations
- Minimal memory footprint

## Testing Strategy

### Unit Testing (Manual)
1. Test CSV reading with various formats
2. Test path construction on different platforms
3. Test file checking with missing/present files
4. Test menu display and input validation

### Integration Testing
1. Test complete workflow: CSV → check → menu → execute
2. Test with actual data directories
3. Test error cases (missing files, invalid run ID)

### Edge Cases to Handle
- Run ID not in CSV
- CSV file malformed or missing
- Paths don't exist
- Partial file availability
- User cancels operation

## Error Messages

### Informative Errors
```matlab
error(['Run ID "%s" not found in CSV.\n' ...
       'Available runs: %s'], ...
       runID, strjoin(availableRuns, ', '));
```

### File-Specific Errors
```matlab
fprintf('Cannot run reconstruction. Missing files:\n');
for i = 1:length(missing)
    fprintf('  - %s\n', missing{i});
end
```

## Code Style Conventions

### Naming
- Functions: lowercase with underscores (`load_run_info`)
- Variables: camelCase (`runInfo`, `funcPath`)
- Constants: UPPERCASE (`CSV_FILENAME`)

### Comments
- Function headers with description and I/O specification
- Inline comments for complex logic
- Section headers for main code blocks

### Formatting
- 4-space indentation
- Maximum line length: 80 characters (flexible for readability)
- Blank lines between logical sections
