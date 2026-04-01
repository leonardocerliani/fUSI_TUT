function status = check_analysis_ready(runInfo)
% CHECK_ANALYSIS_READY - Check if analysis has been completed
%
% Usage:
%   status = check_analysis_ready(runInfo)
%
% Input:
%   runInfo - Struct from load_run_info() containing paths
%
% Output:
%   status - Struct with fields:
%       .ready         - true if analysis already completed
%       .missing_files - Cell array of missing files
%       .found_files   - Cell array of found files
%       .message       - Descriptive message
%       .can_run       - true if input files exist (can run analysis)

% Initialize status structure
status = struct();
status.ready = false;        % Has analysis been completed?
status.can_run = false;     % Can we run analysis (inputs exist)?
status.missing_files = {};
status.found_files = {};
status.message = '';

%% Check if analysis OUTPUT exists
% TODO: Define what output indicates completed analysis
% For now, we'll assume analysis doesn't create a single definitive output file
% So analysis is never marked as "completed" - it can always be re-run

%% Check Preprocessed Functional Data

funcAnalysisDir = runInfo.paths.func_analysis;

% Check if functional analysis directory exists
if ~isfolder(funcAnalysisDir)
    status.missing_files{end+1} = '[Functional analysis directory]';
    % Don't return early - continue checking and use standard message
else

    % 1. prepPDI.mat (REQUIRED - output from preprocessing)
    prepPDIFile = fullfile(funcAnalysisDir, 'prepPDI.mat');
    if isfile(prepPDIFile)
        status.found_files{end+1} = 'prepPDI.mat';
    else
        status.missing_files{end+1} = 'prepPDI.mat (run preprocessing first)';
    end
end

%% Determine can_run status

if isempty(status.missing_files)
    status.can_run = true;
    status.ready = false;  % Analysis can always be re-run
    status.message = '👍 Ready to run';
else
    status.can_run = false;
    status.ready = false;
    status.message = sprintf('Missing %d required file(s) ⚠️', length(status.missing_files));
end

end
