function [stim, wheel, stim_stationary] = create_predictors(data, speed_threshold, duration_threshold, use_chaoyi_method)
% CREATE_PREDICTORS - Create all predictors from fUSI data
%
% Takes preprocessed fUSI data structure and creates frame-aligned
% predictors for stimulus and wheel speed, including stationary trial selection.
%
% Inputs:
%   data - struct from prepPDI.mat with fields:
%       .time - [1 x T] frame timestamps
%       .stimInfo - table with startTime, endTime
%       .wheelInfo - table with time, wheelspeed (raw encoder counts/sec)
%   speed_threshold - speed limit in cm/s for stationary trials (default: 2.0)
%   duration_threshold - max movement duration in ms for stationary trials (default: 200)
%   use_chaoyi_method - if true, use Chaoyi's original implementation (default: false)
%
% Outputs:
%   stim - [T x 1] binary stimulus boxcar for all trials (1 = ON, 0 = OFF)
%   wheel - [T x 1] wheel speed in cm/s resampled to frame times
%   stim_stationary - [T x 1] stimulus boxcar for stationary trials only
%
% Paper criterion for stationary trials: "trials in which wheel velocity 
% exceeded 2 cm/s for less than 200ms during the stimulation period"
%
% Example:
%   [stim, wheel, stim_stationary] = create_predictors(data, 2.0, 200);
%   [stim, wheel, stim_stationary] = create_predictors(data, 2.0, 200, true); % Use Chaoyi's method
%
% See also: hrf_conv, prepare_data_matrix

%% Handle optional inputs
if nargin < 2 || isempty(speed_threshold)
    speed_threshold = 2.0;  % cm/s (paper default)
end

if nargin < 3 || isempty(duration_threshold)
    duration_threshold = 200;  % ms (paper default)
end

if nargin < 4 || isempty(use_chaoyi_method)
    use_chaoyi_method = false;  % Use refactored method by default
end

%% Validate inputs
required_fields = {'time', 'stimInfo', 'wheelInfo'};
for i = 1:length(required_fields)
    if ~isfield(data, required_fields{i})
        error('create_predictors:MissingField', ...
              'Required field "%s" not found in data structure', required_fields{i});
    end
end

%% Get timing info
T = length(data.time);
frame_times = data.time(:);  % Ensure column vector

%% Convert raw wheelspeed to cm/s (ONCE, at the source)
% data.wheelInfo.wheelspeed contains wheel counts *per second* (NB!)
% - the wheel has 1024 counts per rotation.
% - wheel radius: 9.5cm -> circumference: 2*π*r = 19*π cm.
% - therefore each count is (19*pi/1024) ≈ 0.0584 cm of linear movement.
% - the speed in cm/s is given by [wheelspeed] × [cm/count] = [cm/s]
%   where wheelspeed is in counts per second

wheel_cm_s = data.wheelInfo.wheelspeed * (19*pi/1024);

%% Create stimulus boxcar for ALL trials
stim = zeros(T, 1);

nStimuli = height(data.stimInfo);
for i = 1:nStimuli
    stim_start = data.stimInfo.startTime(i);
    stim_end = data.stimInfo.endTime(i);
    
    % Mark frames during stimulus as 1
    frames_during_stim = (frame_times >= stim_start) & (frame_times <= stim_end);
    stim(frames_during_stim) = 1;
end

%% Create stimulus boxcar for STATIONARY trials only
% Trial-level filtering: check cumulative movement during each trial
% NB: this was refactored from IndividualGLMRunningOrNot.m

if use_chaoyi_method
    % Use Chaoyi's original implementation for comparison
    fprintf('  Using Chaoyi''s original method for stationary trial selection\n');
    [stim_stationary, n_valid] = select_stationary_chaoyi(data, frame_times, nStimuli, speed_threshold, duration_threshold);
else
    % Use refactored implementation (default)
    [stim_stationary, n_valid] = select_stationary_refactored(data, wheel_cm_s, frame_times, nStimuli, speed_threshold, duration_threshold);
end

%% Summary output
fprintf('  Stationary trial selection:\n');
fprintf('    Total trials: %d\n', nStimuli);
fprintf('    Valid stationary trials: %d (%.1f%%)\n', n_valid, 100*n_valid/nStimuli);
fprintf('    Criterion: wheel > %.1f cm/s for < %d ms\n', ...
        speed_threshold, duration_threshold);

%% Resample wheel speed to frame times
% Interpolate the converted (cm/s) wheel data to match imaging frame times

