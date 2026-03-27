% writeBinFileMex.m Help file for writeBinFileMex MEX-file.
%
%   Function to save binary data to disk, fast. Does not wait till writing is
%   finished but will detach from writing thread and finish writing data to disk
%   in the background.
%
%   Example Usage:
%     D = int16(magic(4));               % 4-by-4 int16 matrix
%     writeBinFileMex('test.bin', D);    % saves D to test.bin
%
%     D = int16(magic(4));               % 4-by-4 int16 matrix
%     writeBinFileMex('test.bin', D, 1); % saves D(:,2:3) to test.bin
%
%     D = randi(1000, 10, 20, 'int16');  % 100-by-20 int16 matrix
%     writeBinFileMex('test.bin', D, 5); % saves D(:,6:15) to test.bin
%     Dsmall = D(:,6:15)                 % indexed matrix
%     Dread = readBinFile('test.bin', size(Dsmall), '*int16') % output should be the same as Dsmall
%
%   Input arguments:  writeBinFileMex(fname, data, offset);
%     file name     file name as character array
%     data          data matrix (can only be int16 atm)
%     offset        column offset (see example). 2*offset has to be less then numel(data)
%
%   The MEX file has a safe and an unsafe mode.
%   - The safe mode will first make a copy of the data for the thread to be
%     detached. This means that the underlying data in MATLAB can be changed
%     after creating the copy. This is safer since potential write latency could
%     corrupt the data if MATLAB changes the data during writing. Data copying
%     is parallelized using OMP.
%   - The unsafe mode will not copy the data, but directly use the data pointer
%     underling the MATLAB array. This is slighly faster and consumes less
%     memory, but could lead to data corruption.
%   To use the unsafe mode can be used by compiling the program with the flag
%   SAFE_MODE=0. Default this is set to 1.
%
%   Safe mode:
%     mex COMPFLAGS="$COMPFLAGS /openmp /DSAFE_MODE=1" -R2018a -Iinclude src/*.cpp -output writeBinFileMex
%   Unsafe mode:
%     mex COMPFLAGS="$COMPFLAGS /openmp /DSAFE_MODE=0" -R2018a -Iinclude src/*.cpp -output writeBinFileMex
%
% Author        Rick Waasdorp (r.waasdorp@tudelft.nl)
% Version       1.0
% Date          2022-02-14
% Copyright     Copyright (c) 2022
