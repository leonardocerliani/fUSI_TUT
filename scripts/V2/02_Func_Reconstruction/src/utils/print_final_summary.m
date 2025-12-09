function print_final_summary(PDI, stimInfo, behavioral)
    % PRINT_FINAL_SUMMARY Display processing summary
    %
    %   print_final_summary(PDI, stimInfo, behavioral)
    
    fprintf('\n========================================\n');
    fprintf('Summary:\n');
    fprintf('  • PDI data: %d × %d pixels, %d frames\n', ...
        PDI.Dim.nx, PDI.Dim.nz, PDI.Dim.nt);
    
    % Stimulation summary
    if ~isempty(stimInfo)
        stimTypes = unique(stimInfo.stimCond);
        for i = 1:length(stimTypes)
            count = sum(strcmp(stimInfo.stimCond, stimTypes{i}));
            fprintf('  • %s: %d events\n', stimTypes{i}, count);
        end
    else
        fprintf('  • No stimulation events\n');
    end
    
    % Behavioral summary
    behavFound = {};
    if ~isempty(behavioral.wheelInfo)
        behavFound{end+1} = 'wheel';
    end
    if ~isempty(behavioral.gsensorInfo)
        behavFound{end+1} = 'gsensor';
    end
    if ~isempty(behavioral.pupil.pupilTime)
        behavFound{end+1} = 'pupil';
    end
    
    if ~isempty(behavFound)
        fprintf('  • Behavioral: %s\n', strjoin(behavFound, ' + '));
    else
        fprintf('  • No behavioral data\n');
    end
    
    fprintf('  • Duration: %.1f seconds\n', PDI.time(end));
    fprintf('========================================\n\n');
end
