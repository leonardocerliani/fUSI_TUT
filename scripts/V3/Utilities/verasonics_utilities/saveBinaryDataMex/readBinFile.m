function [data, success] = readBinFile(fname, datasize, datatype, iscomplex, offset)
    % [data, success] = readBinFile(fname, datasize, datatype, iscomplex, offset)
    %   Function to read data from a .bin (binary) file. Input arguments
    %
    %       fname       file name to read (e.g. 'input.bin')
    %       datasize    array containing the sizes for each dimension.
    %                   To read a 2-by-3-by-10 array from a bin file, use datasize=[2, 3, 10]
    %       datatype    type of data (e.g. 'int16'/'int32'/'double'/'single', use * for correct type)
    %       iscomplex   flag to read complex data, set 1 if data to read is
    %                   complex. Will read as complex array of specified
    %                   size and type. 
    %       offset      offset in number of elements from file to read from,
    %                   in number of elements. Will be converted to number of
    %                   bytes using sizeof(datatype). Positive number denotes offset from
    %                   start of file, negative offset counts from end of file.
    %
    %   to read int16 and store as int16 provide datatype as '*int16'
    %   otherwise will return doubles
    %
    %   Requires freadcomplex from Matlab FEX to read complex data: 
    %     https://www.mathworks.com/matlabcentral/fileexchange/77530-freadcomplex-and-fwritecomplex
    % 
    % Author        Rick Waasdorp (r.waasdorp@tudelft.nl)
    % Version       1.0
    % Date          2022-05-10
    % Copyright     Copyright (c) 2022
    % 
    if ~exist('datatype', 'var') || isempty(datatype)
        datatype = 'double';
    end
    if ~exist('iscomplex', 'var') || isempty(iscomplex)
        iscomplex = 0;
    end
    if ~exist('offset', 'var') || isempty(offset)
        offset = 0;
    end

    % open file
    fileID = fopen(fname, 'r');
    if fileID > 0
        % seek file of offset
        offset = offset * class2byte(datatype) * (1+iscomplex); % multiply bytes offset by size of datatype
        if offset > 0
            fseek(fileID, offset, 'bof');
        elseif offset < 0
            fseek(fileID, offset, 'eof');
        end

        % read data
        if ~iscomplex
            data = fread(fileID, prod(datasize), datatype);
        else
            data = freadcomplex(fileID, prod(datasize), datatype);
        end
        fclose(fileID);
        if numel(datasize) > 1
            data = reshape(data, datasize);
        end
        success = true;
    else
        fprintf('ERROR: Could not open file %s\n', fname);
        data = [];
        success = false;
    end
end
