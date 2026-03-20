function view_glm_results(all_results, data, model_name)
% VIEW_GLM_RESULTS - Interactive viewer for GLM results
%
% Click on eta² map to see voxel timeseries, model fit, and predictors
%
% Inputs:
%   all_results - struct from do_analysis_methods_paper.m
%   data - original data struct with PDI, bmask, time
%   model_name - string, e.g., 'M1', 'M2', 'M3'
%
% Example:
%   load('prepPDI.mat');
%   load('all_results.mat');
%   view_glm_results(all_results, data, 'M1');
%
% Click on a voxel to see:
%   - Raw signal vs model fit
%   - All predictors (as they appear in the model)

%% Get model results
model = all_results.(model_name);

% Check if model was skipped (e.g., M1 when no stationary trials)
if isfield(model, 'skipped') && model.skipped
    fprintf('Model %s was skipped: %s\n', model_name, model.reason);
    msgbox(sprintf('Model %s was skipped.\nReason: %s', model_name, strrep(model.reason, '_', ' ')), ...
           'Model Skipped', 'warn');
    return;
end

% Get labels and design matrix
pred_labels = model.predictor_labels;
X = model.X;  % Design matrix [T × p]

% Number of predictors (excluding intercept)
n_predictors = length(pred_labels) - 1;

%% Create figure with fixed layout
figure('Name', sprintf('GLM Results: %s', model_name), ...
       'Position', [50 50 1400 700]);

%% Left panel: Multiple eta² maps (arranged vertically)
% Calculate how many maps fit per row (max 2 columns)
if n_predictors <= 2
    map_cols = 1;
else
    map_cols = 2;
end
map_rows = ceil(n_predictors / map_cols);

% Left panel takes 50% of width
left_width = 0.45;
map_width = left_width / map_cols;
map_height = 0.85 / map_rows;

% Create axes for each predictor's eta²
eta2_axes = gobjects(n_predictors, 1);  % Store all axes handles
for i = 1:n_predictors
    row = ceil(i / map_cols);
    col = mod(i-1, map_cols) + 1;
    
    % Calculate position [left bottom width height]
    left_pos = 0.05 + (col-1) * map_width;
    bottom_pos = 0.95 - row * map_height;
    
    ax_eta2 = axes('Position', [left_pos, bottom_pos, map_width*0.85, map_height*0.8]);
    eta2_axes(i) = ax_eta2;  % Store this axis handle
    
    % Extract eta² map for this predictor
    eta2_map = squeeze(model.eta2(i,:,:));
    
    % Display map
    hImg = imagesc(eta2_map);
    axis square
    colormap(ax_eta2, hot)
    colorbar
    title(sprintf('eta²: %s', pred_labels{i}), 'Interpreter', 'none')
    xlabel('X'); ylabel('Y');
    set(gca, 'FontSize', 9);
    
    % Make ALL maps clickable
    set(hImg,'ButtonDownFcn',@clickCallback)
end

%% Right panel: Fixed position for timeseries plots (always same size)
% Right panel starts at 55% of width, takes 40%
ax2 = axes('Position', [0.56, 0.55, 0.40, 0.38]);
title('Click any eta² map to see voxel timeseries')
xlabel('Time (s)'); ylabel('Signal');
set(gca, 'FontSize', 10);

ax3 = axes('Position', [0.56, 0.08, 0.40, 0.38]);
title('Predictors')
xlabel('Time (s)'); ylabel('Normalized value');
set(gca, 'FontSize', 10);

%% Store data in figure
viewer_data = struct();
viewer_data.PDI = data.PDI;
viewer_data.bmask = data.bmask;
viewer_data.time = data.time;
viewer_data.X = X;
viewer_data.betas = model.betas;  % [p × ny × nz]
viewer_data.pred_labels = pred_labels;
viewer_data.eta2_axes = eta2_axes;  % Array of all eta² map axes
viewer_data.ax2 = ax2;
viewer_data.ax3 = ax3;
viewer_data.markers = gobjects(n_predictors, 1);  % One marker per eta² map
guidata(gcf, viewer_data);

end

%% Callback function for click
function clickCallback(~,~)
    
    viewer_data = guidata(gcf);
    
    % Get click location from whichever axis was clicked
    clicked_ax = gca;  % Get current (clicked) axis
    cp = get(clicked_ax,'CurrentPoint');
    x = round(cp(1,1));
    y = round(cp(1,2));
    
    [ny, nz] = size(viewer_data.bmask);
    
    % Bounds check
    if x>=1 && x<=nz && y>=1 && y<=ny
        
        % Check if voxel is in brain
        if ~viewer_data.bmask(y,x)
            return;  % Skip non-brain voxels
        end
        
        %% Extract voxel timeseries
        signal = squeeze(viewer_data.PDI(y, x, :));  % [T×1]
        
        %% Get betas for this voxel
        voxel_betas = squeeze(viewer_data.betas(:, y, x));  % [p×1]
        
        %% Reconstruct model fit
        fitted = viewer_data.X * voxel_betas;  % [T×1]
        
        %% Compute R²
        SS_total = sum((signal - mean(signal)).^2);
        SS_residual = sum((signal - fitted).^2);
        R2 = 1 - (SS_residual / SS_total);
        
        %% Plot 1: Signal vs Fit
        axes(viewer_data.ax2)
        cla;
        hold on;
        plot(viewer_data.time, signal, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Signal');
        plot(viewer_data.time, fitted, 'r--', 'LineWidth', 2, 'DisplayName', 'Model Fit');
        hold off;
        title(sprintf('Voxel (%d,%d) - R² = %.3f', y, x, R2))
        xlabel('Time (s)'); ylabel('Signal');
        legend('Location', 'best');
        grid on;
        
        %% Plot 2: All Predictors
        axes(viewer_data.ax3)
        cla;
        hold on;
        
        % Plot each predictor with different color
        colors = lines(size(viewer_data.X, 2));
        for i = 1:(size(viewer_data.X, 2)-1)  % Skip intercept
            % Normalize predictor for display (0 to 1)
            pred = viewer_data.X(:, i);
            pred_norm = (pred - min(pred)) / (max(pred) - min(pred) + eps);
            plot(viewer_data.time, pred_norm, 'Color', colors(i,:), ...
                 'LineWidth', 1.5, 'DisplayName', viewer_data.pred_labels{i});
        end
        
        hold off;
        title('Predictors (normalized for display)')
        xlabel('Time (s)'); ylabel('Normalized value');
        legend('Location', 'best');
        grid on;
        ylim([-0.1 1.1]);
        
        %% Highlight selected voxel on ALL eta² maps
        for i = 1:length(viewer_data.eta2_axes)
            axes(viewer_data.eta2_axes(i))
            hold on
            % Delete old marker if it exists
            if isgraphics(viewer_data.markers(i))
                delete(viewer_data.markers(i))
            end
            % Plot new marker at same location on each map
            viewer_data.markers(i) = plot(x, y, 'c.', 'MarkerSize', 30);
            hold off
        end
        
        % Store updated data
        guidata(gcf, viewer_data);
    end
end
