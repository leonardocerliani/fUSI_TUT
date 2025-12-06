% freadcomplex reads a data file directly into a complex variable
% /******************************************************************************
%  *
%  * MATLAB (R) is a trademark of The Mathworks (R) Corporation
%  *
%  * Function:    freadcomplex
%  * Filename:    freadcomplex.c
%  * Programmer:  James Tursa
%  * Version:     1.1
%  * Date:        July 1, 2020
%  * Copyright:   (c) 2020 by James Tursa, All Rights Reserved
%  *
%  *  This code uses the BSD License:
%  *
%  *  Redistribution and use in source and binary forms, with or without 
%  *  modification, are permitted provided that the following conditions are 
%  *  met:
%  *
%  *     * Redistributions of source code must retain the above copyright 
%  *       notice, this list of conditions and the following disclaimer.
%  *     * Redistributions in binary form must reproduce the above copyright 
%  *       notice, this list of conditions and the following disclaimer in 
%  *       the documentation and/or other materials provided with the distribution
%  *      
%  *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
%  *  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
%  *  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
%  *  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
%  *  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
%  *  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
%  *  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
%  *  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
%  *  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
%  *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
%  *  POSSIBILITY OF SUCH DAMAGE.
%  *
%  * freadcomplex reads a file containing interleaved complex data directly into
%  * a MATLAB variable.  Uses callbacks into MATLAB for the actual fread( )
%  * function with a doubled size, then internally converts the result to a
%  * complex variable with the original size.  Works with R2018a or later only.
%  *
%  * If there is a mismatch between the requested size and the quantity of
%  * numbers in the file, this mex routine will simply return whatever the
%  * MATLAB function fread( ) returns in that case.
%  *
%  * Building:
%  *
%  * freadcomplex requires that a mex routine be built (one time only). This
%  * process is typically self-building the first time you call the function
%  * as long as you have the following files in the same directory somewhere
%  * on the MATLAB path:
%  *
%  *   freadcomplex.c
%  *   freadcomplex.m
%  *   matlab_version.h
%  * 
%  * If you need to manually build the mex function, here are the commands:
%  *
%  * On later versions of MATLAB R2018a or later:
%  * >> mex freadcomplex.c -R2018a
%  *
%  * Syntax: Since this mex routine calls back into MATLAB, it has the same
%  * input syntax as the MATLAB fread( ) function.  See the official doc for
%  * the input descriptions.
%  *
%  *   A = freadcomplex(fileID)
%  *   A = freadcomplex(fileID,sizeA)
%  *   A = freadcomplex(fileID,sizeA,precision)
%  *   A = freadcomplex(fileID,sizeA,precision,skip)
%  *   A = freadcomplex(fileID,sizeA,precision,skip,machinefmt)
%  *   [A,count] = freadcomplex(___)
%  *
%  * CAUTION: If the file has an odd number of values, this routine will either
%  * tack on on extra imaginary 0 part for the last element or not use the last
%  * file value for the result.  Which behavior you get will depend on whatever
%  * behavior the MATLAB fread( ) function does for the sizeA input you give it.
%  *
%  * There is one additional syntax which returns the version of this routine:
%  *
%  *   S = freadcomplex('version')
%  *
%  * Revision History:
%  * 1.0  2020-June-30  Original Release
%  * 1.1  2020-July-01  Updated for inf sizeA inputs
%  *
%  ********************************************************************************/

function varargout = freadcomplex(varargin)
disp(' ');
disp('You must build the mex routine before you can use freadcomplex.');
disp('Attempting to do so now ...');
disp(' ');
[path, mname] = fileparts(mfilename('fullpath'));
cname = fullfile(path, 'freadcomplex', [mname '.c']);
if( isempty(dir(cname)) )
    disp('Cannot find the file freadcomplex.c in the same directory as the');
    disp('file freadcomplex.m. Please ensure that they are in the same');
    disp('directory and try again. The following file was not found:');
    disp(' ');
    disp(cname);
    disp(' ');
    error('Unable to compile freadcomplex.c');
else
    disp(['Found file freadcomplex.c in ' cname]);
    disp(' ');
    disp('Now attempting to compile ...');
    disp('(If prompted, please press the Enter key and then select any C/C++');
    disp('compiler that is available, such as lcc.)');
    disp(' ');
    try
        v = hex2dec(version('-release'));
    catch
        v = 0;
    end
    R2018a = hex2dec('2018a');
    if( v < R2018a )
        error('This mex routine must be compiled with R2018a or later');
    end
    mex(cname,'-R2018a');
    disp(' ');
    disp('mex freadcomplex.c build completed ... you may now use freadcomplex.');
    disp(' ');
    if( nargout == 0 )
        varargout{1} = freadcomplex(varargin{:});
    else
        [varargout{:}] = freadcomplex(varargin{:});
    end
end
end
