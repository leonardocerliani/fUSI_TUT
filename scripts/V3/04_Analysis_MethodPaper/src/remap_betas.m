function betas_2D = remap_betas(betas, bmask)
% REMAP_BETAS - Remap beta coefficients from vector to 2D space
%
% Converts beta estimates from [p x V] format back to [p x ny x nz] format
% using the brain mask to place values in correct spatial locations.
%
% Inputs:
%   betas - [p x V] parameter estimates (p predictors, V voxels)
%   bmask - [ny x nz] binary brain mask
%
% Output:
%   betas_2D - [p x ny x nz] betas remapped to 2D space
%              Non-brain voxels (bmask == 0) are set to NaN
%
% Example:
%   results = glm('M1', Y, stim);
%   betas_2D = remap_betas(results.betas, data.bmask);
%
% See also: glm, prepare_data_matrix

%% Input validation
[p, V] = size(betas);
[ny, nz] = size(bmask);

if sum(bmask(:)) ~= V
    error('remap_betas:DimensionMismatch', ...
          'Number of brain voxels in bmask (%d) does not match betas (%d)', ...
          sum(bmask(:)), V);
end

%% Remap betas to 2D space

% Initialize with NaN (non-brain voxels)
betas_2D = nan(p, ny, nz);

% Get linear indices of brain voxels
mask_idx = find(bmask(:));

% For each predictor, place betas in correct locations
for i = 1:p
    temp_2D = nan(ny * nz, 1);
    temp_2D(mask_idx) = betas(i, :);
    betas_2D(i, :, :) = reshape(temp_2D, ny, nz);
end

end
