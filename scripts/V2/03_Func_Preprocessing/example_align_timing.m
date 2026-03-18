% EXAMPLE_ALIGN_TIMING - Demonstration of align_timing_to_frames function
%
% This script shows how to use align_timing_to_frames to create
% frame-aligned vectors for wheel speed and stimulus timing from
% preprocessed fUSI data (prepPDI.mat).

%% Example 1: Interactive mode (prompts for file selection)

fprintf('=== Example 1: Interactive Mode ===\n');
fprintf('This will prompt you to select prepPDI.mat file\n\n');

% Uncomment to run:
% [wheel, stim] = align_timing_to_frames();

%% Example 2: Provide path directly

fprintf('=== Example 2: Direct Path ===\n');
fprintf('Provide the path to prepPDI.mat directly\n\n');

% Example path (adjust to your actual path):
prepPDI_path = '/Users/leonardo/Dropbox/fUSI/fUSI_TUT/data/Data_analysis/ses-231215/run-115047-func/prepPDI.mat';

% Uncomment to run with your path:
[wheel, stim] = align_timing_to_frames(prepPDI_path);
c
%% Example 3: Using the aligned vectors for analysis

fprintf('=== Example 3: Using Aligned Vectors ===\n');
fprintf('Once you have the vectors, you can use them for analysis\n\n');

% Example analysis code (already runs since Example 2 is uncommented):

% Load the data to get time vector
loaded = load(prepPDI_path);
PDI = loaded.data;  % prepPDI.mat saves as 'data' variable

% Now you have frame-aligned vectors:
% - PDI.time: [3652 x 1] time in seconds
% - wheel:    [3652 x 1] wheel speed at each frame
% - stim:     [3652 x 1] stimulus state (0 or 1) at each frame

% Plot wheel speed colored by stimulus state
figure;
hold on;
% Non-stimulus periods in blue
idx_no_stim = (stim == 0);
plot(PDI.time(idx_no_stim), wheel(idx_no_stim), 'b.', 'MarkerSize', 8);
% Stimulus periods in red
idx_stim = (stim == 1);
plot(PDI.time(idx_stim), wheel(idx_stim), 'r.', 'MarkerSize', 8);
xlabel('Time (seconds)');
ylabel('Wheel Speed');
title('Wheel Speed During vs Outside Stimulus');
legend('No Stimulus', 'Stimulus ON');
grid on;

% Calculate mean wheel speed during vs outside stimulus
mean_wheel_stim = mean(wheel(stim == 1));
mean_wheel_nostim = mean(wheel(stim == 0));
fprintf('Mean wheel speed during stimulus: %.2f\n', mean_wheel_stim);
fprintf('Mean wheel speed outside stimulus: %.2f\n', mean_wheel_nostim);

% Extract brain data during stimulus
% PDI.PDI is [Y x X x nFrames]
brain_during_stim = PDI.PDI(:, :, stim == 1);
fprintf('Brain data during stimulus: [%d x %d x %d]\n', size(brain_during_stim));

% Calculate stimulus-locked average response
% Find stimulus onsets
stim_onsets = find(diff([0; stim]) == 1);  % Frames where stimulus starts
fprintf('Found %d stimulus onsets at frames: %s\n', length(stim_onsets), mat2str(stim_onsets'));

% For each stimulus, extract a window (e.g., -2 to +10 seconds)
window_before = 2;  % seconds before stimulus
window_after = 10;  % seconds after stimulus
sampling_rate = 5;  % Hz (from preprocessing)
frames_before = window_before * sampling_rate;  % 10 frames
frames_after = window_after * sampling_rate;    % 50 frames

% Extract and average responses
all_responses = [];
for i = 1:length(stim_onsets)
    onset_frame = stim_onsets(i);
    start_frame = onset_frame - frames_before;
    end_frame = onset_frame + frames_after;
    
    % Check bounds
    if start_frame >= 1 && end_frame <= size(PDI.PDI, 3)
        response = PDI.PDI(:, :, start_frame:end_frame);
        all_responses = cat(4, all_responses, response);
    end
end

% Calculate mean stimulus-locked response
mean_response = mean(all_responses, 4);
fprintf('Mean stimulus-locked response: [%d x %d x %d]\n', size(mean_response));

% Plot mean timecourse for a single voxel
voxel_y = 50;
voxel_x = 50;
timecourse = squeeze(mean_response(voxel_y, voxel_x, :));
time_axis = (-frames_before:frames_after) / sampling_rate;

figure;
plot(time_axis, timecourse, 'k-', 'LineWidth', 2);
xline(0, 'r--', 'Stimulus Onset', 'LineWidth', 1.5);
xlabel('Time from stimulus onset (seconds)');
ylabel('Signal (% change)');
title(sprintf('Stimulus-Locked Response at Voxel (%d, %d)', voxel_y, voxel_x));
grid on;
%

%% Tips

fprintf('\n╔════════════════════════════════════════════════════════════════╗\n');
fprintf('║                          TIPS                                  ║\n');
fprintf('╚════════════════════════════════════════════════════════════════╝\n');
fprintf('1. Both wheel and stim vectors have same length as PDI.time\n');
fprintf('2. Use logical indexing: PDI.PDI(:,:,stim==1) for stimulus frames\n');
fprintf('3. Find stimulus onsets: find(diff([0; stim]) == 1)\n');
fprintf('4. Combine with wheel: frames_moving_stim = (wheel>threshold) & (stim==1)\n');
fprintf('5. Save vectors: save(''aligned_timing.mat'', ''wheel'', ''stim'')\n');
fprintf('\n');
