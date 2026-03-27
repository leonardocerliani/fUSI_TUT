function PDI = do_reconstruct_functional(datapath, savepath)
    % DO_RECONSTRUCT_FUNCTIONAL Convert raw fUSI data to structured MAT format
    %
    %   PDI = do_reconstruct_functional(datapath, savepath)
    %
    %   Automatically detects available data files and processes based on
    %   experiment_config.json in the data directory.
    %
    %   Inputs:
    %       datapath - (Optional) Path to Data_collection/run-XXXXX-func/
    %       savepath - (Optional) Path for Data_analysis/run-XXXXX-func/
    %
    %   Outputs:
    %       PDI - Structure containing processed PDI data and metadata
    %
    %   Example:
    %       PDI = do_reconstruct_functional();  % Select folder via dialog
    
    % Add source paths
    funcReconPath = fileparts(mfilename('fullpath'));
    addpath(genpath(fullfile(funcReconPath, 'src')));
    
    %% Header
    fprintf('\n');
    fprintf('========================================\n');
    fprintf('fUSI Data Processing Pipeline\n');
    fprintf('========================================\n\n');
    
    %% Step 1: Get data path
    if nargin < 1 || isempty(datapath)
        datapath = uigetdir('', 'Select functional scan directory');
        if datapath == 0
            error('Data path selection canceled.');
        end
    end
    
    if nargin < 2 || isempty(savepath)
        savepath = generate_save_path(datapath);
    end
    
    %% Step 2: Load and display config
    fprintf('→ Loading configuration: experiment_config.json\n');
    config = load_experiment_config(datapath);
    print_ttl_config(config);
    


    %% Step 3: Load core data with status
    fprintf('\n→ Loading core data files:\n');
    [pdiData, scanParams, ttlData, nidaqLog] = load_core_data(datapath, config);
    
    % fun_plot.plotTTL(ttlData)


    %% Step 4: Timeline synchronization
    fprintf('\n→ Timeline synchronization:\n');
    [pdiData, pdiTime, scanParams, ttlData] = synchronize_timeline(pdiData, scanParams, ttlData, config, datapath);
    

    
    %% Step 5: Detect and load stimulation and behavioral data
    fprintf('\n→ Detected stimulation files:\n');
    stimInfo = detect_and_load_stimulation(datapath, ttlData, nidaqLog, config);
    
    fprintf('\n→ Detected behavioral data:\n');
    behavioral = detect_and_load_behavioral(datapath, nidaqLog);
    


    %% Step 6: Assemble and save
    fprintf('\n→ Assembling PDI structure...\n');
    PDI = build_pdi_structure(pdiData, pdiTime, scanParams, stimInfo, behavioral, savepath);
    save_pdi_data(PDI, savepath);
    


    %% Step 7: Final summary
    print_final_summary(PDI, stimInfo, behavioral);
end
