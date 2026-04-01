function results = simple_corr(predictor, Y, bmask)
% SIMPLE_CORR - Compute correlation between predictor and all voxels
%
% Computes Pearson correlation between a predictor and each voxel's
% time series, returning spatially-remapped correlation and eta² maps.
%
% Inputs:
%   predictor - [T x 1] predictor vector
%   Y - [T x V] data matrix (timepoints x voxels)
%   bmask - [ny x nz] brain mask
%
% Output:
%   results - struct with fields:
%       .r - [ny x nz] correlation map (spatially remapped)
%       .eta2 - [ny x nz] eta² map (r squared, effect size)
%
% Example:
%   all_results.M1_corr = simple_corr(stim_stationary, Y, data.bmask);
%   % Access: all_results.M1_corr.r, all_results.M1_corr.eta2
%
% See also: glm, remap_betas

%% Ensure predictor is column vector
predictor = predictor(:);

%% Compute correlation with all voxels (vectorized)
% corr() returns [1 x V] correlation coefficients
r = corr(predictor, Y);

%% Remap to spatial format using remap_betas
r_map = remap_betas(r, bmask);

%% Squeeze to remove singleton dimension: [1 x ny x nz] → [ny x nz]
r_map = squeeze(r_map);

%% Compute eta² (r squared - proportion of variance explained)
eta2_map = r_map.^2;

%% Store results in struct
results = struct();
results.r = r_map;
results.eta2 = eta2_map;

end
