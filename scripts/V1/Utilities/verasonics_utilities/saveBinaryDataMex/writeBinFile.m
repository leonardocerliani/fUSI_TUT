function success = writeBinFile(fname, data, datatype, append)
    % success = writeBinFile(fname, data, datatype)
    %   Function to write data to a .bin (binary) file. Input arguments
    %
    %       fname       file name to write (e.g. 'output.bin')
    %       data        data to write
    %       datatype    type of data (e.g. 'int16'/'int32'/'double'/'single')
    %
    %   If datatype not explicitly specified, will be set to class(data)
    %
    %   Requires fwritecomplex from Matlab FEX to write complex data:
    %     https://www.mathworks.com/matlabcentral/fileexchange/77530-freadcomplex-and-fwritecomplex
    %
    % Author        Rick Waasdorp (r.waasdorp@tudelft.nl)
    % Version       1.0
    % Date          2022-05-10
    % Copyright     Copyright (c) 2022
    %
    if ~exist('datatype', 'var') || isempty(datatype)
        datatype = class(data);
    end
    if ~exist('append', 'var') || isempty(append)
        append = false;
    end
    if append
        open_mode = 'A';
    else
        open_mode = 'W';
    end

    % open file
    fileID = fopen(fname, open_mode);
    if fileID > 0
        % WRITE data
        if isreal(data)
            fwrite(fileID, data, datatype);
        else
            fwritecomplex(fileID, data, datatype);
        end
        fclose(fileID);
        success = true;
    else
        fprintf('ERROR: Could not open file %s\n', fname);
        success = false;
    end
end
