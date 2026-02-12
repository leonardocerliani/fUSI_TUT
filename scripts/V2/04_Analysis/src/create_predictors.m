function [stim, wheel] = create_predictors(data)
% CREATE_PREDICTORS - Create basic predictors from fUSI data
%
% Takes preprocessed fUSI data structure and creates frame-aligned
% predictors for stimulus and wheel speed.
%
% Inputs:
%   data - struct from prepPDI.mat with fields:
%       .time - [1 x T] frame timestamps
%       .stimInfo - table with startTime, endTime
%       .wheelInfo - table with time, wheelspeed
%
% Outputs:
%   stim - [T x 1] binary stimulus boxcar (1 = ON, 0 = OFF)
%   wheel - [T x 1] wheel speed resampled to frame times
%
% Example:
%   data = load('prepPDI.mat');
%   [stim, wheel] = create_predictors(data.data);
%
% See also: get_stationary_stim, HRF

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

%% Create stimulus boxcar

stim = zeros(T, 1);

nStimuli = height(data.stimInfo);
for i = 1:nStimuli
    stim_start = data.stimInfo.startTime(i);
    stim_end = data.stimInfo.endTime(i);
    
    % Mark frames during stimulus as 1
    frames_during_stim = (frame_times >= stim_start) & (frame_times <= stim_end);
    stim(frames_during_stim) = 1;
end

%% Resample wheel speed to frame times

wheel = interp1(data.wheelInfo.time, ...
                data.wheelInfo.wheelspeed, ...
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
