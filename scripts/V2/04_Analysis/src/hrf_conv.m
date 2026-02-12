function convolved = hrf_conv(predictor, TR)
% HRF_CONV - Apply canonical HRF convolution to a predictor
%
% Convolves a predictor time series with a canonical hemodynamic response
% function (double-gamma HRF). Useful for modeling BOLD/hemodynamic responses
% to neural events.
%
% Inputs:
%   predictor - [T x 1] predictor vector (e.g., stimulus boxcar, wheel speed)
%   TR - scalar, repetition time in seconds (time between frames)
%
% Output:
%   convolved - [T x 1] HRF-convolved predictor (same length as input)
%
% Method:
%   Uses SPM-style canonical HRF with parameters:
%   - Peak response: ~6 seconds
%   - Undershoot: ~16 seconds
%   - Double-gamma function shape
%
% Example:
%   % Apply HRF to stimulus
%   stim_hrf = hrf_conv(stim, TR);
%   
%   % Apply HRF to interaction
%   interaction_hrf = hrf_conv(stim .* wheel, TR);
%
% See also: create_predictors, get_stationary_stim

%% Input validation

if ~isvector(predictor)
    error('hrf_conv:InvalidInput', 'predictor must be a vector');
end

if nargin < 2 || isempty(TR)
    error('hrf_conv:MissingTR', 'TR (repetition time) must be provided');
end

if TR <= 0
    error('hrf_conv:InvalidTR', 'TR must be positive');
end

% Ensure column vector
predictor = predictor(:);
T = length(predictor);

%% Create canonical HRF

% Time vector for HRF (0 to 32 seconds is typical)
hrf_length = 32; % seconds
t = 0:TR:hrf_length;

% SPM canonical HRF parameters (double gamma function)
% First gamma (peak response)
a1 = 6;     % time to peak (seconds)
b1 = 1;     % dispersion

% Second gamma (undershoot)
a2 = 16;    % time to undershoot peak
b2 = 1;     % dispersion
c = 1/6;    % ratio of undershoot to response

% Double gamma HRF
hrf = (t.^a1 .* exp(-t/b1)) / (b1^a1 * gamma(a1+1)) - ...
      c * (t.^a2 .* exp(-t/b2)) / (b2^a2 * gamma(a2+1));

% Normalize to unit area (so convolution preserves magnitude)
hrf = hrf / sum(hrf);

%% Convolve predictor with HRF

% Use conv and truncate to original length
convolved_full = conv(predictor, hrf(:));
convolved = convolved_full(1:T);

%% Ensure output is column vector

convolved = convolved(:);

end