wheel = interp1(data.wheelInfo.time, ...
                wheel_cm_s, ...  % Already converted to cm/s
                frame_times, ...
                'linear');

% Handle any NaN values at edges
if any(isnan(wheel))
    wheel = fillmissing(wheel, 'nearest');
end

% Take absolute value (magnitude regardless of direction)
wheel = abs(wheel);

% Ensure column vector
wheel = wheel(:);

end

%% ========================================================================
%  LOCAL HELPER FUNCTIONS
%  ========================================================================

function [stim_stationary, n_valid] = select_stationary_chaoyi(data, frame_times, nStimuli, speed_threshold, duration_threshold)
% SELECT_STATIONARY_CHAOYI - Chaoyi's original implementation
% 
% This is the exact implementation from IndividualGLMRunningOrNot.m
% for comparison and verification purposes.
%
% Now accepts speed_threshold (cm/s) and duration_threshold (ms) as parameters
% instead of using hardcoded values (35 counts/sec and 0.2 sec)

% Convert speed_threshold from cm/s to encoder counts/sec
% Conversion: counts/sec = (cm/s) / (19*pi/1024)
speed_threshold_counts = speed_threshold / (19*pi/1024);

% Convert duration_threshold from ms to seconds
duration_threshold_sec = duration_threshold / 1000;

stim_stationary = zeros(length(frame_times), 1);
runningTrialIndex = [];

for itrl = 1:nStimuli
    % Extract wheel data during this trial (uses raw encoder counts)
    trialRunning = data.wheelInfo.wheelspeed(...
        data.wheelInfo.time >= data.stimInfo.startTime(itrl) & ...
        data.wheelInfo.time <= data.stimInfo.endTime(itrl));
    
    % Calculate sampling interval using GLOBAL wheelInfo.time
    timeDev = mean(diff(data.wheelInfo.time));
    
    % Find connected components above threshold
    % Now uses parameter instead of hardcoded 35
    CC = bwconncomp(abs(trialRunning) > speed_threshold_counts);
    CCsize = cellfun(@(x) numel(x), CC.PixelIdxList);
    
    % Reject trial if ANY component exceeds duration threshold
    % Now uses parameter instead of hardcoded 0.2
    if any(CCsize > duration_threshold_sec/timeDev)
        runningTrialIndex = [runningTrialIndex, itrl];
    end
end

% Mark stationary trials (inverse of running trials)
stationary_trials = setdiff(1:nStimuli, runningTrialIndex);
for trial = stationary_trials
    frames = (frame_times >= data.stimInfo.startTime(trial)) & ...
             (frame_times <= data.stimInfo.endTime(trial));
    stim_stationary(frames) = 1;
end

n_valid = length(stationary_trials);

end

function [stim_stationary, n_valid] = select_stationary_refactored(data, wheel_cm_s, frame_times, nStimuli, speed_threshold, duration_threshold)
% SELECT_STATIONARY_REFACTORED - Current refactored implementation
%
% This is the refactored version with improved code organization,
% explicit units (cm/s), and trial-specific timeDev calculation.

stim_stationary = zeros(length(frame_times), 1);
n_valid = 0;

for trial = 1:nStimuli
    trial_start = data.stimInfo.startTime(trial);
    trial_end = data.stimInfo.endTime(trial);
    
    % Find wheel measurements during this trial (high-res data, ~55 Hz)
    in_trial = (data.wheelInfo.time >= trial_start) & ...
               (data.wheelInfo.time <= trial_end);
    
    wheel_during_trial = abs(wheel_cm_s(in_trial));  % Now in cm/s
    
    % Duration of one sample (trial-specific)
    times_during_trial = data.wheelInfo.time(in_trial);
    timeDev = mean(diff(times_during_trial));
    
    % Check if any wheel measurements exist for this trial
    if isempty(wheel_during_trial)
        continue;  % Skip trial with no wheel data
    end
    
    % Find connected components (continuous periods above threshold)
    CC = bwconncomp(wheel_during_trial > speed_threshold);
    CCsize = cellfun(@(x) numel(x), CC.PixelIdxList);
    
    % Calculate maximum continuous duration
    max_continuous_duration_ms = 0;
    if ~isempty(CCsize)
        max_continuous_duration_ms = max(CCsize) * timeDev * 1000;
    end
    
    % Keep trial only if NO continuous period exceeds threshold
    if max_continuous_duration_ms < duration_threshold
        frames_in_trial = (frame_times >= trial_start) & (frame_times <= trial_end);
        stim_stationary(frames_in_trial) = 1;
        n_valid = n_valid + 1;
    end
end

end
