function compile_writeBinFileMex(safeMode)
    % function to compile writeBinFileMex. See `help writeBinFileMex` for more details
    %
    if ~exist('safeMode', 'var')
        safeModeFlag = 1;
    else
        if ischar(safeMode); safeMode = str2double(safeMode); end
        safeModeFlag = safeMode > 0;
    end
    compStr = sprintf('mex COMPFLAGS="$COMPFLAGS /openmp /DSAFE_MODE=%i" -R2018a -Iinclude src/*.cpp -output writeBinFileMex', safeModeFlag);
    disp(compStr)
    eval(compStr)
end
