function Y_clean = remove_PC1(Y)
% REMOVE_PC1 - Remove first principal component from fUSI data
%
% Removes the global signal (first principal component) from the data matrix.
% This can help reduce global physiological noise or scanner drift.
%
% Inputs:
%   Y - [T x V] data matrix (timepoints x voxels)
%
% Output:
%   Y_clean - [T x V] data with PC1 removed (same size as input)
%
% Method:
%   1. Compute first principal component (PC1) of Y
%   2. Project out PC1 from each voxel time series
%   3. Return cleaned data with same mean as original
%
% Example:
%   Y_clean = remove_PC1(Y);
%   % Compare variance explained
%   var_before = var(Y(:));
%   var_after = var(Y_clean(:));
%
% See also: pca, create_predictors

%% Input validation

if ~ismatrix(Y)
    error('remove_PC1:InvalidInput', 'Y must be a 2D matrix [T x V]');
end

[T, V] = size(Y);

%% Center data (required for PCA)

Y_mean = mean(Y, 1);  % [1 x V] mean per voxel
Y_centered = Y - Y_mean;  % [T x V] centered data

%% Compute first principal component

% Use economy-size SVD for efficiency
[U, S, ~] = svds(Y_centered, 1);  % Get only first component

% PC1 scores (time course of first component)
PC1_scores = U(:, 1);  % [T x 1]

% Variance explained by PC1
total_var = sum(sum(Y_centered.^2));
PC1_var = S(1,1)^2;
var_explained = 100 * PC1_var / total_var;

%% Remove PC1 from data

% Project out PC1 from centered data
Y_clean_centered = Y_centered - (PC1_scores * (PC1_scores' * Y_centered));

% Add back the mean
Y_clean = Y_clean_centered + Y_mean;

end
