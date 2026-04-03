function config = load_experiment_config(datapath)
    % LOAD_EXPERIMENT_CONFIG Load experiment config from data directory
    %
    %   config = load_experiment_config(datapath)
    %
    %   Looks for experiment_config.json in the data directory.
    %   If not found, loads default values from experiment_config_default_values.json
    %   located in the same folder as this function (src/utils/).
    
    configFile = fullfile(datapath, 'experiment_config.json');
    
    if ~exist(configFile, 'file')
        % Locate default values file next to this function
        defaultConfigFile = fullfile(fileparts(mfilename('fullpath')), 'experiment_config_default_values.json');
        
        fprintf(2, '\n');
        fprintf(2, '========================================\n');
        fprintf(2, 'WARNING: experiment_config.json not found!\n');
        fprintf(2, '========================================\n');
        fprintf(2, 'Expected location:\n  %s\n\n', configFile);
        fprintf(2, 'Loading default TTL channel values:\n');
        fprintf(2, '  pdi_frame:                  3\n');
        fprintf(2, '  experiment_start:           6\n');
        fprintf(2, '  experiment_start_fallback:  5\n');
        fprintf(2, '  visual:                    10\n\n');
        fprintf(2, 'To override, copy experiment_config_template.json from the\n');
        fprintf(2, 'script root into your Data_collection run folder,\n');
        fprintf(2, 'rename it experiment_config.json, and edit as needed.\n');
        fprintf(2, '========================================\n\n');
        
        config = parse_config(defaultConfigFile);
        return;
    end
    
    % Load configuration
    config = parse_config(configFile);
end
