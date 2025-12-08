function events = extract_auditory_events(datapath, ttlData, nidaqLog, auditoryChannel)
    % EXTRACT_AUDITORY_EVENTS Extract auditory stimulation events
    %
    %   events = extract_auditory_events(datapath, ttlData, nidaqLog, auditoryChannel)
    
    % Try TTL-based extraction
    startIndices = detect_ttl_edges(ttlData, auditoryChannel, 'rising');
    endIndices = detect_ttl_edges(ttlData, auditoryChannel, 'falling');
    
    % Convert indices to times
    if ~isempty(startIndices)
        startTimes = ttlData(startIndices, 1);
        endTimes = ttlData(endIndices, 1);
    else
        startTimes = [];
        endTimes = [];
    end
    
    % Fallback to CSV if TTL empty
    if isempty(startTimes)
        csvPath = fullfile(datapath, 'auditoryStimulation.csv');
        if exist(csvPath, 'file')
            stimData = readtable(csvPath);
            stimData.time = stimData.time - nidaqLog.time(1);
            
            startTimes = stimData.time(strcmp('audio_start', stimData.stim));
            endTimes = stimData.time(strcmp('audio_stop', stimData.stim));
        end
    end
    
    % Build events table
    if ~isempty(startTimes)
        events = table(...
            repmat({'CS'}, length(startTimes), 1), ...
            startTimes, ...
            endTimes, ...
            'VariableNames', {'stimCond', 'startTime', 'endTime'});
    else
        events = table();
    end
end
