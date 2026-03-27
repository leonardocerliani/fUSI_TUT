function select_beamformer(bftype)
    % select_beamformer(bftype)
    % Select either cpu or gpu beamforming.
    %
    % date:    09-03-2023
    % author:  R. Waasdorp (r.waasdorp@tudelft.nl)
    % ==============================================================================

    cpu_path = getOOPBFpath('CPU_BF\matlab');
    gpu_path = getOOPBFpath('GPU_BF\matlab');

    switch bftype
        case {'CPU', 'cpu'}
            onPathRm(gpu_path);
            onPathAdd(cpu_path);
        case {'GPU', 'gpu'}
            onPathRm(cpu_path);
            onPathAdd(gpu_path);
        otherwise
            error('beamformer:unknown', 'Unknown Beamformer type. Must be CPU/GPU/Quantum. No other architectures available.')
    end
end
function onPathRm(Folder)
    if onPath(Folder)
        rmpath(Folder);
    end
end
function onPathAdd(Folder)
    if ~onPath(Folder)
        addpath(Folder);
    end
end
function isonpath = onPath(Folder)
    s = pathsep;
    pathStr = [s, path, s];
    isonpath = contains(pathStr, [s, Folder, s], 'IgnoreCase', ispc);
end
