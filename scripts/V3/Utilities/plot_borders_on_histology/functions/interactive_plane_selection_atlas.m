function fig = interactive_plane_selection_atlas(atlas, mapRegistered, ...
        planeChoice, save_settings)

    if ~exist('planeChoice', 'var')
        planeChoice.sag = 10;
        planeChoice.tra = 5;
        planeChoice.cor = 4;
    end

    if ~exist('save_settings', 'var')
        save_settings = struct('save_immediate', false, ...
            'folder', '.', ...
            'filename', 'temp', ...
            'cor', 0, ...
            'sag', 0, ...
            'tra', 0);
    end

    % Extract axes based on atlas size and voxel size
    clim_vascular = minmax(atlas.Vascular(:));
    clim_vascular(1) = 0;
    background = data2indexed(atlas.Vascular, clim_vascular);
    background(isnan(atlas.Vascular)) = intmax('uint8');
    mapRegistered(isnan(atlas.Vascular)) = 0;

    cor_map = mapRegistered;
    cor_threshold = 0.3;
    cor_clim = [0, 0.8];
    border_line_opts = {'color', 'w', 'linewidth', 0.5, 'HitTest', 'off', 'PickableParts', 'none'};
    const_line_opts = {'LineWidth', 1.5, 'HitTest', 'off', 'PickableParts', 'none'};

    % make axes
    [nz, nx, ny] = size(mapRegistered);
    voxel_size = atlas.VoxelSize / 1e3;
    ax_DV = (1:nz) * voxel_size(1);
    ax_AP = (1:nx) * voxel_size(2);
    ax_LR = (1:ny) * voxel_size(3);

    % Initialize slice indices
    PlaneSag = find_nearest(ax_LR, planeChoice.sag);
    PlaneTra = find_nearest(ax_DV, planeChoice.tra);
    PlaneCor = find_nearest(ax_AP, planeChoice.cor);
    planeChoice.sag = ax_LR(PlaneSag);
    planeChoice.tra = ax_DV(PlaneTra);
    planeChoice.cor = ax_AP(PlaneCor);

    % update lines in atlas, scale with voxel size
    atlas = scale_lines_atlas(atlas, voxel_size);

    fh = struct(); img = struct();

    % Set up figure with subplots
    fig = figure('Name', 'Interactive Plane Selection', 'NumberTitle', 'off');
    fig.Position = [250 75 1000 850];
    fig.KeyPressFcn = @key_press_fcn;
    ax1 = subplot(2, 2, 1); % sag
    ax2 = subplot(2, 2, 3); % tra
    ax3 = subplot(2, 2, 2); % cor

    % removeToolbarExplorationButtons(fig);
    %     ax1.Toolbar.Visible = 'off';
    %     ax2.Toolbar.Visible = 'off';
    %     ax3.Toolbar.Visible = 'off';
    % axtoolbar(ax1,{});

    compose_images();

    % Initial plot with image handles
    fh.sag.img = image(ax1, ax_AP, ax_DV, img.sag);
    fh.sag.img.ButtonDownFcn = @(src, event) click_callback('sagittal');
    hold(ax1, 'on'); daspect(ax1, [1 1 1]);
    fh.sag.tit = title(ax1, sprintf('Sagittal %.3fmm', planeChoice.sag));
    fh.sag.xl = xline(ax1, ax_AP(PlaneCor), 'g', const_line_opts{:});
    fh.sag.yl = yline(ax1, ax_DV(PlaneTra), 'b', const_line_opts{:});
    fh.sag.lines = drawBordersCustom(ax1, atlas, 'sagittal', PlaneSag, border_line_opts);
    xlabel(ax1, 'AP'); ylabel(ax1, 'DV');

    fh.tra.img = image(ax2, ax_LR, ax_AP, img.tra);
    fh.tra.img.ButtonDownFcn = @(src, event) click_callback('transversal');
    hold(ax2, 'on'); daspect(ax2, [1 1 1]);
    fh.tra.tit = title(ax2, sprintf('Transversal %.3fmm', planeChoice.tra));
    fh.tra.xl = xline(ax2, ax_LR(PlaneSag), 'r', const_line_opts{:});
    fh.tra.yl = yline(ax2, ax_AP(PlaneCor), 'g', const_line_opts{:});
    fh.tra.lines = drawBordersCustom(ax2, atlas, 'transversal', PlaneTra, border_line_opts);
    xlabel(ax2, 'LR'); ylabel(ax2, 'AP');

    fh.cor.img = image(ax3, ax_LR, ax_DV, img.cor);
    fh.cor.img.ButtonDownFcn = @(src, event) click_callback('coronal');
    hold(ax3, 'on'); daspect(ax3, [1 1 1]);
    fh.cor.tit = title(ax3, sprintf('Coronal %.3fmm', planeChoice.cor));
    fh.cor.xl = xline(ax3, ax_LR(PlaneSag), 'r', const_line_opts{:});
    fh.cor.yl = yline(ax3, ax_DV(PlaneTra), 'b', const_line_opts{:});
    fh.cor.lines = drawBordersCustom(ax3, atlas, 'coronal', PlaneCor, border_line_opts);
    xlabel(ax3, 'LR'); ylabel(ax3, 'DV');

    % set userdata on axes
    ax1.UserData = 'sagittal';
    ax2.UserData = 'transversal';
    ax3.UserData = 'coronal';

    if save_settings.save_immediate; save_to_file(fig, save_settings); end

    function click_callback(plane)
        click_coords = get(gca, 'CurrentPoint');
        x_click = click_coords(1, 1);
        y_click = click_coords(1, 2);

        switch plane
            case 'sagittal'
                PlaneCor = find_nearest(ax_AP, x_click);
                PlaneTra = find_nearest(ax_DV, y_click);
                planeChoice.cor = ax_AP(PlaneCor);
                planeChoice.tra = ax_DV(PlaneTra);
            case 'transversal'
                PlaneSag = find_nearest(ax_LR, x_click);
                PlaneCor = find_nearest(ax_AP, y_click);
                planeChoice.cor = ax_AP(PlaneCor);
                planeChoice.sag = ax_LR(PlaneSag);
            case 'coronal'
                PlaneSag = find_nearest(ax_LR, x_click);
                PlaneTra = find_nearest(ax_DV, y_click);
                planeChoice.sag = ax_LR(PlaneSag);
                planeChoice.tra = ax_DV(PlaneTra);
        end
        update_images();
    end

    function compose_images()
        sq = @squeeze;
        img.sag = image_blender(sq(background(:, :, PlaneSag)), sq(cor_map(:, :, PlaneSag)), cor_threshold, cor_clim);
        img.tra = image_blender(sq(background(PlaneTra, :, :)), sq(cor_map(PlaneTra, :, :)), cor_threshold, cor_clim);
        img.cor = image_blender(sq(background(:, PlaneCor, :)), sq(cor_map(:, PlaneCor, :)), cor_threshold, cor_clim);

    end

    function update_images()
        compose_images();

        fh.sag.img.CData = img.sag;
        fh.sag.xl.Value = ax_AP(PlaneCor);
        fh.sag.yl.Value = ax_DV(PlaneTra);
        delete(fh.sag.lines);
        fh.sag.lines = drawBordersCustom(ax1, atlas, 'sagittal', PlaneSag, border_line_opts);
        fh.sag.tit.String = sprintf('Sagittal %.3fmm', planeChoice.sag);

        fh.tra.img.CData = img.tra;
        fh.tra.xl.Value = ax_LR(PlaneSag);
        fh.tra.yl.Value = ax_AP(PlaneCor);
        delete(fh.tra.lines);
        fh.tra.lines = drawBordersCustom(ax2, atlas, 'transversal', PlaneTra, border_line_opts);
        fh.tra.tit.String = sprintf('Transversal %.3fmm', planeChoice.tra);

        fh.cor.img.CData = img.cor;
        fh.cor.xl.Value = ax_LR(PlaneSag);
        fh.cor.yl.Value = ax_DV(PlaneTra);
        delete(fh.cor.lines);
        fh.cor.lines = drawBordersCustom(ax3, atlas, 'coronal', PlaneCor, border_line_opts);
        fh.cor.tit.String = sprintf('Coronal %.3fmm', planeChoice.cor);

    end

    function idx = find_nearest(array, value)
        [~, idx] = min(abs(array - value));
    end

    function key_press_fcn(src, event)

        switch event.Key
            case 's'
                disp('Request Save')
                save_to_file(fig, save_settings)
        end
    end
