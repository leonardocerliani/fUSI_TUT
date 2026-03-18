function [wheelspeed_resampled, stim_boxcar] = align_timing_to_frames(prepPDI_path)
% ALIGN_TIMING_TO_FRAMES - Resample wheel and stimulus timing to match PDI frame times
%
% Syntax:
%   [wheelspeed_resampled, stim_boxcar] = align_timing_to_frames(prepPDI_path)
%   [wheelspeed_resampled, stim_boxcar] = align_timing_to_frames()  % Interactive mode
%
% Description:
%   Takes preprocessed PDI data and creates frame-aligned vectors for wheel speed
%   and stimulus timing. This gives you one value per frame (like in fMRI analysis).
%
%   - Wheel speed: Linear interpolation from high-res sensor data to frame times
%   - Stimulus: Binary boxcar (1 = stimulus ON, 0 = stimulus OFF)
%
% Inputs:
%   prepPDI_path - (optional) Full path to prepPDI.mat file
%                  If not provided, prompts user to select file
%
% Outputs:
%   wheelspeed_resampled - [N x 1] vector of wheel speed, one value per frame
%                          where N = number of frames (length of data.time)
%   stim_boxcar          - [N x 1] binary vector (1 = stimulus ON, 0 = OFF)
%
% Example:
%   % Interactive mode
%   [wheel, stim] = align_timing_to_frames();
%
%   % Provide path directly
%   [wheel, stim] = align_timing_to_frames('/path/to/prepPDI.mat');
%
%   % Use the vectors for analysis
%   plot(data.time, wheel);  % Plot wheel speed over time
%   figure; plot(data.time, stim);  % Plot stimulus timing
%
% See also: interp1

%% Handle input arguments

if nargin < 1 || isempty(prepPDI_path)
    fprintf('\n>>> Please select the prepPDI.mat file\n');
    [filename, pathname] = uigetfile('*.mat', 'Select prepPDI.mat file');
    if filename == 0
        error('File selection cancelled.');
    end
    prepPDI_path = fullfile(pathname, filename);
end

% Validate file exists
if ~isfile(prepPDI_path)
    error('File not found: %s', prepPDI_path);
end

%% Load preprocessed data

fprintf('=== Loading Preprocessed Data ===\n');
fprintf('File: %s\n', prepPDI_path);

% Load the data structure
loaded = load(prepPDI_path);

% Handle different possible structures:
% Case 1: loaded.data.PDI exists (saved as 'data' variable)
% Case 2: loaded.PDI exists (saved as 'PDI' variable)
% Case 3: loaded directly contains the fields (multiple variables saved)
if isfield(loaded, 'data')
    PDI = loaded.data;
    fprintf('Loaded successfully (data structure).\n');
elseif isfield(loaded, 'PDI')
    PDI = loaded.PDI;
    fprintf('Loaded successfully (PDI structure).\n');
else
    % Assume the loaded struct itself contains all fields
    PDI = loaded;
    fprintf('Loaded successfully (direct fields).\n');
end

% Verify we have the required fields
required_fields = {'time', 'PDI', 'wheelInfo', 'stimInfo'};
for i = 1:length(required_fields)
    if ~isfield(PDI, required_fields{i})
        error('Required field "%s" not found in loaded data. Available fields: %s', ...
              required_fields{i}, strjoin(fieldnames(PDI), ', '));
    end
end

fprintf('Number of frames: %d\n', length(PDI.time));
fprintf('Number of wheel samples: %d\n', length(PDI.wheelInfo.time));
fprintf('Number of stimulus events: %d\n', length(PDI.stimInfo.startTime));
fprintf('\n');

%% Resample wheel speed to frame times

fprintf('=== Resampling Wheel Speed ===\n');

% Use linear interpolation to map wheel speed onto PDI frame times
wheelspeed_resampled = interp1(PDI.wheelInfo.time, ...
                               PDI.wheelInfo.wheelspeed, ...
                               PDI.time, ...
                               'linear');

