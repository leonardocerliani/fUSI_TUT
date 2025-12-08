/**
 * @file saveFunctions.hpp
 * @author Rick Waasdorp (r.waasdorp@tudelft.nl)
 * @brief Function to save binary data on Windows and detach from saving thread
 * @version 0.1
 * @date 2021-12-06
 *
 * @copyright Copyright (c) 2021
 *
 */

#ifndef __SAVEFUNCTIONS_HPP__
#define __SAVEFUNCTIONS_HPP__

#include <windows.h>
#include <iostream>
#include <stdio.h>
#include <fstream>
#include <thread>
#include "omp.h"

#include "fileIOWindows.hpp"
#include "debugTools.hpp"
#include "Timer.hpp"

#define COPY_DATA_THREAD SAFE_MODE // if 1, copies the data to other location in RAM, of 0 uses saves data in RAM
#define DETACH_WRITE_THREAD 1      // if 0, thread is not detached. slower
#define NUM_SAMPLES_VALIDATION 10  // x at start and x at end of file, so total 2*x read and validated

int saveBinFile(const char *fname, int16_t *int_data, size_t numel);
void saveBinFile_detach(const char *fname, HANDLE file, int16_t *int_data, size_t numel);
void writeData(HANDLE file, int16_t *int_data, size_t numel, size_t buf_size = 8);
bool validateDataWindows(const char *fname, int16_t *val_data, size_t size);

#endif //!__SAVEFUNCTIONS_HPP__
