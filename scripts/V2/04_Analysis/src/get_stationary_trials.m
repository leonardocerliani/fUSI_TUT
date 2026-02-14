function stim_stationary = get_stationary_trials(data, speed_threshold, duration_threshold)
% GET_STATIONARY_TRIALS - Paper method for stationary stimulus selection
%
% Implements trial-level filtering: keeps trials where wheel velocity 
% exceeds threshold for less than duration threshold during stimulation.
%
% Inputs:
%   data - struct from prepPDI.mat with fields:
%       .time - [T x 1] frame times
%       .stimInfo - table with startTime, endTime
%       .wheelInfo - table with time, wheelspeed
%   speed_threshold - speed limit in cm/s (default: 2.0)
%   duration_threshold - max movement duration in ms (default: 200)
%
% Output:
%   stim_stationary - [T x 1] stimulus predictor with only valid trials
%                     (1 during stationary trials, 0 otherwise)
%
% Paper criterion: "trials in which wheel velocity exceeded 2 cm/s 
% for less than 200ms during the stimulation period"
%
% Example:
%   stim_stationary = get_stationary_trials(data, 2.0, 200);
%
% See also: create_predictors

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
        error('get_stationary_trials:MissingField', ...
              'Required field "%s" not found in data structure', required_fields{i});
    end
end

%% Initialize output
T = length(data.time);
stim_stationary = zeros(T, 1);

%% Process each stimulus trial
n_trials = height(data.stimInfo);
n_valid = 0;

for trial = 1:n_trials
    trial_start = data.stimInfo.startTime(trial);
    trial_end = data.stimInfo.endTime(trial);
    
    % Find wheel measurements during this trial
    in_trial = (data.wheelInfo.time >= trial_start) & ...
               (data.wheelInfo.time <= trial_end);
    
    wheel_during_trial = abs(data.wheelInfo.wheelspeed(in_trial));
    times_during_trial = data.wheelInfo.time(in_trial);
    
    % Check if any wheel measurements exist for this trial
    if isempty(wheel_during_trial)
        continue;  % Skip trial with no wheel data
    end
    
    % Identify movement periods (wheel > threshold)
    is_moving = (wheel_during_trial > speed_threshold);
    
    % Calculate total duration of movement
    % Method: sum intervals where movement occurs
    if any(is_moving) && length(times_during_trial) > 1
        % Calculate time intervals
        dt = diff(times_during_trial);  % Time between samples
        
        % Sum intervals where movement occurs
        % Use is_moving(1:end-1) since dt has length n-1
        movement_duration_ms = sum(dt(is_moving(1:end-1))) * 1000;
    else
        movement_duration_ms = 0;
    end
    
    % Apply paper criterion: keep trial if movement duration < threshold
    if movement_duration_ms < duration_threshold
        % Mark this trial as valid (set corresponding frames to 1)
        frames_in_trial = (data.time >= trial_start) & (data.time <= trial_end);
        stim_stationary(frames_in_trial) = 1;
        n_valid = n_valid + 1;
    end
end

%% Summary (optional - can be commented out for silent operation)
fprintf('  Stationary trial selection:\n');
fprintf('    Total trials: %d\n', n_trials);
fprintf('    Valid trials: %d (%.1f%%)\n', n_valid, 100*n_valid/n_trials);
fprintf('    Criterion: wheel > %.1f cm/s for < %d ms\n', ...
        speed_threshold, duration_threshold);

end
