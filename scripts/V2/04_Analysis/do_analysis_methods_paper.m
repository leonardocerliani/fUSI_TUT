% DO_ANALYSIS_METHODS_PAPER - Main script for fUSI GLM analysis
%
% Simplified, clean implementation for GLM analysis on fUSI data
%
% Author: fUSI methods paper
% Date: 2026-02-12

%% Setup
clear; clc; close all;
addpath('src');

fprintf('=== fUSI GLM Analysis ===\n\n');

%% 1. Load Data
fprintf('Loading data...\n');
load('prepPDI.mat');

fprintf('  Data: [%d x %d x %d]\n', size(data.PDI, 1), size(data.PDI, 2), size(data.PDI, 3));
fprintf('  Brain voxels: %d\n\n', sum(data.bmask(:)));

%% 2. Create Predictors
fprintf('Creating predictors...\n');
[stim, wheel] = create_predictors(data);
TR = median(diff(data.time));
fprintf('  TR: %.3f sec\n\n', TR);

%% 3. Prepare Data Matrices
fprintf('Preparing data matrices...\n');
Y = prepare_data_matrix(data.PDI, data.bmask);
Y_PC1_removed = remove_PC1(Y);
fprintf('\n');

%% 4. Fit Models : NB the last beta is always the intercept!
fprintf('Fitting GLM models...\n\n');

% Initialize results structure
all_results = struct();

% --- MODEL 1: Stimulus ---
fprintf('M1: stimulus\n');
% res = glm('M1', Y, stim); % w/out convolution
res = glm('M1', Y, hrf_conv(stim, TR));
all_results.M1.betas = remap_betas(res.betas, data.bmask);

% --- MODEL 2: Stationary stimulus ---
fprintf('M2: stationary stimulus\n');
stim_stationary = get_stationary_stim(stim, wheel, 5.0);
res = glm('M2', Y, stim_stationary);
all_results.M2.betas = remap_betas(res.betas, data.bmask);

fprintf('\n=== Analysis complete ===\n');
fprintf('Results stored in: all_results\n');
fprintf('  all_results.M1.betas: [%d x %d x %d]\n', ...
        size(all_results.M1.betas, 1), size(all_results.M1.betas, 2), size(all_results.M1.betas, 3));
fprintf('  all_results.M2.betas: [%d x %d x %d]\n', ...
        size(all_results.M2.betas, 1), size(all_results.M2.betas, 2), size(all_results.M2.betas, 3));
