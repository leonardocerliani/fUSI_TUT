function TimeTagEnable()
    % TIMETAGENABLE - function to enable the time tag in RcvData on the Verasonics.
    % First two samples per acquisition will contain the timestamp.
    % Time tag counter is a 32 bit value, that increments every 25 usec,
    % so we have to scale by 25 * 1e-6 to convert to a value in seconds
    %
    % To enable the Time tag, have a struct P with field TimeTagEna:
    %       P.TimeTagEna = 1;
    % Then call this function during initialisation of VSX, for example
    % using UI.Statment:
    %       UI(1).Statement = 'TimeTagInit()';
    %
    % R. Waasdorp, 11-03-2021
    %
    import com.verasonics.hal.hardware.*
    TimeTagEna = evalin('base', 'P.TimeTagEna');
    VDAS = evalin('base', 'VDAS');
    switch TimeTagEna
        case 0
            if VDAS% can't execute this command if HW is not present
                % disable time tag
                rc = Hardware.enableAcquisitionTimeTagging(false);
                if ~rc
                    error('Error from enableAcqTimeTagging')
                end
            end
        case 1
            if VDAS
                % enable time tag
                rc = Hardware.enableAcquisitionTimeTagging(true);
                if ~rc
                    error('Error from enableAcqTimeTagging')
                end
            end
        case 2
            if VDAS
                % enable time tag and reset counter
                rc = Hardware.enableAcquisitionTimeTagging(true);
                if ~rc
                    error('Error from enableAcqTimeTagging')
                end
                rc = Hardware.setTimeTaggingAttributes(false, true);
                if ~rc
                    error('Error from setTimeTaggingAttributes')
                end
            end
    end
end
