function results = glm(model_name, Y, X, predictor_labels)
% GLM - Fit General Linear Model to fUSI data (simplified interface)
%
% Inputs:
%   model_name - string, name of the model (e.g., 'M1', 'M2_PC1_removed')
%   Y - [T x V] data matrix (timepoints x voxels)
%   X - [T x p] design matrix (timepoints x predictors)
%   predictor_labels - {1 x p} cell array of predictor names
%       Note: Constant term 'intercept' is automatically added
%
% Outputs:
%   results - struct with fields:
%       .betas - [p+1 x V] parameter estimates (includes intercept)
%       .R2 - [1 x V] global model R² (proportion of variance explained)
%       .eta2 - [p+1 x V] partial eta² effect size per predictor
%       .Z - [p+1 x V] z-scores for each beta
%       .p - [p+1 x V] p-values for each beta (two-tailed)
%       .predictor_labels - {1 x p+1} cell array (includes 'intercept')
%       .model_name - string, model name
%   Note: Residuals not stored to save memory (can be uncommented if needed)
%
% Example:
%   M1_predictors = hrf_conv(stim, TR);
%   M1_labels = {'visual_hrf'};
%   glm_estimate = glm('M1', Y, M1_predictors, M1_labels);
%   all_results.M1 = remap_glm_results(glm_estimate, data.bmask);
%
%   M3_predictors = [hrf_conv(stim, TR), wheel, hrf_conv(wheel, TR)];
%   M3_labels = {'visual_hrf', 'running', 'running_hrf'};
%   glm_estimate = glm('M3', Y, M3_predictors, M3_labels);
%   all_results.M3 = remap_glm_results(glm_estimate, data.bmask);
%
% See also: remap_glm_results, create_predictors, prepare_data_matrix, hrf_conv

%% Validate inputs
[T, p] = size(X);
V = size(Y, 2);

if size(Y, 1) ~= T
    error('GLM:DimensionMismatch', ...
          'Y must have %d rows to match design matrix', T);
end

% Check predictor_labels is a cell array
if ~iscell(predictor_labels)
    error('GLM:InvalidLabels', ...
          'predictor_labels must be a cell array of strings');
end

% Check length matches number of predictors
if length(predictor_labels) ~= p
    error('GLM:LabelMismatch', ...
          'predictor_labels must have %d elements to match predictors in X', p);
end

%% Auto-add constant term (intercept)
X = [X, ones(T, 1)];
predictor_labels = [predictor_labels, {'intercept'}];

%% Fit GLM using backslash operator
betas = X \ Y;  % [p+1 x V]

%% Compute additional statistics
[T, p] = size(X);
V = size(Y, 2);

% Fitted values
fitted = X * betas;                    % [T x V]
% Note: residuals = Y - fitted [T x V] - NOT stored to save memory

% Degrees of freedom
df = T - p;

%% R² (global model fit)
% Formula: R² = 1 - (SS_residual / SS_total)
% where SS_residual = sum((Y - fitted)²)
%       SS_total = sum((Y - mean(Y))²)
SS_total = sum((Y - mean(Y, 1)).^2, 1);           % [1 x V]
SS_residual = sum((Y - fitted).^2, 1);             % [1 x V] - computed but not stored
R2 = 1 - (SS_residual ./ SS_total);                % [1 x V]
R2(SS_total == 0) = 0;  % Handle edge case of zero variance

%% Partial eta² (effect size per predictor)
% Formula: eta² = SS_effect / (SS_effect + SS_residual)
% where SS_effect = sum((fitted_predictor - mean(Y))²)
%       fitted_predictor = X(:,j) * beta(j)
eta2 = zeros(p, V);                                % [p x V]
for j = 1:p
    % Partial fit for predictor j
    partial_fit = X(:, j) * betas(j, :);           % [T x V]
    SS_effect = sum((partial_fit - mean(Y, 1)).^2, 1);  % [1 x V]
    eta2(j, :) = SS_effect ./ (SS_effect + SS_residual);
    eta2(j, SS_effect + SS_residual == 0) = 0;     % Handle edge case
end

%% Z-scores and p-values
% Formula: Z = beta / SE(beta)
% where SE(beta) = sqrt(diag(inv(X'X)) * sigma²)
%       sigma² = SS_residual / df

% Variance of residuals per voxel
sigma2 = SS_residual / df;                         % [1 x V]

% Standard errors (vectorized across voxels)
% SE(beta_j) = sqrt(C_jj * sigma²) where C = inv(X'X)
C = inv(X' * X);                                   % [p x p]
se_beta = sqrt(diag(C) * sigma2);                  % [p x V]

% Z-scores
Z = betas ./ se_beta;                              % [p x V]
Z(se_beta == 0) = 0;                               % Handle edge case

% P-values (two-tailed test using normal approximation)
% Formula: p = 2 * (1 - Φ(|Z|))
% where Φ is the cumulative distribution function of standard normal
p_values = 2 * (1 - normcdf(abs(Z)));              % [p x V]

%% Store results
results = struct();
results.betas = betas;                             % [p+1 x V]
results.R2 = R2;                                   % [1 x V]
results.eta2 = eta2;                               % [p+1 x V]
results.Z = Z;                                     % [p+1 x V]
results.p = p_values;                              % [p+1 x V]
% results.res = residuals;                         % [T x V] - NOT stored to save memory
results.predictor_labels = predictor_labels;
results.model_name = model_name;

end
