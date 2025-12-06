function line_handles = drawBordersCustom(ax, atlas, orientation, plane, lineopts)

    if ~exist('lineopts', 'var'); lineopts = {'k:'}; end
    %flip_xy = false;
    if strcmp(orientation, 'coronal')
        L = atlas.LinesScaled.Cor{plane};
    elseif strcmp(orientation, 'sagittal')
        L = atlas.LinesScaled.Sag{plane};
    elseif strcmp(orientation, 'transversal')
        L = atlas.LinesScaled.Tra{plane};
        %flip_xy = true;
    else
        error('cut must be: coronal sagittal or transversal')
    end

    
    nb = length(L);
    line_handles = gobjects(nb, 1);
    for ib = 1:nb
        x = L{ib};
        %if flip_xy; flip(x, 2); end
        line_handles(ib) = plot(ax, x(:, 2), x(:, 1), lineopts{:}); % change the color of the line
    end
    

end
