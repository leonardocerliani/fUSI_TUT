function out = class2byte(in)
    % spits out the number of bytes for a datatype
    in = strrep(in, '*', '');
    numclass = {'double'; 'single'; 'int8'; 'int16'; 'int32'; 'int64'; 'uint8'; 'uint16'; 'uint32'; 'uint64'};
    numbytes = [8; 4; 1; 2; 4; 8; 1; 2; 4; 8];
    out = numbytes(strcmp(in, numclass));
end
