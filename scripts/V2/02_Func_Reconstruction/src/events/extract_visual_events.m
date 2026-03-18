function events = extract_visual_events(datapath, ttlData, nidaqLog, visualChannel)
    % EXTRACT_VISUAL_EVENTS Extract visual stimulation events
    %
    %   events = extract_visual_events(datapath, ttlData, nidaqLog, visualChannel)
    
    % Try TTL-based extraction
    startIndices = detect_ttl_edges(ttlData, visualChannel, 'rising');
    endIndices = detect_ttl_edges(ttlData, visualChannel, 'falling');
    
    % Convert indices to times and filter very short events
    if ~isempty(startIndices) && ~isempty(endIndices)
        startTimes = ttlData(startIndices, 1);
        endTimes = ttlData(endIndices, 1);
        
        duration = endTimes - startTimes;
        valid = duration >= 0.01;
        startTimes = startTimes(valid);
        endTimes = endTimes(valid);
    else
        startTimes = [];
        endTimes = [];
    end
    
    % Fallback to CSV if TTL empty
    if isempty(startTimes)
        csvPath = fullfile(datapath, 'VisualStimulation.csv');
        if exist(csvPath, 'file')
            stimData = readtable(csvPath);
            stimData.time = stimData.time - nidaqLog.time(1);
            
            startTimes = stimData.time(strcmp('stim', stimData.event));
            endTimes = stimData.time(strcmp('blank', stimData.event));
        end
    end
    
    % Build events table
    if ~isempty(startTimes)
        events = table(...
            repmat({'visual'}, length(startTimes), 1), ...
            startTimes, ...
            endTimes, ...
            'VariableNames', {'stimCond', 'startTime', 'endTime'});
    else
        events = table();
    end
end
