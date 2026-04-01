function Y = prepare_data_matrix(PDI, bmask)
% PREPARE_DATA_MATRIX - Reshape fUSI data from 3D to 2D matrix for GLM
%
% Converts PDI data from [nx x nz x T] format to [T x V] format,
% where V is the number of brain voxels (determined by bmask).
%
% Inputs:
%   PDI - [nx x nz x T] preprocessed fUSI data
%   bmask - [nx x nz] binary brain mask (1 = brain, 0 = non-brain)
%
% Output:
%   Y - [T x V] data matrix suitable for GLM fitting
%       T = number of timepoints
%       V = number of brain voxels (sum(bmask(:)))
%
% Notes:
%   - Only voxels where bmask == 1 are included
%   - Output is in column-major order (standard MATLAB)
%   - Each column of Y is a voxel time series
%
% Example:
%   data = load('prepPDI.mat');
%   Y = prepare_data_matrix(data.PDI, data.bmask);
%   size(Y)  % [3652 x 14220] for typical dataset
%
% See also: glm, reconstruct_maps

%% Input validation

if ndims(PDI) ~= 3
    error('prepare_data_matrix:InvalidInput', ...
          'PDI must be 3D array [nx x nz x T]');
end

[nx, nz, T] = size(PDI);

if ~isequal(size(bmask), [nx, nz])
    error('prepare_data_matrix:DimensionMismatch', ...
          'bmask must be [%d x %d] to match PDI', nx, nz);
end

if ~islogical(bmask) && ~all(ismember(bmask(:), [0 1]))
    warning('prepare_data_matrix:InvalidMask', ...
            'bmask should be logical or binary (0/1). Converting to logical.');
    bmask = logical(bmask);
end

%% Reshape data

% Reshape PDI from [nx x nz x T] to [nx*nz x T]
PDI_2D = reshape(PDI, nx*nz, T);  % [nx*nz x T]

% Extract only brain voxels using mask
mask_idx = find(bmask(:));  % Linear indices of brain voxels
Y = PDI_2D(mask_idx, :)';  % [T x V]

end
