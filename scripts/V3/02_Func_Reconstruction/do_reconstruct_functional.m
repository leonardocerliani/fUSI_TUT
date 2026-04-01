function PDI = do_reconstruct_functional(func_collection_path, func_analysis_path)
    % DO_RECONSTRUCT_FUNCTIONAL Convert raw fUSI data to structured MAT format
    %
    %   PDI = do_reconstruct_functional(func_collection_path, func_analysis_path)
    %
    %   Automatically detects available data files and processes based on
    %   experiment_config.json in the data directory.
    %
    %   Inputs:
    %       func_collection_path - (Optional) Path to Data_collection/ses-XX/run-XXXXX-func/
    %       func_analysis_path   - (Optional) Path to Data_analysis/ses-XX/run-XXXXX-func/
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
    if nargin < 1 || isempty(func_collection_path)
        func_collection_path = uigetdir('', 'Select functional scan directory (Data_collection)');
        if func_collection_path == 0
            error('Data path selection canceled.');
        end
    end
    
    if nargin < 2 || isempty(func_analysis_path)
        func_analysis_path = generate_save_path(func_collection_path);
    end
    
    %% Step 2: Load and display config
    fprintf('→ Loading configuration: experiment_config.json\n');
    config = load_experiment_config(func_collection_path);
    print_ttl_config(config);
    


    %% Step 3: Load core data with status
    fprintf('\n→ Loading core data files:\n');
    [pdiData, scanParams, ttlData, nidaqLog] = load_core_data(func_collection_path, config);
    
    % fun_plot.plotTTL(ttlData)


    %% Step 4: Timeline synchronization
    fprintf('\n→ Timeline synchronization:\n');
    [pdiData, pdiTime, scanParams, ttlData] = synchronize_timeline(pdiData, scanParams, ttlData, config, func_collection_path);
    

    
    %% Step 5: Detect and load stimulation and behavioral data
    fprintf('\n→ Detected stimulation files:\n');
    stimInfo = detect_and_load_stimulation(func_collection_path, ttlData, nidaqLog, config);
    
    fprintf('\n→ Detected behavioral data:\n');
    behavioral = detect_and_load_behavioral(func_collection_path, nidaqLog);
    


    %% Step 6: Assemble and save
    fprintf('\n→ Assembling PDI structure...\n');
    PDI = build_pdi_structure(pdiData, pdiTime, scanParams, stimInfo, behavioral, func_analysis_path);
    save_pdi_data(PDI, func_analysis_path);
    


    %% Step 7: Final summary
    print_final_summary(PDI, stimInfo, behavioral);
end
