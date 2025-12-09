function [pdiData, scanParams, ttlData, nidaqLog] = load_core_data(datapath, config)
    % LOAD_CORE_DATA Load all core data files
    %
    %   [pdiData, scanParams, ttlData, nidaqLog] = load_core_data(datapath, config)
    
    % Locate FUSI data directory
    D = dir(fullfile(datapath, 'FUSI_data*'));
    if isempty(D)
        error('No FUSI_data* directory found in: %s', datapath);
    end
    fusDatapath = fullfile(D(1).folder, D(1).name);
    
    % Load scan parameters
    scanParamFiles = {'post_L22-14_PlaneWave_FUSI_data.mat', ...
                      'L22-14_PlaneWave_FUSI_data.mat'};
    BFConfig = [];
    
    for i = 1:length(scanParamFiles)
        scanParamPath = fullfile(fusDatapath, scanParamFiles{i});
        if exist(scanParamPath, 'file')
            S = load(scanParamPath, 'BFConfig');
            BFConfig = S.BFConfig;
            fprintf('  ✓ Scan parameters loaded: %s\n', scanParamFiles{i});
            break;
        end
    end
    
    if isempty(BFConfig)
        error('No scan parameter file found in: %s', fusDatapath);
    end
    scanParams = BFConfig;
    
    % Load PDI binary
    pdiFile = fullfile(fusDatapath, 'fUS_block_PDI_float.bin');
    if ~exist(pdiFile, 'file')
        error('PDI binary not found: %s', pdiFile);
    end
    
    fid = fopen(pdiFile, 'r');
    rawPDI = fread(fid, inf, 'single');
    fclose(fid);
    
    % Calculate dimensions
    nt = numel(rawPDI) / (BFConfig.Nx * BFConfig.Nz);
    pdiData = reshape(rawPDI, [BFConfig.Nz, BFConfig.Nx, nt]);
    clear rawPDI;
    
    fprintf('  ✓ PDI binary loaded: fUS_block_PDI_float.bin (%d × %d × %d frames)\n', ...
        BFConfig.Nx, BFConfig.Nz, nt);
    
    % Load TTL data
    ttlFiles = dir(fullfile(datapath, 'TTL*.csv'));
    if isempty(ttlFiles)
        error('No TTL file found in: %s', datapath);
    end
    
    ttlData = readmatrix(fullfile(ttlFiles(1).folder, ttlFiles(1).name));
    fprintf('  ✓ TTL data loaded: %s (%d channels, %d samples)\n', ...
        ttlFiles(1).name, size(ttlData, 2), size(ttlData, 1));
    
    % Load NIDAQ log
    nidaqFiles = {'NIDAQ.csv', 'DAQ.csv'};
    nidaqLog = [];
    
    for i = 1:length(nidaqFiles)
        nidaqPath = fullfile(datapath, nidaqFiles{i});
        if exist(nidaqPath, 'file')
            nidaqLog = readtable(nidaqPath);
            fprintf('  ✓ DAQ log loaded: %s\n', nidaqFiles{i});
            break;
        end
    end
    
    if isempty(nidaqLog)
        error('No NIDAQ/DAQ file found in: %s', datapath);
    end
end
