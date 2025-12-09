function config = parse_config(configFile)
    % PARSE_CONFIG Load and parse JSON configuration file
    %
    %   config = parse_config(configFile)
    %
    %   Inputs:
    %       configFile - Path to JSON configuration file
    %
    %   Outputs:
    %       config - MATLAB structure with configuration parameters
    
    if ~exist(configFile, 'file')
        error('Configuration file not found: %s', configFile);
    end
    
    try
        % Read JSON file
        jsonText = fileread(configFile);
        
        % Parse into MATLAB structure
        config = jsondecode(jsonText);
        
    catch ME
        error('Failed to parse JSON file %s: %s', configFile, ME.message);
    end
end
