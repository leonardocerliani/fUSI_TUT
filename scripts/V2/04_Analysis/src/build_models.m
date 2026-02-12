function models = build_models(data, stim_boxcar, wheelspeed, options)
% BUILD_MODELS - Create GLM model specifications for fUSI analysis
%
% Builds multiple GLM models with different combinations of predictors.
% Currently implements M1_running_all as the primary model.
%
% Inputs:
%   data - struct from prepPDI.mat with fields:
%       .time - [1 x T] frame timestamps
%       .motionParams - [T x 2] motion parameters (optional)
%   stim_boxcar - [T x 1] stimulus boxcar (1 = ON, 0 = OFF)
%   wheelspeed - [T x 1] wheel speed (resampled to frame times)
%   options - struct with fields:
%       .use_hrf - logical, apply HRF convolution to stimulus? (default: false)
%       .use_drift - logical, include drift regressors? (default: false)
%       .use_motion - logical, include motion parameters? (default: false)
%       .use_derivatives - logical, include temporal derivatives? (default: false)
%       .high_pass - scalar, high-pass cutoff in seconds (default: 0 = none)
%       .zscore_predictors - logical, z-score continuous predictors? (default: true)
%
% Outputs:
%   models - struct array with fields:
%       .name - model name (e.g., 'M1_running_all')
%       .X - [T x p] design matrix
%       .regressor_names - {1 x p} cell array of regressor names
%
% Example:
%   options.use_hrf = false;
%   options.use_drift = false;
%   options.use_motion = false;
%   options.zscore_predictors = true;
%   models = build_models(data, stim_boxcar, wheelspeed, options);
%
% See also: glm, align_timing_to_frames, hrf

%% Handle optional arguments

if nargin < 4 || isempty(options)
    options = struct();
end

% Set defaults
if ~isfield(options, 'use_hrf'), options.use_hrf = false; end
if ~isfield(options, 'use_drift'), options.use_drift = false; end
if ~isfield(options, 'use_motion'), options.use_motion = false; end
if ~isfield(options, 'use_derivatives'), options.use_derivatives = false; end
if ~isfield(options, 'high_pass'), options.high_pass = 0; end
if ~isfield(options, 'zscore_predictors'), options.zscore_predictors = true; end

%% Get timing information

T = length(data.time);
TR = median(diff(data.time));  % Compute TR from frame times

%% Validate inputs

if length(stim_boxcar) ~= T
    error('build_models:DimensionMismatch', ...
          'stim_boxcar must have %d elements to match frame times', T);
end

if length(wheelspeed) ~= T
    error('build_models:DimensionMismatch', ...
          'wheelspeed must have %d elements to match frame times', T);
end

% Ensure column vectors
stim_boxcar = stim_boxcar(:);
wheelspeed = wheelspeed(:);

fprintf('=== Building GLM Models ===\n');
fprintf('Number of timepoints: %d\n', T);
fprintf('TR: %.3f seconds\n', TR);
fprintf('Options:\n');
fprintf('  - HRF convolution: %s\n', bool2str(options.use_hrf));
fprintf('  - Drift regressors: %s\n', bool2str(options.use_drift));
fprintf('  - Motion parameters: %s\n', bool2str(options.use_motion));
fprintf('  - Temporal derivatives: %s\n', bool2str(options.use_derivatives));
fprintf('  - Z-score predictors: %s\n', bool2str(options.zscore_predictors));
fprintf('\n');

%% Prepare stimulus regressor

if options.use_hrf
    fprintf('Convolving stimulus with HRF...\n');
    stim_reg = hrf(stim_boxcar, TR, 'canonical');
else
    stim_reg = stim_boxcar;
end

% Z-score if requested
if options.zscore_predictors
    stim_reg = zscore(stim_reg);
end

%% Prepare wheel speed regressor

wheel_reg = wheelspeed;

% Z-score if requested
if options.zscore_predictors
    wheel_reg = zscore(wheel_reg);
end

%% Prepare optional regressors

% Motion parameters
if options.use_motion && isfield(data, 'motionParams')
    motion_reg = data.motionParams;  % [T x 2]
    if options.zscore_predictors
        motion_reg = zscore(motion_reg);
    end
else
    motion_reg = [];
end

% Drift regressors
if options.use_drift
    drift_reg = create_drift_regressors(T, TR, options.high_pass);
else
    drift_reg = [];
end

% Temporal derivatives
if options.use_derivatives
    stim_deriv = [0; diff(stim_reg)];
    wheel_deriv = [0; diff(wheel_reg)];
    if options.zscore_predictors
        stim_deriv = zscore(stim_deriv);
        wheel_deriv = zscore(wheel_deriv);
    end
else
    stim_deriv = [];
    wheel_deriv = [];
end

%% Build Model: M1_running_all

model_idx = 1;

% Build design matrix
X = [stim_reg, wheel_reg];
reg_names = {'stimulus', 'wheelspeed'};

% Add derivatives if requested
if options.use_derivatives
    X = [X, stim_deriv, wheel_deriv];
    reg_names = [reg_names, {'stimulus_deriv', 'wheelspeed_deriv'}];
end

% Add motion if requested
if ~isempty(motion_reg)
    X = [X, motion_reg];
    reg_names = [reg_names, {'motion1', 'motion2'}];
end

% Add drift if requested
if ~isempty(drift_reg)
    n_drift = size(drift_reg, 2);
    X = [X, drift_reg];
    drift_names = arrayfun(@(i) sprintf('drift%d', i), 1:n_drift, 'UniformOutput', false);
    reg_names = [reg_names, drift_names];
end

% Add constant term (intercept)
X = [X, ones(T, 1)];
reg_names = [reg_names, {'constant'}];

% Package model
models(model_idx).name = 'M1_running_all';
models(model_idx).X = X;
models(model_idx).regressor_names = reg_names;

fprintf('Model built: %s\n', models(model_idx).name);
fprintf('  Design matrix: [%d x %d]\n', size(X, 1), size(X, 2));
fprintf('  Regressors: %s\n', strjoin(reg_names, ', '));
fprintf('\n');

%% Future models (placeholders)

% Add more models here as specified by user
% Example:
% models(2).name = 'M2_stimulus_only';
% models(2).X = [stim_reg, ones(T,1)];
% models(2).regressor_names = {'stimulus', 'constant'};

fprintf('Total models created: %d\n\n', length(models));

end

%% Helper function: create drift regressors

function drift_reg = create_drift_regressors(T, TR, high_pass)
% Create DCT-based drift regressors for high-pass filtering
%
% Inputs:
%   T - number of timepoints
%   TR - repetition time in seconds
%   high_pass - cutoff in seconds (0 = no filtering)
%
% Output:
%   drift_reg - [T x n_drift] drift regressors

if high_pass <= 0
    drift_reg = [];
    return;
end

% Compute number of drift terms needed
total_time = T * TR;
n_drift = floor(2 * total_time / high_pass);

% Create DCT basis (discrete cosine transform)
drift_reg = zeros(T, n_drift);
for k = 1:n_drift
    drift_reg(:, k) = cos(pi * (2*(0:T-1)' + 1) * k / (2*T));
end

% Orthonormalize
drift_reg = orth(drift_reg);

fprintf('Created %d drift regressors (high-pass cutoff: %.1f sec)\n', n_drift, high_pass);

end

%% Helper function: bool to string

function str = bool2str(val)
if val
    str = 'yes';
else
    str = 'no';
end
end
