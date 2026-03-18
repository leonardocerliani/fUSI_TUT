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

speed_threshold = 10.0;
time_lapse_treshold = 1000;

fprintf('Creating predictors...\n');
[stim, wheel, stim_stationary] = create_predictors(data, speed_threshold, time_lapse_treshold);

% Visualize stationary trial selection (set to true to see plot)
plot_stationary_trials(data, stim, wheel, stim_stationary, speed_threshold, true);

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

%% --- MODEL 1: Stimuli while stationary ---
fprintf('M1: Stimuli while stationary\n');
M1_predictors = stim_stationary;
M1_labels = {'stim_stationary'};
glm_estimate = glm('M1', Y, M1_predictors, M1_labels);
all_results.M1 = remap_glm_results(glm_estimate, data.bmask);
all_results.M1.X = [M1_predictors, ones(size(M1_predictors,1),1)];  % Store design matrix

% M1 With PC1 removal
glm_estimate = glm('M1_PC1_removed', Y_PC1_removed, M1_predictors, M1_labels);
all_results.M1_PC1_removed = remap_glm_results(glm_estimate, data.bmask);
all_results.M1_PC1_removed.X = [M1_predictors, ones(size(M1_predictors,1),1)];


% M1 simple correlation
all_results.M1_corr = simple_corr(stim_stationary, Y, data.bmask);




%% --- MODEL 2: All stimuli ---
fprintf('M2: All stimuli\n');
M2_predictors = hrf_conv(stim, TR);
M2_labels = {'stim_hrf'};
glm_estimate = glm('M2', Y, M2_predictors, M2_labels);
all_results.M2 = remap_glm_results(glm_estimate, data.bmask);
all_results.M2.X = [M2_predictors, ones(size(M2_predictors,1),1)];  % Store design matrix

% M2 With PC1 removal
glm_estimate = glm('M2_PC1_removed', Y_PC1_removed, M2_predictors, M2_labels);
all_results.M2_PC1_removed = remap_glm_results(glm_estimate, data.bmask);
all_results.M2_PC1_removed.X = [M2_predictors, ones(size(M2_predictors,1),1)];


% M2 simple correlation 
all_results.M2_corr = simple_corr(stim, Y, data.bmask);



%% --- MODEL 3: All stimuli + running + interaction ---
fprintf('M3: All stimuli + running + interaction\n');
M3_predictors = [hrf_conv(stim, TR), wheel, hrf_conv(wheel, TR), hrf_conv(stim.*wheel, TR)];
M3_labels = {'stim_hrf', 'running', 'running_hrf', '(stim*running)_hrf'};
glm_estimate = glm('M3', Y, M3_predictors, M3_labels);
all_results.M3 = remap_glm_results(glm_estimate, data.bmask);
all_results.M3.X = [M3_predictors, ones(size(M3_predictors,1),1)];  % Store design matrix

% M3 With PC1 removal
glm_estimate = glm('M3_PC1_removed', Y_PC1_removed, M3_predictors, M3_labels);
all_results.M3_PC1_removed = remap_glm_results(glm_estimate, data.bmask);
all_results.M3_PC1_removed.X = [M3_predictors, ones(size(M3_predictors,1),1)];


%% view results

view_glm_results(all_results, data, 'M1')
view_glm_results(all_results, data, 'M2')
view_glm_results(all_results, data, 'M3')
view_glm_results(all_results, data, 'M3_PC1_removed')
