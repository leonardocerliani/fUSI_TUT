function plot_stationary_trials(data, stim, wheel, stim_stationary, speed_threshold, do_plot)
% PLOT_STATIONARY_TRIALS - Visualize stationary vs running trial selection
%
% Creates a diagnostic plot showing which trials were classified as
% stationary vs running based on wheel speed criteria.
%
% Inputs:
%   data - struct from prepPDI.mat with fields:
%       .time - [T x 1] frame times
%       .stimInfo - table with startTime, endTime
%   stim - [T x 1] all stimulus trials (from create_predictors)
%   wheel - [T x 1] wheel speed in cm/s (from create_predictors)
%   stim_stationary - [T x 1] stationary stimulus trials only
%   speed_threshold - speed threshold used (e.g., 2.0 cm/s)
%   do_plot - boolean flag (true = create plot, false = skip)
%
% Example:
%   [stim, wheel, stim_stationary] = create_predictors(data, 2.0, 200);
%   plot_stationary_trials(data, stim, wheel, stim_stationary, 2.0, true);
%
% See also: create_predictors

%% Check if plotting is requested
if nargin < 6 || ~do_plot
    return;  % Skip plotting
end

%% Identify trial types
n_trials = height(data.stimInfo);
stationary_trials = [];
running_trials = [];

for trial = 1:n_trials
    trial_start = data.stimInfo.startTime(trial);
    trial_end = data.stimInfo.endTime(trial);
    
    % Check if this trial has any stationary frames
    frames_in_trial = (data.time >= trial_start) & (data.time <= trial_end);
    
    if any(stim_stationary(frames_in_trial))
        stationary_trials = [stationary_trials, trial];
    else
        running_trials = [running_trials, trial];
    end
end

%% Create figure
figure('Position', [100, 100, 1400, 800], 'Name', 'Stationary Trial Selection');

%% Top panel: Full timeseries
subplot(3, 1, 1);
hold on;

% Plot wheel speed
plot(data.time, wheel, 'k-', 'LineWidth', 1, 'DisplayName', 'Wheel speed');

% Mark all stimulus periods
stim_on = find(stim);
if ~isempty(stim_on)
    plot(data.time(stim_on), wheel(stim_on), 'r.', 'MarkerSize', 6, ...
         'DisplayName', 'All stimuli');
end

% Mark stationary stimulus periods
stat_on = find(stim_stationary);
if ~isempty(stat_on)
    plot(data.time(stat_on), wheel(stat_on), 'g.', 'MarkerSize', 8, ...
         'DisplayName', 'Stationary stimuli');
end

% Threshold line
yline(speed_threshold, 'r--', sprintf('Threshold = %.1f cm/s', speed_threshold), ...
      'LineWidth', 2, 'LabelHorizontalAlignment', 'left');

ylabel('Wheel Speed (cm/s)');
title(sprintf('Trial Classification: %d Stationary / %d Running (out of %d total)', ...
             length(stationary_trials), length(running_trials), n_trials));
legend('Location', 'best');
grid on;
xlim([data.time(1), data.time(end)]);

%% Middle panel: Trial-by-trial view (stationary)
subplot(3, 1, 2);
hold on;

if ~isempty(stationary_trials)
    for i = 1:length(stationary_trials)
        trial = stationary_trials(i);
        trial_start = data.stimInfo.startTime(trial);
        trial_end = data.stimInfo.endTime(trial);
        
        % Get wheel data during this trial
        in_trial = (data.time >= trial_start) & (data.time <= trial_end);
        times = data.time(in_trial);
        wheel_trial = wheel(in_trial);
        
        % Plot with different colors for each trial
        plot(times, wheel_trial, 'LineWidth', 1.5);
    end
    
    % Threshold line
    yline(speed_threshold, 'r--', sprintf('Threshold = %.1f cm/s', speed_threshold), ...
          'LineWidth', 2, 'LabelHorizontalAlignment', 'left');
    
    ylabel('Wheel Speed (cm/s)');
    title(sprintf('STATIONARY Trials (%d trials)', length(stationary_trials)));
    grid on;
    xlim([data.time(1), data.time(end)]);
else
    text(0.5, 0.5, 'NO STATIONARY TRIALS', ...
         'Units', 'normalized', 'HorizontalAlignment', 'center', ...
         'FontSize', 16, 'FontWeight', 'bold', 'Color', 'r');
    xlim([0, 1]);
    ylim([0, 1]);
end

%% Bottom panel: Trial-by-trial view (running)
subplot(3, 1, 3);
hold on;

if ~isempty(running_trials)
    for i = 1:length(running_trials)
        trial = running_trials(i);
        trial_start = data.stimInfo.startTime(trial);
        trial_end = data.stimInfo.endTime(trial);
        
        % Get wheel data during this trial
        in_trial = (data.time >= trial_start) & (data.time <= trial_end);
        times = data.time(in_trial);
        wheel_trial = wheel(in_trial);
        
        % Plot with different colors for each trial
        plot(times, wheel_trial, 'LineWidth', 1.5);
    end
    
    % Threshold line
    yline(speed_threshold, 'r--', sprintf('Threshold = %.1f cm/s', speed_threshold), ...
          'LineWidth', 2, 'LabelHorizontalAlignment', 'left');
    
    ylabel('Wheel Speed (cm/s)');
    xlabel('Time (s)');
    title(sprintf('RUNNING Trials (%d trials)', length(running_trials)));
    grid on;
    xlim([data.time(1), data.time(end)]);
else
    text(0.5, 0.5, 'NO RUNNING TRIALS (all stationary!)', ...
         'Units', 'normalized', 'HorizontalAlignment', 'center', ...
         'FontSize', 16, 'FontWeight', 'bold', 'Color', 'g');
    xlim([0, 1]);
    ylim([0, 1]);
end

%% Summary text
annotation('textbox', [0.15, 0.95, 0.7, 0.03], ...
           'String', sprintf('Speed threshold: %.1f cm/s | Stationary: %d/%d trials (%.1f%%)', ...
                           speed_threshold, length(stationary_trials), n_trials, ...
                           100*length(stationary_trials)/n_trials), ...
           'EdgeColor', 'none', 'FontSize', 12, 'FontWeight', 'bold', ...
           'HorizontalAlignment', 'center');

end
