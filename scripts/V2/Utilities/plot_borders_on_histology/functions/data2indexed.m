function indexed = data2indexed(data, clim)


    % if ~exist('clim','var'); clim = [min(data(:)) max(data(:))]; end

    m = intmax('uint8');
    m = cast(m, 'like', data);
    cmin = clim(1);
    cmax = clim(2);
	
    indexed = fix((data - cmin) / (cmax - cmin) * m) + 1;
    indexed = uint8(indexed);

end