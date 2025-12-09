function [PDI, anatomic, Transf, atlas] = load_anat_and_func(anatPath, funcPath, atlasPath)
% LOAD_ANAT_AND_FUNC - Load anatomical, functional, and atlas data for fUSI preprocessing
%
% Syntax:
%   [PDI, anatomic, Transf, atlas] = load_anat_and_func(anatPath, funcPath, atlasPath)
%   [PDI, anatomic, Transf, atlas] = load_anat_and_func()
%
% Description:
%   Loads all required data for fUSI preprocessing including the Allen brain
%   atlas, anatomical scan, transformation matrix, and functional scan.
%   If paths are not provided, prompts user with UI dialogs.
%
% Inputs:
%   anatPath  - (optional) Path to anatomical data directory containing 
%               anatomic.mat and Transformation.mat
%               Example: 'sample_data/Data_analysis/run-113409-anat'
%   funcPath  - (optional) Path to functional data directory containing PDI.mat
%               Example: 'sample_data/Data_analysis/run-115047-func'
%   atlasPath - (optional) Path to directory containing allen_brain_atlas.mat
%               Example: '/path/to/atlas/directory'
%
%   If any input is not provided, a UI dialog will prompt for selection.
%
% Outputs:
%   PDI       - Structure containing functional data (PDI.PDI is the 3D array)
%   anatomic  - Structure containing anatomical data and metadata
%   Transf    - Transformation matrix for atlas-to-subject registration
%   atlas     - Allen brain atlas structure
%
% Example:
%   % Provide paths directly
%   [PDI, anatomic, Transf, atlas] = load_anat_and_func(...
%       'sample_data/Data_analysis/run-113409-anat', ...
%       'sample_data/Data_analysis/run-115047-func', ...
%       '/path/to/atlas')
%
%   % Interactive mode
%   [PDI, anatomic, Transf, atlas] = load_anat_and_func()

%% Input argument handling

% Check if anatPath is provided, otherwise prompt user
if nargin < 1 || isempty(anatPath)
    fprintf('\n>>> Please select the ANATOMICAL data directory\n');
    anatPath = uigetdir(pwd, 'Select Anatomical Data Directory');
    if anatPath == 0
        error('Anatomical data directory selection cancelled.');
    end
end

% Check if funcPath is provided, otherwise prompt user
if nargin < 2 || isempty(funcPath)
    fprintf('\n>>> Please select the FUNCTIONAL data directory\n');
    funcPath = uigetdir(pwd, 'Select Functional Data Directory');
    if funcPath == 0
        error('Functional data directory selection cancelled.');
    end
end

% Check if atlasPath is provided, otherwise prompt user
if nargin < 3 || isempty(atlasPath)
    fprintf('\n>>> Please select the directory containing ALLEN BRAIN ATLAS (allen_brain_atlas.mat)\n');
    atlasPath = uigetdir(pwd, 'Select Directory Containing allen_brain_atlas.mat');
    if atlasPath == 0
        error('Atlas directory selection cancelled.');
    end
end

% Validate that directories exist
if ~isfolder(anatPath)
    error('Anatomical data directory does not exist: %s', anatPath);
end

if ~isfolder(funcPath)
    error('Functional data directory does not exist: %s', funcPath);
end

if ~isfolder(atlasPath)
    error('Atlas directory does not exist: %s', atlasPath);
end

%% Load Allen Brain Atlas

fprintf('Loading Allen Brain Atlas from: %s\n', atlasPath);
atlasFile = fullfile(atlasPath, 'allen_brain_atlas.mat');
if ~isfile(atlasFile)
    error('Allen brain atlas file not found: %s', atlasFile);
end
load(atlasFile, 'atlas');

%% Load anatomical scan

fprintf('Loading anatomical data from: %s\n', anatPath);

% Load anatomical data
anatFile = fullfile(anatPath, 'anatomic.mat');
if ~isfile(anatFile)
    error('Anatomical data file not found: %s', anatFile);
end
load(anatFile, 'anatomic');

% Load transformation matrix
transfFile = fullfile(anatPath, 'Transformation.mat');
if ~isfile(transfFile)
    error('Transformation file not found: %s', transfFile);
end
load(transfFile, 'Transf');

% Set storage path
anatomic.savepath = anatPath;

%% Load functional scan

fprintf('Loading functional data from: %s\n', funcPath);
funcFile = fullfile(funcPath, 'PDI.mat');
if ~isfile(funcFile)
    error('Functional data file not found: %s', funcFile);
end

load(funcFile, 'PDI');
PDI.savepath = funcPath;

fprintf('Data loading complete.\n');

end
