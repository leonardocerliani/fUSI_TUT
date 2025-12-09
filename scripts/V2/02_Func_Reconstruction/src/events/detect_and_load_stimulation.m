function stimInfo = detect_and_load_stimulation(datapath, ttlData, nidaqLog, config)
    % DETECT_AND_LOAD_STIMULATION Auto-detect stim files and extract events
    %
    %   stimInfo = detect_and_load_stimulation(datapath, ttlData, nidaqLog, config)
    
    stimInfo = table();
    ttl = config.ttl_channels;
    
    % Check for visual stimulation
    if exist(fullfile(datapath, 'VisualStimulation.csv'), 'file') && isfield(ttl, 'visual')
        events = extract_visual_events(datapath, ttlData, nidaqLog, ttl.visual);
        if ~isempty(events)
            stimInfo = [stimInfo; events];
            fprintf('  ✓ Visual stimulation: VisualStimulation.csv\n');
            fprintf('    → Found %d visual events (channel %d)\n', height(events), ttl.visual);
        end
    else
        fprintf('  ✗ Visual stimulation: Not found\n');
    end
    
    % Check for shock stimulation
    if exist(fullfile(datapath, 'ShockStimulation.csv'), 'file') && isfield(ttl, 'shock')
        events = extract_shock_events(datapath, ttlData, ttl.shock);
        if ~isempty(events)
            stimInfo = [stimInfo; events];
            fprintf('  ✓ Shock stimulation: ShockStimulation.csv\n');
            if length(ttl.shock) > 1
                fprintf('    → Found %d shock events (channels %s)\n', height(events), ...
                    strjoin(arrayfun(@num2str, ttl.shock, 'UniformOutput', false), ', '));
            else
                fprintf('    → Found %d shock events (channel %d)\n', height(events), ttl.shock);
            end
        end
    else
        fprintf('  ✗ Shock stimulation: Not found\n');
    end
    
    % Check for auditory stimulation
    if exist(fullfile(datapath, 'auditoryStimulation.csv'), 'file') && isfield(ttl, 'auditory')
        events = extract_auditory_events(datapath, ttlData, nidaqLog, ttl.auditory);
        if ~isempty(events)
            stimInfo = [stimInfo; events];
            fprintf('  ✓ Auditory stimulation: auditoryStimulation.csv\n');
            fprintf('    → Found %d auditory events (channel %d)\n', height(events), ttl.auditory);
        end
    else
        fprintf('  ✗ Auditory stimulation: Not found\n');
    end
    
    % Sort by start time
    if ~isempty(stimInfo)
        stimInfo = sortrows(stimInfo, 'startTime');
    end
end