end

function out = image_blender(background, correlation, cor_threshold, cor_clim)

    cor_img = data2image(correlation, hot, cor_clim);

    % method 1
    % alpha_fg = zeros(size(correlation));
    % alpha_fg(correlation > cor_threshold) = 1; % cor_threshold;

    % method 2
    % sig_fun = @(I, k) 1 ./ (1 + exp(-k .* (I - 0.5)));
    % alpha_fg = sig_fun(correlation, 10);

    % method 3
    map_to_range = @(I, LB, UB) max(0, min(1, (I - LB) ./ (UB - LB))) .* (I > LB & I < UB) + (I >= UB);
    alpha_fg = map_to_range(correlation, 0.2, 0.4);

    % blend images
    out = blend_images(background, cor_img, alpha_fg);

end

function atlas = scale_lines_atlas(atlas, voxel_size)
    lines = atlas.Lines;
    v = 'Sag'; dx = voxel_size(1); dy = voxel_size(2);
    lines_scaled.(v) = scale_lines(lines.(v), dx, dy);
    v = 'Cor'; dx = voxel_size(3); dy = voxel_size(1);
    lines_scaled.(v) = scale_lines(lines.(v), dx, dy);
    v = 'Tra'; dx = voxel_size(2); dy = voxel_size(1);
    lines_scaled.(v) = scale_lines(lines.(v), dx, dy);
    atlas.LinesScaled = lines_scaled;
    function lines_cell = scale_lines(lines_cell, dx, dy)
        scale_fun = @(line) line .* [dx, dy];
        for k = 1:numel(lines_cell)
            lines_cell{k} = cellfun(scale_fun, lines_cell{k}, 'uniformOutput', false);
        end
    end

