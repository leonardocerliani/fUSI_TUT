function stim_stationary = get_stationary_stim(stim, wheel, threshold)
% GET_STATIONARY_STIM - Extract stimulus periods during low wheel speed
%
% Returns a modified stimulus predictor that includes only stimulus periods
% where the wheel speed is below a specified threshold. Useful for isolating
% stimulus responses during stationary (non-running) periods.
%
% Inputs:
%   stim - [T x 1] stimulus predictor (typically binary: 1 = ON, 0 = OFF)
%   wheel - [T x 1] wheel speed predictor (absolute speed)
%   threshold - scalar, wheel speed threshold (e.g., 5 cm/s)
%               Default: 5.0
%
% Output:
%   stim_stationary - [T x 1] stimulus predictor during stationary periods
%                     (1 where stim=1 AND wheel<threshold, 0 otherwise)
%
% Example:
%   % Get stimulus responses only when mouse is stationary
%   stim_stationary = get_stationary_stim(stim, wheel, 5);
%   
%   % Compare stationary vs running responses
%   X = [stim_stationary, stim - stim_stationary, ones(size(stim))];
%   results = glm(Y, X);
%
% See also: create_predictors, hrf_conv

%% Input validation

if ~isvector(stim) || ~isvector(wheel)
    error('get_stationary_stim:InvalidInput', 'stim and wheel must be vectors');
end

if length(stim) ~= length(wheel)
    error('get_stationary_stim:DimensionMismatch', ...
          'stim and wheel must have the same length');
end

if nargin < 3 || isempty(threshold)
    threshold = 5.0;  % default threshold in cm/s
end

if threshold < 0
    error('get_stationary_stim:InvalidThreshold', 'threshold must be non-negative');
end

% Ensure column vectors
stim = stim(:);
wheel = wheel(:);

%% Create stationary stimulus predictor

% Identify stationary periods (wheel speed below threshold)
is_stationary = (wheel < threshold);

% Keep stimulus only during stationary periods
stim_stationary = stim .* is_stationary;

end
