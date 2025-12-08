function events = extract_shock_events(datapath, ttlData, shockChannels)
    % EXTRACT_SHOCK_EVENTS Extract shock stimulation events
    %
    %   events = extract_shock_events(datapath, ttlData, shockChannels)
    
    % Read shock metadata
    stimInfo = readtable(fullfile(datapath, 'ShockStimulation.csv'));
    
    % Build condition to check for each channel
    startIndices = [];
    endIndices = [];
    
    for i = 1:length(shockChannels)
        ch = shockChannels(i);
        startIdx = detect_ttl_edges(ttlData, ch, 'falling');
        endIdx = detect_ttl_edges(ttlData, ch, 'rising');
        
        if ~isempty(startIdx)
            startIndices = [startIndices; startIdx];
            endIndices = [endIndices; endIdx];
        end
    end
    
    % Convert indices to times
    if ~isempty(startIndices)
        startTimes = ttlData(startIndices, 1);
        endTimes = ttlData(endIndices, 1);
    else
        startTimes = [];
        endTimes = [];
    end
    
    % Remove very short events
    if ~isempty(startTimes)
        duration = endTimes - startTimes;
        valid = (duration >= 0.1) & (startTimes >= 0.1);
        startTimes = startTimes(valid);
        endTimes = endTimes(valid);
    end
    
    % Determine shock type
    if strcmp(stimInfo.type{2}, 'tail')
        % Load intensity information
        if exist(fullfile(datapath, 'shockIntensities_and_perceivedSqueaks.xlsx'), 'file')
            shockInfo = readtable(fullfile(datapath, 'shockIntensities_and_perceivedSqueaks.xlsx'));
            
            events = table(...
                repmat({'shock_tail'}, length(startTimes), 1), ...
                startTimes, ...
                endTimes, ...
                'VariableNames', {'stimCond', 'startTime', 'endTime'});
            
            % Merge with intensity info if available
            if height(shockInfo) == height(events)
                for col = 1:width(shockInfo)
                    events.(shockInfo.Properties.VariableNames{col}) = shockInfo.(shockInfo.Properties.VariableNames{col});
                end
            end
        else
            events = table(...
                repmat({'shock_tail'}, length(startTimes), 1), ...
                startTimes, ...
                endTimes, ...
                'VariableNames', {'stimCond', 'startTime', 'endTime'});
        end
    else
        % Left/right shock paradigm
        stimConds = stimInfo.type(2:end);
        stimConds = strrep(stimConds, 'left', 'shockOBS');
        stimConds = strrep(stimConds, 'right', 'shockCTL');
        
        events = table(...
            stimConds, ...
            startTimes, ...
            endTimes, ...
            'VariableNames', {'stimCond', 'startTime', 'endTime'});
    end
end
