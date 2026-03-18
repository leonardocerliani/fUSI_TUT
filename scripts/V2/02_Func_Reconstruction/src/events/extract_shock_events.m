function events = extract_shock_events(datapath, ttlData, shockChannels)
    % EXTRACT_SHOCK_EVENTS Extract shock stimulation events
    %
    %   events = extract_shock_events(datapath, ttlData, shockChannels)
    %
    %   NOTE: The shockChannels parameter is currently not used - channels are
    %   hardcoded (4, 5, 12) for consistency with legacy behavior. The parameter
    %   is kept for function signature consistency with other extract functions.
    
    % Notify user about hardcoded channels
    fprintf('  → USING DEFAULT HARDCODED SHOCK CHANNELS: 4, 5, AND 12\n');
    
    % Read shock metadata to determine shock type
    stimInfo = readtable(fullfile(datapath, 'ShockStimulation.csv'));
    
    % Check shock type from first event (row 2)
    if contains(stimInfo.event{2}, 'tail')
        % Tail shock: detect falling/rising edges on channels 5 or 12 (hardcoded)
        startTime = ttlData(diff(ttlData(:,5)) < 0 | diff(ttlData(:,12)) < 0, 1);
        endTime = ttlData(diff(ttlData(:,5)) > 0 | diff(ttlData(:,12)) > 0, 1);
        
        % Remove pre-experiment events (< 0.1s)
        startTime(startTime < 0.1) = [];
        endTime(endTime < 0.1) = [];
        
        % Load intensity information if available
        if exist(fullfile(datapath, 'shockIntensities_and_perceivedSqueaks.xlsx'), 'file')
            shockInfo = readtable(fullfile(datapath, 'shockIntensities_and_perceivedSqueaks.xlsx'));
            
            % Build events table starting with shock info
            events = table(...
                repmat({'shock_tail'}, length(startTime), 1), ...
                startTime, endTime, ...
                'VariableNames', {'stimCond', 'startTime', 'endTime'});
            
            % Merge additional shock intensity columns
            if height(shockInfo) == height(events)
                for col = 1:width(shockInfo)
                    events.(shockInfo.Properties.VariableNames{col}) = ...
                        shockInfo.(shockInfo.Properties.VariableNames{col});
                end
            end
        else
            % Just basic event table
            events = table(...
                repmat({'shock_tail'}, length(startTime), 1), ...
                startTime, endTime, ...
                'VariableNames', {'stimCond', 'startTime', 'endTime'});
        end
        
    else
        % Left/right shock: detect falling/rising edges on channels 4 or 12
        startTime = ttlData(diff(ttlData(:,4)) < 0 | diff(ttlData(:,12)) < 0, 1);
        endTime = ttlData(diff(ttlData(:,4)) > 0 | diff(ttlData(:,12)) > 0, 1);
        
        % Build event conditions from CSV and rename
        stimConds = stimInfo.event(2:end);
        stimConds = strrep(stimConds, 'shock_left', 'shockOBS');
        stimConds = strrep(stimConds, 'shock_right', 'shockCTL');
        
        % Build events table
        events = table(stimConds, startTime, endTime, ...
            'VariableNames', {'stimCond', 'startTime', 'endTime'});
    end
end
