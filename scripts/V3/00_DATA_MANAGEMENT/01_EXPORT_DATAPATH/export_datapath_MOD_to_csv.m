function export_datapath_MOD_to_csv()

    conditions = { ...
        'VisualTest','ShockTest','VS','SO','FR','SS', ...
        'SOcFOS','SOFC','VisualTestMultiSlice','USStimulation','ElectrodeTest'};

    rows = {};
    rowCount = 0;  % Track row count explicitly

    for c = 1:length(conditions)
        cond = conditions{c};

        try
            [subDataPath, subAnatPath, ~] = Datapath_MOD(cond);
        catch ME
            warning('Error in condition %s:\n%s', cond, ME.message);
            continue;
        end

        n = length(subDataPath);

        % Handle empty or mismatched subAnatPath
        if isempty(subAnatPath)
            subAnatPath = repmat({''}, n, 1);
        elseif ~iscell(subAnatPath)
            % Convert to cell if needed
            subAnatPath = {subAnatPath};
        end
        
        % Ensure subAnatPath is a column cell array
        if isrow(subAnatPath)
            subAnatPath = subAnatPath';
        end

        if length(subAnatPath) ~= n
            if length(subAnatPath) >= 1
                subAnatPath = repmat(subAnatPath(1), n, 1);
            else
                subAnatPath = repmat({''}, n, 1);
            end
        end

        for i = 1:n
            funcPath = subDataPath{i};
            anatPath = subAnatPath{i};

            subject = extract_token(funcPath, 'sub-[^/]+|animal[0-9]+');
            session = extract_token(funcPath, 'ses-[0-9]+');
            run = extract_token(funcPath, 'run-[^/]+');

            if contains(funcPath, 'fUSIMethodsPaper')
                project = 'fUSIMethodsPaper';
            elseif contains(funcPath, 'fUSIEmotionalContagion')
                project = 'fUSIEmotionalContagion';
            elseif contains(funcPath, 'USS')
                project = 'USS';
            else
                project = 'Unknown';
            end

            if contains(funcPath, '/data06')
                orig_root = 'data06';
            elseif contains(funcPath, '/data03')
                orig_root = 'data03';
            else
                orig_root = 'unknown';
            end

            % Use row counter instead of end+1 with column indexing
            rowCount = rowCount + 1;
            rows{rowCount, 1} = project;
            rows{rowCount, 2} = cond;
            rows{rowCount, 3} = subject;
            rows{rowCount, 4} = session;
            rows{rowCount, 5} = run;
            rows{rowCount, 6} = funcPath;
            rows{rowCount, 7} = anatPath;
            rows{rowCount, 8} = orig_root;
        end
    end

    if isempty(rows)
        error('No data collected. Check Datapath function.');
    end

    T = cell2table(rows, 'VariableNames', { ...
        'project','condition','subject_id','session_id','func_run_id', ...
        'functional_path','anatomical_path','orig_root'});

    writetable(T, 'original_Datapath_location.csv');

    fprintf('CSV exported successfully to: %s\n', fullfile(pwd, 'original_Datapath_location.csv'));
    fprintf('Total rows exported: %d\n', rowCount);
end


function token = extract_token(str, pattern)
    match = regexp(str, pattern, 'match');
    if isempty(match)
        token = '';
    else
        token = match{1};
    end
end
