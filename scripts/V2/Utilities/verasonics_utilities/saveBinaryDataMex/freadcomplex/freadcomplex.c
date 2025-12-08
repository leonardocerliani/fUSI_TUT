/******************************************************************************
 *
 * MATLAB (R) is a trademark of The Mathworks (R) Corporation
 *
 * Function:    freadcomplex
 * Filename:    freadcomplex.c
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
 * freadcomplex reads a file containing interleaved complex data directly into
 * a MATLAB variable.  Uses callbacks into MATLAB for the actual fread( )
 * function with a doubled size, then internally converts the result to a
 * complex variable with the original size.  Works with R2018a or later only.
 *
 * If there is a mismatch between the requested size and the quantity of
 * numbers in the file, this mex routine will simply return whatever the
 * MATLAB function fread( ) returns in that case.
 *
 * Building:
 *
 * freadcomplex requires that a mex routine be built (one time only). This
 * process is typically self-building the first time you call the function
 * as long as you have the following files in the same directory somewhere
 * on the MATLAB path:
 *
 *   freadcomplex.c
 *   freadcomplex.m
 *   matlab_version.h
 * 
 * If you need to manually build the mex function, here are the commands:
 *
 * On later versions of MATLAB R2018a or later:
 * >> mex freadcomplex.c -R2018a
 *
 * Syntax: Since this mex routine calls back into MATLAB, it has the same
 * input syntax as the MATLAB fread( ) function.  See the official doc for
 * the input descriptions.
 *
 *   A = freadcomplex(fileID)
 *   A = freadcomplex(fileID,sizeA)
 *   A = freadcomplex(fileID,sizeA,precision)
 *   A = freadcomplex(fileID,sizeA,precision,skip)
 *   A = freadcomplex(fileID,sizeA,precision,skip,machinefmt)
 *   [A,count] = freadcomplex(___)
 *
 * CAUTION: If the file has an odd number of values, this routine will either
 * tack on on extra imaginary 0 part for the last element or not use the last
 * file value for the result.  Which behavior you get will depend on whatever
 * behavior the MATLAB fread( ) function does for the sizeA input you give it.
 *
 * There is one additional syntax which returns the version of this routine:
 *
 *   S = freadcomplex('version')
 *
 * Revision History:
 * 1.0  2020-June-30  Original Release
 * 1.1  2020-July-01  Updated for inf sizeA inputs
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
    int i, sizeA_present = 0;
    mxArray *rhs[5];
    mxArray *dimensions, *mxcomplex;
    double *ddims;
    mwSize ndim;
    mwSize *dims, *cdims;
    char *v;

/* Check version */
    if( TARGET_API_VERSION == R2017b ) {
        mexErrMsgTxt("This mex routine must be compiled with the -R2018a option.");
    }
    
/* Check number of arguments */
    if( nrhs == 0 ) {
        mexErrMsgTxt("Not enough input arguments.");
    }
    if( nrhs > 5 ) {
        mexErrMsgTxt("Too many output arguments.");
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

/* Copy input arguments */
    for( i=0; i<nrhs; i++ ) {
        rhs[i] = (mxArray *) prhs[i];
    }
    
/* If SizeA is present */
    if( nrhs >= 2 && mxIsNumeric(prhs[1]) ) {
        sizeA_present = 1;
        if( mxIsComplex(prhs[1]) ) {
            mexErrMsgTxt("Size must be a real number.");
        }
        if( mexCallMATLAB(1, &dimensions, 1, prhs+1, "double") ) {
            mexErrMsgTxt("Unable to convert sizeA to double");
        }
        if( mxIsSparse(dimensions) ) {
            mexCallMATLAB(1, rhs+1, 1, &dimensions, "full");
            mxDestroyArray(dimensions);
        } else {
            rhs[1] = dimensions;
        }
/* Double the first dimension */
        ddims = (double *)mxGetData(rhs[1]);
        ndim = mxGetNumberOfElements(rhs[1]);
        for( i=0; i<ndim; i++ ) {
            if( mxIsFinite(ddims[i]) ) {
                ddims[i] = (mwSize) ddims[i];
            }
        }
        ddims[0] *= 2.0;
    }
    
/* Read the data */
    if( mexCallMATLAB(nlhs?nlhs:1, plhs, nrhs, rhs, "fread") ) {
        mexErrMsgTxt("Unable to read data from file.");
    }
    
/* Clean up temporary dimension array */
    if( sizeA_present ) {
        mxDestroyArray(rhs[1]);
    }
    
/* Convert to complex variable with half the elements */ 
    if( !mxIsNumeric(plhs[0]) ) {
        mexErrMsgTxt("Unable to convert precision to complex.");
    }
    ndim = mxGetNumberOfDimensions(plhs[0]);
    dims = mxGetDimensions(plhs[0]);
    cdims = mxMalloc(ndim*sizeof(mwSize));
    for( i=0; i<ndim; i++ ) {
        cdims[i] = dims[i];
    }
    if( cdims[0]%2 ) { /* if first dimension is odd, return column vector */
        cdims[0] = mxGetNumberOfElements(plhs[0]) / 2; /* might lose last value */
        cdims[1] = 1;
        ndim = 2;
        if( mxGetNumberOfElements(plhs[0])%2 ) {
            mexWarnMsgTxt("File has odd number of values, last value not used.");
        }
    } else {
        cdims[0] /= 2; /* halve the first dimension */
    }
    mxcomplex = mxCreateNumericMatrix(0,0,mxGetClassID(plhs[0]),mxCOMPLEX); /* Create empty complex */
    mxSetData(mxcomplex,mxGetData(plhs[0])); /* Transfer data pointer */
    mxSetData(plhs[0],NULL); /* Null out the data pointer from original */
    mxDestroyArray(plhs[0]); /* Get rid of real variable */
    mxSetDimensions(mxcomplex,cdims,ndim); /* Set the halved dimensions */
    plhs[0] = mxcomplex; /* return the complex variable instead */
}
