function savepath = generate_save_path(datapath)
    % GENERATE_SAVE_PATH Auto-generate analysis path from data path
    %
    %   savepath = generate_save_path(datapath)
    %
    %   Converts: /any/path/to/Data_collection/run-XXXXX
    %   To:       /any/path/to/Data_analysis/run-XXXXX
    %
    %   This works regardless of where Data_collection is located
    
    % Find 'Data_collection' in the path
    tmpInd1 = strfind(datapath, 'Data_collection');
    
    if isempty(tmpInd1)
        error('The datapath does not contain ''Data_collection''.');
    end
    
    % Calculate position after 'Data_collection'
    tmpInd2 = tmpInd1 + length('Data_collection');
    
    % Build analysis path by replacing collection with analysis
    savepath = fullfile(...
        datapath(1:tmpInd1-1), ...      % Everything before Data_collection
        'Data_analysis', ...             % Replace with Data_analysis
        datapath(tmpInd2:end));          % Everything after Data_collection
end
