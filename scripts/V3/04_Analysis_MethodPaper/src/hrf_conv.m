function convolved = hrf_conv(predictor, TR)
% HRF_CONV - Apply canonical HRF convolution to a predictor
%
% Convolves a predictor time series with a canonical hemodynamic response
% function (double-gamma HRF) using the exact parameters from Chaoyi's code.
% Useful for modeling BOLD/hemodynamic responses to neural events.
%
% Inputs:
%   predictor - [T x 1] predictor vector (e.g., stimulus boxcar, wheel speed)
%   TR - scalar, repetition time in seconds (time between frames)
%
% Output:
%   convolved - [T x 1] HRF-convolved predictor (same length as input)
%
% Method:
%   Uses SPM-style canonical HRF (from hemodynamicResponse.m) with parameters:
%   [2.4 8 0.8 0.9 6 0 16] where:
%     p(1) = 2.4  - delay of response (default 6)
%     p(2) = 8    - delay of undershoot (default 16)
%     p(3) = 0.8  - dispersion of response (default 1)
%     p(4) = 0.9  - dispersion of undershoot (default 1)
%     p(5) = 6    - ratio of response to undershoot (default 6)
%     p(6) = 0    - onset (default 0)
%     p(7) = 16   - length of kernel in seconds (default 32)
%
%   These parameters match those used in IndividualGLMRunningOrNot.m
%
% Example:
%   % Apply HRF to stimulus
%   stim_hrf = hrf_conv(stim, TR);
%   
%   % Apply HRF to interaction
%   interaction_hrf = hrf_conv(stim .* wheel, TR);
%
% See also: hemodynamicResponse, create_predictors

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

%% Create HRF using Chaoyi's parameters

% Parameters: [delay_response, delay_undershoot, disp_response, disp_undershoot, 
%              ratio, onset, kernel_length]
hrf_params = [2.4, 8, 0.8, 0.9, 6, 0, 16];

% - p(1) = 2.4 - delay of response (default 6)
% - p(2) = 8 - delay of undershoot (default 16)
% - p(3) = 0.8 - dispersion of response (default 1)
% - p(4) = 0.9 - dispersion of undershoot (default 1)
% - p(5) = 6 - ratio of response to undershoot (default 6)
% - p(6) = 0 - onset (default 0)
% - p(7) = 16 - length of kernel (default 32)



% Generate HRF using hemodynamicResponse function (from SPM)
hrf = hemodynamicResponse(TR, hrf_params);

%% Convolve predictor with HRF

% Use filter (equivalent to convolution, more efficient)
% filter(b, a, x) computes y where a(1)*y(n) = b(1)*x(n) + ... + b(nb+1)*x(n-nb)
% With a=1, this is just convolution: y(n) = b(1)*x(n) + b(2)*x(n-1) + ...
convolved = filter(hrf, 1, predictor);

%% Ensure output is column vector

convolved = convolved(:);

end
