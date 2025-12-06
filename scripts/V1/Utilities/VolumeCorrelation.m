function corr_value = VolumeCorrelation(A, B)
    % Flatten the volumes
    A_vec = A(:);
    B_vec = B(:);

    % Find valid indices
    valid_idx = ~isnan(A_vec) & ~isnan(B_vec) & (A_vec~=0) & (B_vec~=0);

    % Extract valid data
    A_valid = A_vec(valid_idx);
    B_valid = B_vec(valid_idx);

    % Compute correlation coefficient
    R = corrcoef(A_valid, B_valid);
    corr_value = R(1, 2);
end
