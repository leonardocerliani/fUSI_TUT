function blended_image = blend_images(bg_image, fg_image, alpha_mask)
    % Ensure the images are in double precision for accurate calculations
    bg_image = im2double(bg_image);
    fg_image = im2double(fg_image);
    alpha_mask = im2double(alpha_mask);

    % Check if alpha_mask is a single channel and replicate it if necessary
    if size(alpha_mask, 3) == 1
        alpha_mask = repmat(alpha_mask, [1 1 3]);
    end

    % Blend the images
    blended_image = alpha_mask .* fg_image + (1 - alpha_mask) .* bg_image;

    % Convert the result back to uint8
    blended_image = im2uint8(blended_image);
end
