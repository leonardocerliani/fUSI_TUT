function img = data2image(data, cmap, clim)
    % img = data2image(data, cmap, clim)
    % convert a data matrix to an image.
    %
    % R Waasdorp - r.waasdorp@tudelft.nl - 14-03-2024

    if exist('clim', 'var') && ~isempty(clim)
        cmin = clim(1);
        cmax = clim(2);
    else
        cmin = min(data(:));
        cmax = max(data(:));
    end

    if size(data, 3) == 1
        % create indexed image and convert to rgb
        m = length(cmap);
        index = fix((data - cmin) / (cmax - cmin) * m) + 1;
        img = uint8(ind2rgb(index, cmap) * 255);
    else % stack of images
        fprintf('Converting stack of data with 3rd dim Time to images\n')
        [nz, nx, nt] = size(data);
        img = zeros(nz, nx, 3, nt, 'uint8');
        for k = 1:nt
            img(:, :, :, k) = data2image(data(:, :, k), cmap, clim);
        end
    end

end
