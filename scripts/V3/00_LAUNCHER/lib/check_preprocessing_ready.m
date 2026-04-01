function status = check_preprocessing_ready(runInfo)
% CHECK_PREPROCESSING_READY - Check if preprocessing has been completed
%
% Usage:
%   status = check_preprocessing_ready(runInfo)
%
% Input:
%   runInfo - Struct from load_run_info() containing paths
%
% Output:
%   status - Struct with fields:
%       .ready         - true if preprocessing already completed
%       .missing_files - Cell array of missing files
%       .found_files   - Cell array of found files
%       .message       - Descriptive message
%       .can_run       - true if input files exist (can run preprocessing)

% Initialize status structure
status = struct();
status.ready = false;        % Has preprocessing been completed?
status.can_run = false;     % Can we run preprocessing (inputs exist)?
status.missing_files = {};
status.found_files = {};
status.message = '';

%% Check if preprocessing OUTPUT exists (prepPDI.mat)

funcAnalysisDir = runInfo.paths.func_analysis;
prepPDIFile = fullfile(funcAnalysisDir, 'prepPDI.mat');

if isfile(prepPDIFile)
    status.ready = true;
    status.found_files{end+1} = 'prepPDI.mat (preprocessing complete)';
    status.message = '✅ Preprocessing already completed';
    status.can_run = true;  % Can re-run if needed
    return;
end

%% Check if preprocessing INPUTS exist (can we run it?)

%% Check Functional Data (output from reconstruction)

funcAnalysisDir = runInfo.paths.func_analysis;

% Check if functional analysis directory exists
if ~isfolder(funcAnalysisDir)
    status.missing_files{end+1} = '[Functional analysis directory]';
else
    % 1. PDI.mat (REQUIRED - output from reconstruction)
    pdiFile = fullfile(funcAnalysisDir, 'PDI.mat');
    if isfile(pdiFile)
        status.found_files{end+1} = 'PDI.mat (functional)';
    else
        status.missing_files{end+1} = 'PDI.mat (functional - run reconstruction first)';
    end
end

%% Check Anatomical Data (from anatomical registration)

anatAnalysisDir = runInfo.paths.anat_analysis;

% Check if anatomical analysis directory exists
if ~isfolder(anatAnalysisDir)
    status.missing_files{end+1} = '[Anatomical analysis directory]';
else
    % 2. anatomic.mat (REQUIRED)
    anatomicFile = fullfile(anatAnalysisDir, 'anatomic.mat');
    if isfile(anatomicFile)
        status.found_files{end+1} = 'anatomic.mat';
    else
        status.missing_files{end+1} = 'anatomic.mat (run anatomical registration first)';
    end
    
    % 3. Transformation.mat (REQUIRED)
    transformFile = fullfile(anatAnalysisDir, 'Transformation.mat');
    if isfile(transformFile)
        status.found_files{end+1} = 'Transformation.mat';
    else
        status.missing_files{end+1} = 'Transformation.mat (run anatomical registration first)';
    end
end

%% Check Atlas

atlasDir = runInfo.paths.atlas;
atlasFile = fullfile(atlasDir, 'allen_brain_atlas.mat');

if isfile(atlasFile)
    status.found_files{end+1} = 'allen_brain_atlas.mat';
else
    status.missing_files{end+1} = 'allen_brain_atlas.mat (check atlas path)';
end

%% Determine can_run status

if isempty(status.missing_files)
    status.can_run = true;
    status.ready = false;  % Not yet completed (no prepPDI.mat)
    status.message = '👍 Ready to run';
else
    status.can_run = false;
    status.ready = false;
    status.message = sprintf('Missing %d required file(s) ⚠️', length(status.missing_files));
end

end
