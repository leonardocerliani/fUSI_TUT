function [stim, wheel, stim_stationary] = create_predictors(data, speed_threshold, duration_threshold)
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
%
% See also: hrf_conv, prepare_data_matrix

%% Handle optional inputs
if nargin < 2 || isempty(speed_threshold)
    speed_threshold = 2.0;  % cm/s (paper default)
end

if nargin < 3 || isempty(duration_threshold)
    duration_threshold = 200;  % ms (paper default)
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

stim_stationary = zeros(T, 1);
n_valid = 0;

for trial = 1:nStimuli
    trial_start = data.stimInfo.startTime(trial);
    trial_end = data.stimInfo.endTime(trial);
    
    % Find wheel measurements during this trial (high-res data, ~55 Hz)
    in_trial = (data.wheelInfo.time >= trial_start) & ...
               (data.wheelInfo.time <= trial_end);
    
    wheel_during_trial = abs(wheel_cm_s(in_trial));  % Now in cm/s
    times_during_trial = data.wheelInfo.time(in_trial);
    
    % Check if any wheel measurements exist for this trial
    if isempty(wheel_during_trial)
        continue;  % Skip trial with no wheel data
    end
    
    % Find connected components (continuous periods above threshold)
    % This uses bwconncomp to identify separate "runs" of movement
    CC = bwconncomp(wheel_during_trial > speed_threshold);
    CCsize = cellfun(@(x) numel(x), CC.PixelIdxList);
    
    % Calculate duration of each connected component
    timeDev = mean(diff(times_during_trial));
    
    % Paper criterion: reject trial if ANY continuous period > 200ms
    % (NOT the sum of all periods!)
    max_continuous_duration_ms = 0;
    if ~isempty(CCsize)
        max_continuous_duration_ms = max(CCsize) * timeDev * 1000;
    end
    
    % Keep trial only if NO continuous period exceeds threshold
    if max_continuous_duration_ms < duration_threshold
        % Mark this trial as valid (set corresponding frames to 1)
        frames_in_trial = (frame_times >= trial_start) & (frame_times <= trial_end);
        stim_stationary(frames_in_trial) = 1;
        n_valid = n_valid + 1;
    end
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