end

function save_to_file(fig, save_settings)
    ax = fig.Children;
    [~, ~] = mkdir(fullfile(save_settings.folder, 'coronal'));
    [~, ~] = mkdir(fullfile(save_settings.folder, 'sagittal'));
    [~, ~] = mkdir(fullfile(save_settings.folder, 'transversal'));
    [~, ~] = mkdir(fullfile(save_settings.folder, 'overview'));

    for k = 1:numel(ax)
        view = ax(k).Title.String;
        plane = ax(k).UserData;

        switch plane
            case 'coronal'
                if ~save_settings.cor; continue; end
            case 'sagittal'
                if ~save_settings.sag; continue; end
            case 'transversal'
                if ~save_settings.tra; continue; end
        end

        fname = fullfile(save_settings.folder, plane, sprintf('%s_%s.pdf', save_settings.filename, view));
        exportgraphics(ax(k), fname);
        fname = strrep(fname, '.pdf', '.png');
        exportgraphics(ax(k), fname, 'resolution', 300);
    end

    if ~save_settings.overview
        disp('Figures saved!')
        return
    end

    fname = fullfile(save_settings.folder, 'overview', sprintf('%s_%s.pdf', save_settings.filename, view));
    exportgraphics(fig, fname);
    fname = strrep(fname, '.pdf', '.png');
    exportgraphics(fig, fname, 'resolution', 300);
    disp('Figures saved!')
end

function fig = figure_legacy(varargin)
    %Open a figure with the old style (pre-R2018b) of plot interactions
    fig = figure(varargin{:});
    try %#ok if verLessThan is missing verLessThan would have returned true
        if ~verLessThan('matlab', '9.5')
            addToolbarExplorationButtons(fig)
            % Use eval to trick the syntax checking in ML6.5 (both the ~ and
            % the @ trip up the syntax checker).
            %
            % Using evalc ensures that you can group functions in a single
            % anonymous function that otherwise have no output (as neither
            % disableDefaultInteractivity() nor set() have output arguments).
            defaultAxesCreateFcn = eval(['@(ax,~){', ...
                                             'evalc(''set(ax.Toolbar,''''Visible'''',''''off'''')''),', ...
                                         'evalc(''disableDefaultInteractivity(ax)'')}']);
            set(fig, 'defaultAxesCreateFcn', ...
                defaultAxesCreateFcn);
        end
    end
end
