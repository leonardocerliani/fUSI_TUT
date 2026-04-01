function status = check_reconstruction_ready(runInfo)
% CHECK_RECONSTRUCTION_READY - Check if reconstruction has been completed
%
% Usage:
%   status = check_reconstruction_ready(runInfo)
%
% Input:
%   runInfo - Struct from load_run_info() containing paths
%
% Output:
%   status - Struct with fields:
%       .ready         - true if reconstruction already completed
%       .missing_files - Cell array of missing files
%       .found_files   - Cell array of found files
%       .message       - Descriptive message
%       .can_run       - true if raw data exists (can run reconstruction)

% Initialize status structure
status = struct();
status.ready = false;        % Has reconstruction been completed?
status.can_run = false;     % Can we run reconstruction (raw data exists)?
status.missing_files = {};
status.found_files = {};
status.message = '';

%% Check if reconstruction OUTPUT exists (PDI.mat)

funcAnalysisDir = runInfo.paths.func_analysis;
pdiFile = fullfile(funcAnalysisDir, 'PDI.mat');

if isfile(pdiFile)
    status.ready = true;
    status.found_files{end+1} = 'PDI.mat (reconstruction complete)';
    status.message = '✅ Reconstruction already completed';
    status.can_run = true;  % Can re-run if needed
    return;
end

%% Check if reconstruction INPUTS exist (can we run it?)

dataDir = runInfo.paths.func_collection;

% Check if directory exists
if ~isfolder(dataDir)
    status.message = '❌ Data collection directory does not exist';
    status.missing_files = {'[Data collection directory]'};
    status.can_run = false;
    return;
end

%% Required Files Checklist

% 1. experiment_config.json (REQUIRED)
configFile = fullfile(dataDir, 'experiment_config.json');
if isfile(configFile)
    status.found_files{end+1} = 'experiment_config.json';
else
    status.missing_files{end+1} = 'experiment_config.json';
end

% 2. TTL*.csv (REQUIRED - at least one)
ttlFiles = dir(fullfile(dataDir, 'TTL*.csv'));
if ~isempty(ttlFiles)
    status.found_files{end+1} = sprintf('TTL*.csv (%d file(s))', length(ttlFiles));
else
    status.missing_files{end+1} = 'TTL*.csv (no files found)';
end

% 3. DAQ.csv OR NIDAQ.csv (REQUIRED - at least one)
daqFile = fullfile(dataDir, 'DAQ.csv');
nidaqFile = fullfile(dataDir, 'NIDAQ.csv');
if isfile(daqFile) || isfile(nidaqFile)
    if isfile(daqFile)
        status.found_files{end+1} = 'DAQ.csv';
    end
    if isfile(nidaqFile)
        status.found_files{end+1} = 'NIDAQ.csv';
    end
else
    status.missing_files{end+1} = 'DAQ.csv or NIDAQ.csv';
end

%% FUSI_data Directory Checks

fusiDataDir = fullfile(dataDir, 'FUSI_data');

% Check if FUSI_data directory exists
if ~isfolder(fusiDataDir)
    status.missing_files{end+1} = 'FUSI_data/ (directory not found)';
else
    % 4. fUS_block_PDI_float.bin (REQUIRED)
    binaryFile = fullfile(fusiDataDir, 'fUS_block_PDI_float.bin');
    if isfile(binaryFile)
        status.found_files{end+1} = 'FUSI_data/fUS_block_PDI_float.bin';
    else
        status.missing_files{end+1} = 'FUSI_data/fUS_block_PDI_float.bin';
    end
    
    % 5. *_PlaneWave_FUSI_data.mat (REQUIRED - at least one)
    planeWaveFiles = dir(fullfile(fusiDataDir, '*_PlaneWave_FUSI_data.mat'));
    if ~isempty(planeWaveFiles)
        fileNames = {planeWaveFiles.name};
        fileList = strjoin(fileNames, ', ');
        status.found_files{end+1} = sprintf('FUSI_data/*_PlaneWave_FUSI_data.mat (%s)', fileList);
    else
        status.missing_files{end+1} = 'FUSI_data/*_PlaneWave_FUSI_data.mat';
    end
end

%% Determine can_run status

if isempty(status.missing_files)
    status.can_run = true;
    status.ready = false;  % Not yet completed (no PDI.mat)
    status.message = '👍 Ready to run';
else
    status.can_run = false;
    status.ready = false;
    status.message = sprintf('Missing %d required file(s) ⚠️', length(status.missing_files));
end

end
