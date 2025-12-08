/******************************************************************************
 *
 * MATLAB (R) is a trademark of The Mathworks (R) Corporation
 *
 * Function:    fwritecomplex
 * Filename:    fwritecomplex.c
 * Programmer:  James Tursa
 * Version:     1.1
 * Date:        July 1, 2020
 * Copyright:   (c) 2020 by James Tursa, All Rights Reserved
 *
 *  This code uses the BSD License:
 *
 *  Redistribution and use in source and binary forms, with or without 
 *  modification, are permitted provided that the following conditions are 
 *  met:
 *
 *     * Redistributions of source code must retain the above copyright 
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright 
 *       notice, this list of conditions and the following disclaimer in 
 *       the documentation and/or other materials provided with the distribution
 *      
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
 *  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
 *  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
 *  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
 *  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
 *  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 *  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 *  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
 *  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
 *  POSSIBILITY OF SUCH DAMAGE.
 *
 * fwritecomplex writes a file containing interleaved complex data.  Uses
 * callbacks into MATLAB for the actual fwrite( ) function with a doubled
 * size.  Works with R2018a or later only.
 *
 * Building:
 *
 * fwritecomplex requires that a mex routine be built (one time only). This
 * process is typically self-building the first time you call the function
 * as long as you have the following files in the same directory somewhere
 * on the MATLAB path:
 *
 *   fwritecomplex.c
 *   fwritecomplex.m
 *   matlab_version.h
 * 
 * If you need to manually build the mex function, here are the commands:
 *
 * On later versions of MATLAB R2018a or later:
 * >> mex fwritecomplex.c -R2018a
 *
 * Syntax: Since this mex routine calls back into MATLAB, it has the same
 * input syntax as the MATLAB fwrite( ) function.  See the official doc for
 * the input descriptions.
 *
 *   fwritecomplex(fileID,A)
 *   fwritecomplex(fileID,A,precision)
 *   fwritecomplex(fileID,A,precision,skip)
 *   fwritecomplex(fileID,A,precision,skip,machinefmt)
 *   count = fwrite(___)
 *
 * There is one additional syntax which returns the version of this routine:
 *
 *   S = fwritecomplex('version')
 *
 * Revision History:
 * 1.1  2020-July-01  Original Release
 *
 ********************************************************************************/

// Includes -------------------------------------------------------------------

#include "mex.h"
#include "string.h"
#include "matlab_version.h"

// Macros ---------------------------------------------------------------------

#define VERSION "1.1"

// Gateway Function -----------------------------------------------------------

void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    int i, fail = 0;
    char *v;
    mwSize ndim;
    mwSize *dims;
    mxArray *mxreal;

/* Check version */
    if( TARGET_API_VERSION == R2017b ) {
        mexErrMsgTxt("This mex routine must be compiled with the -R2018a option.");
    }
    
/* Check for version request */
    if( nrhs == 1 && mxIsChar(prhs[0]) ) {
        v = mxArrayToString(prhs[0]);
        if( strcmp(v,"version") == 0 ) {
            mxFree(v);
            plhs[0] = mxCreateString(VERSION);
            return;
        }
        mxFree(v);
    }
    
/* Check number of arguments */
    if( nrhs < 2 ) {
        mexErrMsgTxt("Not enough input arguments.");
    }
    if( nrhs > 5 ) {
        mexErrMsgTxt("Too many output arguments.");
    }

/* Check for numeric input */
    if( !mxIsNumeric(prhs[1]) ) {
        mexErrMsgTxt("2nd input must be numeric.");
    }

/* If input is real, simply call fwrite now */
    if( !mxIsComplex(prhs[1]) ) {
        if( mexCallMATLAB(nlhs,plhs,nrhs,prhs,"fwrite") ) {
            mexErrMsgTxt("Unable to write data.");
        }
        return;
    }
    
/* Create an empty real version of the variable */
    ndim = mxGetNumberOfDimensions(prhs[1]);
    dims = mxGetDimensions(prhs[1]);
    mxreal = mxCreateNumericMatrix(0,0,mxGetClassID(prhs[1]),mxREAL); /* Create empty real */
    
/* Attach the data pointer and set the dimensions */    
    mxSetData(mxreal,mxGetData(prhs[1]));
    mxSetDimensions(mxreal,dims,ndim);
    dims = mxGetDimensions(mxreal);
    
/* Double the first dimension of the real variable and write it out */
    dims[0] *= 2;
    prhs[1] = mxreal;
    if( mexCallMATLAB(nlhs,plhs,nrhs,prhs,"fwrite") ) {
        fail = 1;
    }
    
/* Detach data pointer and destroy real array */
    mxSetData(prhs[1],NULL);
    mxDestroyArray(prhs[1]);
    
/* Check for failure */
    if( fail ) {
        mexErrMsgTxt("Unable to write data.");
    }
}
