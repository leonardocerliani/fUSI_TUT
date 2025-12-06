function fprintfd(varargin)
    if evalin('base', 'exist(''DEBUG'',''var'')')
        DEBUG = evalin('base', 'DEBUG');
        if DEBUG
            fprintf(varargin{:});
        end
    end
end
