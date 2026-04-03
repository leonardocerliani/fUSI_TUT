function fusi_pipeline_launcher(runID)
% FUSI_PIPELINE_LAUNCHER - Main CLI launcher for fUSI image processing pipeline
%
% Usage:
%   fusi_pipeline_launcher('run-115047')
%
% Description:
%   This launcher orchestrates the complete fUSI pipeline by:
%   1. Looking up run information from CSV database
%   2. Checking which pipeline stages are ready to run
%   3. Displaying interactive menu with status checkboxes
%   4. Executing the selected pipeline stage
%
% Pipeline Stages:
%   Stage 02: Functional Reconstruction (raw data → PDI.mat)
%   Stage 03: Functional Preprocessing (PDI.mat → prepPDI.mat)
%   Stage 04: Analysis (prepPDI.mat → analysis results)
%
% Input:
%   runID - Run identifier in format 'run-XXXXXX' (e.g., 'run-115047')
%
% Example:
%   fusi_pipeline_launcher('run-115047')
%
% See also: load_run_info, check_reconstruction_ready, 
%           check_preprocessing_ready, check_analysis_ready

% Author: Cline AI Assistant
% Date: March 31, 2026

%% ============================================================
%  CONFIGURATION - Set CSV filename for your environment
%  ============================================================
% Choose the appropriate CSV file for your data location:
% - 'fUSI_data_location_STORM.csv' for remote server
% - 'fUSI_data_location_LOCAL.csv' for local machine

CSV_FILENAME = 'fUSI_data_location_STORM.csv';  % <-- EDIT THIS LINE

%% Setup
fprintf('\n========================================\n');
fprintf('fUSI Pipeline Launcher\n');
fprintf('========================================\n\n');

% Add lib directory to path
libPath = fullfile(fileparts(mfilename('fullpath')), 'lib');
addpath(libPath);

%% Step 1: Load run information from CSV
fprintf('→ Loading run information for: %s\n', runID);
fprintf('→ Using CSV file: %s\n', CSV_FILENAME);

try
    runInfo = load_run_info(runID, CSV_FILENAME);
catch ME
    fprintf('\n');
    error('Failed to load run info: %s', ME.message);
end

fprintf('  ✓ Project: %s\n', runInfo.project);
fprintf('  ✓ Subject / Session: %s / %s\n', runInfo.subject_id, runInfo.session_id);
fprintf('  ✓ Dest root: %s\n\n', runInfo.dest_root);

%% Step 2: Check file availability for each pipeline stage
fprintf('→ Checking pipeline stage status...\n\n');

% Check Stage 02: Reconstruction
status.reconstruction = check_reconstruction_ready(runInfo);

% Check Stage 03: Preprocessing
status.preprocessing = check_preprocessing_ready(runInfo);

% Check Stage 04: Analysis
status.analysis = check_analysis_ready(runInfo);

%% Step 3: Display status menu and get user selection
selectedStage = display_status_menu(runID, status);

% Handle exit
if selectedStage == 0
    fprintf('\nExiting launcher.\n');
    return;
end

%% Step 4: Execute selected pipeline stage
fprintf('\n→ Executing pipeline stage...\n\n');

switch selectedStage
    case 1  % Reconstruction
        if ~status.reconstruction.can_run
            fprintf('❌ Cannot run reconstruction - missing required files.\n');
            display_missing_files(status.reconstruction);
            return;
        end
        
        % Warn if already completed
        if status.reconstruction.ready
            fprintf('WARNING: Reconstruction already exists!\nOverwrite it? (y/N)');
            response = input('Do you want to overwrite it? (y/N): ', 's');
            if isempty(response)
                response = 'N';  % Default to No
            end
            if ~strcmpi(response, 'y')
                fprintf('Reconstruction cancelled.\n');
                return;
            end
        end
        
        run_reconstruction(runInfo);
        
    case 2  % Preprocessing
        if ~status.preprocessing.can_run
            fprintf('❌ Cannot run preprocessing - missing required files.\n');
            display_missing_files(status.preprocessing);
            return;
        end
        
        % Warn if already completed
        if status.preprocessing.ready
            fprintf('⚠️  WARNING: Preprocessing already exists!\nOverwrite it? (y/N)');
            response = input('Do you want to overwrite it? (y/N): ', 's');
            if isempty(response)
                response = 'N';  % Default to No
            end
            if ~strcmpi(response, 'y')
                fprintf('Preprocessing cancelled.\n');
                return;
            end
        end
        
        run_preprocessing(runInfo);
        
    case 3  % Analysis
        if ~status.analysis.can_run
            fprintf('❌ Cannot run analysis - missing required files.\n');
            display_missing_files(status.analysis);
            return;
        end
        
        % Note: Analysis can always be re-run (no single output file)
        run_analysis(runInfo);
        
    otherwise
        error('Invalid stage selection: %d', selectedStage);
