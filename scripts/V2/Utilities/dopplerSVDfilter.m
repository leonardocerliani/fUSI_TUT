function [Dop, CovU, S, svalsToKeep, IQF_corrected] = dopplerSVDfilter(IQ, svalsToKeep)
    % [Dop, CovU, S, svalsToKeep] = dopplerSVDfilter(IQ, svalsToKeep)
    %   Perform singular value filtering for Doppler imaging.
    %
    %   Provide IQ as 3D array (z,x,t) and provide the singular
    %   values to keep, e.g. 1:10 for the most spatiotemporay correlated,
    %   or 50:200 for blood signal.
    %
    %   Optionally also outputs the covariance matrix of the singular vectors,
    %   and the singular values.
    %
    %   R. Waasdorp (r.waasdorp@tudelft.nl), 25-01-2022
    %

    % get size of IQ
    [nz, nx, nt] = size(IQ);

    if ~exist('svalsToKeep', 'var') || isempty(svalsToKeep)
        svalsToKeep = round([0.2 0.9] .* nt);
        svalsToKeep = max(1, svalsToKeep(1)):svalsToKeep(2);
        fprintf('WARNING: No SVD Threshold given, using: %i - %i\n', svalsToKeep(1), svalsToKeep(end))
    end

    % determine EVs to skip
    skipEVS = 1:nt;
    if max(svalsToKeep) > nt
        svalsToKeep = svalsToKeep(1:find(svalsToKeep == nt));
    end
    skipEVS(svalsToKeep) = [];

    S_casorati = reshape(IQ, nx * nz, nt);
    [V, S] = eig(S_casorati' * S_casorati);
    V = fliplr(V);
    lU = S_casorati * V; % project SV to get lambda*U
    IQF_tissue = lU(:, skipEVS) * V(:, skipEVS)';
    IQF_corrected = IQ - reshape(IQF_tissue, [nz, nx, nt]);
    Dop = mean(abs(IQF_corrected).^2, 3);

    if nargout > 1
        S = sqrt(fliplr(diag(S)'));
        lU_norm = lU ./ S;
        CovU = abs(lU_norm)' * abs(lU_norm);
    end
end
