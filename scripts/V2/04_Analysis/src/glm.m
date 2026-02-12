function results = glm(model_name, Y, X)
% GLM - Fit General Linear Model to fUSI data (simplified interface)
%
% Inputs:
%   model_name - string, name of the model (e.g., 'M1', 'M2_PC1_removed')
%   Y - [T x V] data matrix (timepoints x voxels)
%   X - [T x p] design matrix (timepoints x predictors)
%       Note: Constant term (intercept) is automatically added
%
% Outputs:
%   results - struct with field:
%       .betas - [p+1 x V] parameter estimates (includes intercept)
%
% Example:
%   results = glm('M1', Y, stim);
%   results = glm('M2', Y_PC1_removed, [hrf_conv(stim, TR), wheel]);
%
% See also: create_predictors, prepare_data_matrix, hrf_conv

%% Auto-add constant term (intercept)
X = [X, ones(size(X, 1), 1)];

[T, p] = size(X);
V = size(Y, 2);

if size(Y, 1) ~= T
    error('GLM:DimensionMismatch', ...
          'Y must have %d rows to match design matrix', T);
end

%% Fit GLM using backslash operator
betas = X \ Y;  % [p x V]

%% Store minimal results
results = struct();
results.betas = betas;
results.model_name = model_name;

end
