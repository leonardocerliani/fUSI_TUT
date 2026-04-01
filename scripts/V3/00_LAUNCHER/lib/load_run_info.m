function runInfo = load_run_info(runID, csvFilename)
% LOAD_RUN_INFO - Load run information from CSV and construct all paths
%
% Usage:
%   runInfo = load_run_info('run-115047', 'fUSI_data_location_LOCAL.csv')
%
% Description:
%   Reads the specified CSV file, finds the matching run, and constructs
%   all necessary paths for data collection and analysis directories.
%
% Inputs:
%   runID       - Run identifier (e.g., 'run-115047') [REQUIRED]
%   csvFilename - Name of CSV file to use (e.g., 'fUSI_data_location_LOCAL.csv') [REQUIRED]
%                 This should be passed from fusi_pipeline_launcher.m
%
% Output:
%   runInfo - Struct with fields:
%       .experiment    - Experiment name
%       .func_run      - Functional run ID
%       .session_id    - Session ID
%       .anatomic_run  - Anatomical run ID
%       .data_root     - Root data directory
%       .paths         - Struct with all constructed paths:
%           .func_collection   - Functional data collection directory
%           .func_analysis     - Functional data analysis directory
%           .anat_collection   - Anatomical data collection directory
%           .anat_analysis     - Anatomical data analysis directory
%           .atlas             - Atlas directory
%
% Example:
%   runInfo = load_run_info('run-115047', 'fUSI_data_location_STORM.csv')

% Validate inputs
if nargin < 2 || isempty(csvFilename)
    error('load_run_info:MissingCSVFilename', ...
        'CSV filename must be provided. Configure CSV_FILENAME in fusi_pipeline_launcher.m');
end

if nargin < 1 || isempty(runID)
    error('load_run_info:MissingRunID', ...
        'Run ID must be provided (e.g., ''run-115047'')');
end

%% Read CSV file

% Get full path to CSV file (should be in same directory as this function)
launcherDir = fileparts(fileparts(mfilename('fullpath')));
csvPath = fullfile(launcherDir, csvFilename);

% Check if CSV file exists
if ~isfile(csvPath)
    error('load_run_info:CSVFileNotFound', ...
        'CSV file not found: %s\nCheck CSV_FILENAME in fusi_pipeline_launcher.m', csvPath);
end

% Read CSV file
try
    csvTable = readtable(csvPath, 'Delimiter', ',', 'ReadVariableNames', true);
catch ME
    error('load_run_info:CSVReadError', ...
        'Failed to read CSV file: %s\nError: %s', csvPath, ME.message);
end

% Validate required columns
requiredCols = {'experiment', 'session_id', 'func_run', 'anatomic_run', 'data_root'};
missingCols = setdiff(requiredCols, csvTable.Properties.VariableNames);
if ~isempty(missingCols)
    error('load_run_info:MissingColumns', ...
        'CSV file missing required columns: %s', strjoin(missingCols, ', '));
end

%% Find matching run

% Find row where func_run matches runID
matchIdx = strcmp(csvTable.func_run, runID);

if ~any(matchIdx)
    error('load_run_info:RunNotFound', ...
        'Run ID ''%s'' not found in CSV file: %s\nAvailable runs: %s', ...
        runID, csvFilename, strjoin(csvTable.func_run, ', '));
end

if sum(matchIdx) > 1
    warning('load_run_info:MultipleMatches', ...
        'Multiple entries found for run %s. Using first match.', runID);
end

% Get the first matching row
rowIdx = find(matchIdx, 1);

%% Extract run information

runInfo = struct();
runInfo.experiment = char(csvTable.experiment(rowIdx));
runInfo.session_id = char(csvTable.session_id(rowIdx));
runInfo.func_run = char(csvTable.func_run(rowIdx));
runInfo.anatomic_run = char(csvTable.anatomic_run(rowIdx));
runInfo.data_root = char(csvTable.data_root(rowIdx));

% Construct paths
runInfo.paths = struct();

% Functional paths
runInfo.paths.func_collection = fullfile(...
    runInfo.data_root, ...
    'Data_collection', ...
    runInfo.session_id, ...
    runInfo.func_run);

runInfo.paths.func_analysis = fullfile(...
    runInfo.data_root, ...
    'Data_analysis', ...
    runInfo.session_id, ...
    runInfo.func_run);

% Anatomical paths
runInfo.paths.anat_collection = fullfile(...
    runInfo.data_root, ...
    'Data_collection', ...
    runInfo.session_id, ...
    runInfo.anatomic_run);

runInfo.paths.anat_analysis = fullfile(...
    runInfo.data_root, ...
    'Data_analysis', ...
    runInfo.session_id, ...
    runInfo.anatomic_run);

% Atlas path (one directory up from launcher)
runInfo.paths.atlas = fullfile(launcherDir, '..', 'allen_brain_atlas');

end
