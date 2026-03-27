% fwritecomplex writes an interleaved complex variable to a file
% /******************************************************************************
%  *
%  * MATLAB (R) is a trademark of The Mathworks (R) Corporation
%  *
%  * Function:    fwritecomplex
%  * Filename:    fwritecomplex.c
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
%  * fwritecomplex writes a file containing interleaved complex data.  Uses
%  * callbacks into MATLAB for the actual fwrite( ) function with a doubled
%  * size.  Works with R2018a or later only.
%  *
%  * Building:
%  *
%  * fwritecomplex requires that a mex routine be built (one time only). This
%  * process is typically self-building the first time you call the function
%  * as long as you have the following files in the same directory somewhere
%  * on the MATLAB path:
%  *
%  *   fwritecomplex.c
%  *   fwritecomplex.m
%  *   matlab_version.h
%  * 
%  * If you need to manually build the mex function, here are the commands:
%  *
%  * On later versions of MATLAB R2018a or later:
%  * >> mex fwritecomplex.c -R2018a
%  *
%  * Syntax: Since this mex routine calls back into MATLAB, it has the same
%  * input syntax as the MATLAB fwrite( ) function.  See the official doc for
%  * the input descriptions.
%  *
%  *   fwritecomplex(fileID,A)
%  *   fwritecomplex(fileID,A,precision)
%  *   fwritecomplex(fileID,A,precision,skip)
%  *   fwritecomplex(fileID,A,precision,skip,machinefmt)
%  *   count = fwrite(___)
%  *
%  * There is one additional syntax which returns the version of this routine:
%  *
%  *   S = fwritecomplex('version')
%  *
%  * Revision History:
%  * 1.1  2020-July-01  Original Release
%  *
%  ********************************************************************************/

function varargout = fwritecomplex(varargin)
disp(' ');
disp('You must build the mex routine before you can use fwritecomplex.');
disp('Attempting to do so now ...');
disp(' ');
[path, mname] = fileparts(mfilename('fullpath'));
cname = fullfile(path, 'freadcomplex', [mname '.c']);
if( isempty(dir(cname)) )
    disp('Cannot find the file fwritecomplex.c in the same directory as the');
    disp('file fwritecomplex.m. Please ensure that they are in the same');
    disp('directory and try again. The following file was not found:');
    disp(' ');
    disp(cname);
    disp(' ');
    error('Unable to compile fwritecomplex.c');
else
    disp(['Found file fwritecomplex.c in ' cname]);
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
    disp('mex fwritecomplex.c build completed ... you may now use fwritecomplex.');
    disp(' ');
    if( nargout == 0 )
        varargout{1} = fwritecomplex(varargin{:});
    else
        [varargout{:}] = fwritecomplex(varargin{:});
    end
end
end
