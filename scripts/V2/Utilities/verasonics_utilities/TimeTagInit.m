function TimeTagInit()
    import com.verasonics.hal.hardware.*
    VDAS = evalin('base', 'VDAS');
    if VDAS
        % enable time tag
        rc = Hardware.enableAcquisitionTimeTagging(true);
        if ~rc
            error('Error from enableAcqTimeTagging')
        end
        % and reset counter
        rc = Hardware.setTimeTaggingAttributes(false, true);
        if ~rc
            error('Error from setTimeTaggingAttributes')
        end
    end
end
