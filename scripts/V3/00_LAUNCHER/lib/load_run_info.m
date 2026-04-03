function runInfo = load_run_info(runID, csvFilename)
% LOAD_RUN_INFO - Load run information from CSV and construct all paths
%
% Usage:
%   runInfo = load_run_info('run-115047', 'fUSI_data_location_STORM.csv')
%
% Description:
%   Reads the specified CSV file, finds the matching run, and constructs
%   all necessary paths for data collection and analysis directories.
%
%   Compatible with the CSV produced by 00_DATA_MANAGEMENT/03_CP_DATA/
%   cp_fUSI_orig2dest.py (copy tracking CSV).
%
% Required CSV columns:
%   func_run_id     - Functional run identifier     (e.g. run-115047)
%   project         - Project folder name           (e.g. fUSIMethodsPaper)
%   subject_id      - Subject identifier            (e.g. sub-methods02)
%   session_id      - Session identifier            (e.g. ses-231215)
%   anatomical_path - Full ORIGINAL path to anat Data_analysis folder
%                     (used only to extract anat subject / session / run)
%   dest_root       - Destination root              (e.g. /data03/fUSIMethodsPaper_LC)
%
% Optional CSV columns (present but not used for path construction):
%   TOCOPY, COPIED, condition, orig_root
%
% Inputs:
%   runID       - Run identifier (e.g., 'run-115047')  [REQUIRED]
%   csvFilename - CSV filename in launcher directory   [REQUIRED]
%
% Output:
%   runInfo - Struct with fields:
%       .project       - Project name
%       .condition     - Condition (if present in CSV, else '')
%       .subject_id    - Subject ID
%       .session_id    - Session ID
%       .func_run_id   - Functional run ID
%       .dest_root     - Destination root path
%       .paths         - Struct with all constructed paths:
%           .func_collection   - Functional Data_collection directory
%           .func_analysis     - Functional Data_analysis directory
%           .anat_collection   - Anatomical Data_collection directory
%           .anat_analysis     - Anatomical Data_analysis directory
%           .atlas             - Atlas directory (relative to scripts root)

%% Validate inputs
if nargin < 2 || isempty(csvFilename)
    error('load_run_info:MissingCSVFilename', ...
        'CSV filename must be provided. Configure CSV_FILENAME in fusi_pipeline_launcher.m');
end
if nargin < 1 || isempty(runID)
    error('load_run_info:MissingRunID', ...
        'Run ID must be provided (e.g., ''run-115047'')');
end

%% Read CSV file

% CSV lives in the launcher directory (one level above lib/)
launcherDir = fileparts(fileparts(mfilename('fullpath')));
csvPath = fullfile(launcherDir, csvFilename);

if ~isfile(csvPath)
    error('load_run_info:CSVFileNotFound', ...
        'CSV file not found: %s\nCheck CSV_FILENAME in fusi_pipeline_launcher.m', csvPath);
end

try
    csvTable = readtable(csvPath, 'Delimiter', ',', 'ReadVariableNames', true);
catch ME
    error('load_run_info:CSVReadError', ...
        'Failed to read CSV: %s\nError: %s', csvPath, ME.message);
end

% Validate required columns
requiredCols = {'func_run_id', 'project', 'subject_id', 'session_id', ...
                'anatomical_path', 'dest_root'};
missingCols = setdiff(requiredCols, csvTable.Properties.VariableNames);
if ~isempty(missingCols)
    error('load_run_info:MissingColumns', ...
        'CSV file missing required columns: %s\n(Got: %s)', ...
        strjoin(missingCols, ', '), ...
        strjoin(csvTable.Properties.VariableNames, ', '));
end

%% Find matching run

matchIdx = strcmp(csvTable.func_run_id, runID);

if ~any(matchIdx)
    error('load_run_info:RunNotFound', ...
        'Run ''%s'' not found in %s\nAvailable runs: %s', ...
        runID, csvFilename, strjoin(csvTable.func_run_id, ', '));
end
if sum(matchIdx) > 1
    warning('load_run_info:MultipleMatches', ...
        'Multiple entries found for run %s. Using first match.', runID);
end

rowIdx = find(matchIdx, 1);

%% Extract run information

runInfo = struct();
runInfo.project     = char(csvTable.project(rowIdx));
runInfo.subject_id  = char(csvTable.subject_id(rowIdx));
runInfo.session_id  = char(csvTable.session_id(rowIdx));
runInfo.func_run_id = char(csvTable.func_run_id(rowIdx));
runInfo.dest_root   = char(csvTable.dest_root(rowIdx));

% Optional: condition
if ismember('condition', csvTable.Properties.VariableNames)
    runInfo.condition = char(csvTable.condition(rowIdx));
else
    runInfo.condition = '';
end

%% Parse anatomical_path to extract anat subject / session / run
%
% anatomical_path is the ORIGINAL (pre-copy) full path, e.g.:
%   /data06/fUSIMethodsPaper/Data_analysis/sub-methods02/ses-231215/run-113409/
%
% The last 3 non-empty path components are always:
%   subject_id / session_id / run_id
% — regardless of which project/host they come from.

anatPathRaw = strtrim(char(csvTable.anatomical_path(rowIdx)));
anatParts   = strsplit(anatPathRaw, '/');
anatParts   = anatParts(~cellfun(@isempty, anatParts));  % strip empty tokens

if length(anatParts) < 3
    error('load_run_info:BadAnatPath', ...
        'Cannot parse anatomical_path (need ≥ 3 components): %s', anatPathRaw);
end

anat_sub = anatParts{end-2};   % e.g. sub-methods02
anat_ses = anatParts{end-1};   % e.g. ses-231215
anat_run = anatParts{end};     % e.g. run-113409

%% Construct paths

runInfo.paths = struct();

runInfo.paths.func_collection = fullfile(runInfo.dest_root, 'Data_collection', ...
    runInfo.subject_id, runInfo.session_id, runInfo.func_run_id);

runInfo.paths.func_analysis = fullfile(runInfo.dest_root, 'Data_analysis', ...
    runInfo.subject_id, runInfo.session_id, runInfo.func_run_id);

runInfo.paths.anat_collection = fullfile(runInfo.dest_root, 'Data_collection', ...
    anat_sub, anat_ses, anat_run);

runInfo.paths.anat_analysis = fullfile(runInfo.dest_root, 'Data_analysis', ...
    anat_sub, anat_ses, anat_run);

% Atlas: one directory above launcher directory
runInfo.paths.atlas = fullfile(launcherDir, '..', 'allen_brain_atlas');

end
