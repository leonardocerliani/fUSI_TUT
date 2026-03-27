function pos = getPosLocationcode(locCode, dw, dh)
    % GETPOSLOCATIONCODE get the position in the VSX gui for a certain VSX
    % location code, e.g. 'UserA1'. Possible to change region size with input
    % arguments 'dw', 'dh' (positive for smaller, negative for larger) in
    % normalized units.
    %
    % R. Waasdorp, 05-03-2021
    %

    if ~exist('dw', 'var') || isempty(dw)
        dw = 0;
    end

    if ~exist('dh', 'var') || isempty(dh)
        dh = dw;
    end
    % location strings and positions from verasonics
    locstr_all = {...
            'UserA1', [0.0875 0.14 0.2 0.07];
            'UserA2', [0.0875 0.24 0.2 0.07];
            'UserB1', [0.4 0.14 0.2 0.07];
            'UserB2', [0.4 0.24 0.2 0.07];
            'UserB3', [0.4 0.34 0.2 0.07];
            'UserB4', [0.4 0.44 0.2 0.07];
            'UserB5', [0.4 0.54 0.2 0.07];
            'UserB6', [0.4 0.64 0.2 0.07];
            'UserB7', [0.4 0.74 0.2 0.07];
            'UserB8', [0.4 0.84 0.2 0.07];
            'UserC1', [0.7125 0.14 0.2 0.07];
            'UserC2', [0.7125 0.24 0.2 0.07];
            'UserC3', [0.7125 0.34 0.2 0.07];
            'UserC4', [0.7125 0.44 0.2 0.07];
            'UserC5', [0.7125 0.54 0.2 0.07];
            'UserC6', [0.7125 0.64 0.2 0.07];
            'UserC7', [0.7125 0.74 0.2 0.07];
            'UserC8', [0.7125 0.84 0.2 0.07];
            };

    % index
    idx = find(strcmp(locstr_all(:, 1), locCode), 1);
    pos = locstr_all{idx, 2};

    pos(1) = pos(1) - dw / 2;
    pos(2) = pos(2) - dh / 2;
    pos(3) = pos(3) + dw / 2;
    pos(4) = pos(4) + dh / 2;
end