% Handle any NaN values at edges (extrapolation)
% Fill with nearest valid value
if any(isnan(wheelspeed_resampled))
    fprintf('Warning: %d NaN values found (edge effects)\n', sum(isnan(wheelspeed_resampled)));
    fprintf('Filling with nearest neighbor...\n');
    wheelspeed_resampled = fillmissing(wheelspeed_resampled, 'nearest');
end

% Take absolute value since negative values just indicate reversed rotation
% We want magnitude regardless of direction
wheelspeed_resampled = abs(wheelspeed_resampled);
fprintf('Applied absolute value (negative = reversed rotation direction)\n');

fprintf('Wheel speed resampled: %d values → %d values\n', ...
        length(PDI.wheelInfo.time), length(wheelspeed_resampled));
fprintf('Mean wheel speed: %.2f\n', mean(wheelspeed_resampled));
fprintf('Std wheel speed: %.2f\n', std(wheelspeed_resampled));
fprintf('\n');

%% Create stimulus boxcar

fprintf('=== Creating Stimulus Boxcar ===\n');

% Initialize boxcar with zeros
nFrames = length(PDI.time);
stim_boxcar = zeros(nFrames, 1);

% For each stimulus event, mark frames during stimulus as 1
nStimuli = length(PDI.stimInfo.startTime);
total_stim_frames = 0;

for i = 1:nStimuli
    % Find frames during this stimulus
    stim_start = PDI.stimInfo.startTime(i);
    stim_end = PDI.stimInfo.endTime(i);
    
    % Mark frames in this time window as 1
    frames_during_stim = (PDI.time >= stim_start) & (PDI.time <= stim_end);
    stim_boxcar(frames_during_stim) = 1;
    
    % Count for reporting
    n_frames_this_stim = sum(frames_during_stim);
    total_stim_frames = total_stim_frames + n_frames_this_stim;
    
    fprintf('  Stimulus %d: %.2f - %.2f sec (%d frames)\n', ...
            i, stim_start, stim_end, n_frames_this_stim);
end

fprintf('\nTotal stimulus frames: %d / %d (%.1f%%)\n', ...
        total_stim_frames, nFrames, 100*total_stim_frames/nFrames);
fprintf('\n');

%% Visualization

fprintf('=== Creating Visualization ===\n');

figure('Position', [100 100 1200 600]);

% Subplot 1: Wheel speed
subplot(2,1,1);
plot(PDI.time, wheelspeed_resampled, 'b-', 'LineWidth', 1.5);
xlabel('Time (seconds)');
ylabel('Wheel Speed');
title('Wheel Speed (Resampled to Frame Times)');
grid on;

% Subplot 2: Stimulus boxcar
subplot(2,1,2);
plot(PDI.time, stim_boxcar, 'r-', 'LineWidth', 1.5);
xlabel('Time (seconds)');
ylabel('Stimulus (ON=1, OFF=0)');
title('Stimulus Boxcar');
ylim([-0.1 1.1]);
grid on;

fprintf('Visualization complete.\n\n');

%% Summary

fprintf('╔════════════════════════════════════════════════════════════════╗\n');
fprintf('║                    ALIGNMENT SUMMARY                           ║\n');
fprintf('╚════════════════════════════════════════════════════════════════╝\n');
fprintf('  Frame-aligned vectors created:\n');
fprintf('    - wheelspeed_resampled: [%d x 1]\n', length(wheelspeed_resampled));
fprintf('    - stim_boxcar:          [%d x 1]\n', length(stim_boxcar));
fprintf('\n');
fprintf('  Both vectors match PDI frame timing:\n');
fprintf('    - Number of frames: %d\n', nFrames);
fprintf('    - Sampling rate: 5 Hz\n');
fprintf('    - Total duration: %.2f seconds\n', PDI.time(end) - PDI.time(1));
fprintf('\n');
fprintf('  You can now use these vectors for analysis!\n');
fprintf('  Example: frame 100 corresponds to:\n');
if nFrames >= 100
    fprintf('    - Time: %.2f seconds\n', PDI.time(100));
    fprintf('    - Wheel speed: %.2f\n', wheelspeed_resampled(100));
    fprintf('    - Stimulus state: %d\n', stim_boxcar(100));
end
fprintf('\n');

end