end

fprintf('\n========================================\n');
fprintf('Pipeline stage completed successfully!\n');
fprintf('========================================\n\n');

end

%% Helper function to display missing files
function display_missing_files(stageStatus)
    if ~isempty(stageStatus.missing_files)
        fprintf('\nMissing files:\n');
        for i = 1:length(stageStatus.missing_files)
            fprintf('  ✗ %s\n', stageStatus.missing_files{i});
        end
    end
    if isfield(stageStatus, 'message')
        fprintf('\n%s\n', stageStatus.message);
    end
end

%% Stage execution functions (to be implemented)
function run_reconstruction(runInfo)
    fprintf('=== Running Stage 02: Functional Reconstruction ===\n\n');
    
    % Add reconstruction stage directory to path
    launcherDir = fileparts(mfilename('fullpath'));
    scriptsDir = fileparts(launcherDir);
    reconstructionPath = fullfile(scriptsDir, '02_Func_Reconstruction');
    addpath(genpath(reconstructionPath));
    
    % Get paths
    func_collection_path = runInfo.paths.func_collection;
    func_analysis_path = runInfo.paths.func_analysis;
    
    fprintf('Collection path: %s\n', func_collection_path);
    fprintf('Analysis path: %s\n\n', func_analysis_path);
    
    % Call reconstruction function
    fprintf('Executing: do_reconstruct_functional(func_collection_path, func_analysis_path)\n\n');
    PDI = do_reconstruct_functional(func_collection_path, func_analysis_path);
    
    fprintf('\n✓ Reconstruction complete!\n');
end

function run_preprocessing(runInfo)
    fprintf('=== Running Stage 03: Functional Preprocessing ===\n\n');
    
    % Add preprocessing stage directory to path
    launcherDir = fileparts(mfilename('fullpath'));
    scriptsDir = fileparts(launcherDir);
    preprocessingPath = fullfile(scriptsDir, '03_Func_Preprocessing');
    addpath(genpath(preprocessingPath));
    
    % Get paths
    anat_analysis_path = runInfo.paths.anat_analysis;
    func_analysis_path = runInfo.paths.func_analysis;
    atlasPath = runInfo.paths.atlas;
    
    fprintf('Anatomical analysis path: %s\n', anat_analysis_path);
    fprintf('Functional analysis path: %s\n', func_analysis_path);
    fprintf('Atlas path: %s\n\n', atlasPath);
    
    % Call preprocessing function
    fprintf('Executing: do_preprocessing(anat_analysis_path, func_analysis_path, atlasPath)\n\n');
    do_preprocessing(anat_analysis_path, func_analysis_path, atlasPath);
    
    fprintf('\n✓ Preprocessing complete!\n');
end

function run_analysis(runInfo)
    fprintf('=== Running Stage 04: Analysis ===\n\n');
    
    % Check experiment type FIRST
    if ~strcmp(runInfo.project, 'fUSIMethodsPaper')
        fprintf('❌ This analysis cannot be carried out on %s\n', runInfo.func_run_id);
        fprintf('   Analysis requires project: fUSIMethodsPaper\n');
        fprintf('   This run project: %s\n', runInfo.project);
        return;
    end
    
    % Add analysis stage directory to path
    launcherDir = fileparts(mfilename('fullpath'));
    scriptsDir = fileparts(launcherDir);
    analysisPath = fullfile(scriptsDir, '04_Analysis_MethodPaper');
    addpath(genpath(analysisPath));
    
    % Get path to functional analysis directory
    func_analysis_path = runInfo.paths.func_analysis;
    
    fprintf('Functional analysis path: %s\n\n', func_analysis_path);
    
    % Call analysis function
    fprintf('Executing: do_analysis_methods_paper(func_analysis_path)\n\n');
    do_analysis_methods_paper(func_analysis_path);
    
    fprintf('\n✓ Analysis complete!\n');
end
