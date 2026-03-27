/**
 * @file main.cpp
 * @author Rick Waasdorp (r.waasdorp@tudelft.nl)
 * @brief Function to save binary data on Windows and detach from save thread
 * @version 0.1
 * @date 2021-12-06
 *
 * @copyright Copyright (c) 2021
 *
 */

#include "mex.h"
#include "debugTools.hpp"
#include "Timer.hpp"
#include "saveFunctions.hpp"
#include "coutWindows.hpp"

#ifndef SAFE_MODE
#define SAFE_MODE 1
#endif

void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
    if (nrhs < 2)
        mexErrMsgIdAndTxt("writeBinFileMex:input:notenoughinputarguments", "Not enough input arguments :'(");
    // check input types
    if (mxGetClassID(prhs[0]) != mxCHAR_CLASS)
        mexErrMsgIdAndTxt("writeBinFileMex:input:dataype", "Only char array (not string) is supported for the filename at the moment.");
    if (mxGetClassID(prhs[1]) != mxINT16_CLASS)
        mexErrMsgIdAndTxt("writeBinFileMex:input:dataype", "Only int16 is supported at the moment.");
    // check that its 2D matrix
    if (mxGetNumberOfDimensions(prhs[1]) != 2)
        mexErrMsgIdAndTxt("writeBinFileMex:input:ndims", "Only 2D matrices are supported at the moment.");

    // read inputs
    const char *fname = mxArrayToString(prhs[0]);
    const mxArray *mxPtr = prhs[1];
    size_t nelems = mxGetNumberOfElements(mxPtr);
    int16_t *ptr = (int16_t *)mxGetData(mxPtr);

    if (nrhs == 3)
    {
        size_t offset = 0;
        size_t rows = mxGetM(prhs[1]);
        size_t cols = mxGetN(prhs[1]);
        size_t ncols_offset = (size_t)mxGetScalar(prhs[2]);
        offset = ncols_offset * rows;
        if (2 * offset >= nelems)
            mexErrMsgIdAndTxt("writeBinFileMex:input:offset", "offset too large");
        nelems -= offset * 2;
        ptr += offset;
    }

    int errorcode = saveBinFile(fname, ptr, nelems);
    if (errorcode)
        std::cout << "ERROR" << std::endl;
}
