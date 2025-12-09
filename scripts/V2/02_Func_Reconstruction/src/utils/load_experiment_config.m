function config = load_experiment_config(datapath)
    % LOAD_EXPERIMENT_CONFIG Load experiment config from data directory
    %
    %   config = load_experiment_config(datapath)
    %
    %   Looks for experiment_config.json in the data directory.
    %   If not found, provides helpful error with template example.
    
    configFile = fullfile(datapath, 'experiment_config.json');
    
    if ~exist(configFile, 'file')
        % Print helpful error message with template
        fprintf(2, '\n');
        fprintf(2, '========================================\n');
        fprintf(2, 'ERROR: Configuration file not found!\n');
        fprintf(2, '========================================\n\n');
        fprintf(2, 'Expected location:\n  %s\n\n', configFile);
        fprintf(2, 'Please create experiment_config.json with the following format:\n\n');
        fprintf(2, '{\n');
        fprintf(2, '  "experiment_id": "run-115047-func",\n');
        fprintf(2, '  "date": "2023-12-15",\n');
        fprintf(2, '  "description": "Visual stimulation experiment",\n');
        fprintf(2, '  \n');
        fprintf(2, '  "ttl_channels": {\n');
        fprintf(2, '    "pdi_frame": 3,\n');
        fprintf(2, '    "experiment_start": 6,\n');
        fprintf(2, '    "experiment_start_fallback": 5,\n');
        fprintf(2, '    "shock": [4, 5, 12],\n');
        fprintf(2, '    "visual": 10,\n');
        fprintf(2, '    "auditory": 11\n');
        fprintf(2, '  }\n');
        fprintf(2, '}\n\n');
        fprintf(2, 'Notes:\n');
        fprintf(2, '  • Update channel numbers to match your setup\n');
        fprintf(2, '  • Remove lines for unused stimulation types\n');
        fprintf(2, '  • Save as experiment_config.json in the data folder\n\n');
        fprintf(2, '========================================\n\n');
        
        error('Configuration file missing. Please create experiment_config.json in data directory.');
    end
    
    % Load configuration
    config = parse_config(configFile);
end
