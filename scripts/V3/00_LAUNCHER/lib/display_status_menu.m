function selectedStage = display_status_menu(runID, status)
% DISPLAY_STATUS_MENU - Display pipeline status and get user selection
%
% Usage:
%   selectedStage = display_status_menu(runID, status)
%
% Description:
%   Displays a menu showing the status of each pipeline stage with
%   checkboxes indicating readiness, then prompts user to select which
%   stage to run.
%
% Input:
%   runID  - Run identifier (e.g., 'run-115047')
%   status - Struct with fields:
%       .reconstruction - Status struct from check_reconstruction_ready
%       .preprocessing  - Status struct from check_preprocessing_ready
%       .analysis       - Status struct from check_analysis_ready
%
% Output:
%   selectedStage - Integer selection:
%       0 - Exit
%       1 - Reconstruction
%       2 - Preprocessing
%       3 - Analysis
%
% Example:
%   selectedStage = display_status_menu('run-115047', status)

% Display menu header
fprintf('\n========================================\n');
fprintf('Pipeline Status: %s\n', runID);
fprintf('========================================\n\n');

% Reconstruction status
if status.reconstruction.ready
    fprintf('✅ Functional Reconstruction\n');
elseif status.reconstruction.can_run
    fprintf('[ ] Functional Reconstruction\n');
else
    fprintf('Functional Reconstruction ⚠️\n');
end
fprintf('    %s\n\n', status.reconstruction.message);

% Preprocessing status
if status.preprocessing.ready
    fprintf('✅ Functional Preprocessing\n');
elseif status.preprocessing.can_run
    fprintf('[ ] Functional Preprocessing\n');
else
    fprintf('Functional Preprocessing ⚠️\n');
end
fprintf('    %s\n\n', status.preprocessing.message);

% Analysis status
if status.analysis.ready
    fprintf('✅ Analysis: MethodPaper\n');
elseif status.analysis.can_run
    fprintf('[ ] Analysis: MethodPaper\n');
else
    fprintf('Analysis: MethodPaper ⚠️ \n');
end
fprintf('    %s\n\n', status.analysis.message);

fprintf('========================================\n');

% Display menu options
fprintf('\nWhich step do you want to run?\n');
fprintf('1 - Functional Reconstruction\n');
fprintf('2 - Functional Preprocessing\n');
fprintf('3 - Analysis: MethodPaper\n');
fprintf('0 - Exit\n\n');

% Get user input
selectedStage = input('Enter your choice: ');

% Validate input
if isempty(selectedStage) || ~isnumeric(selectedStage) || selectedStage < 0 || selectedStage > 3
    error('Invalid selection. Please choose 0-3.');
end

% Ensure it's an integer
selectedStage = round(selectedStage);

end
