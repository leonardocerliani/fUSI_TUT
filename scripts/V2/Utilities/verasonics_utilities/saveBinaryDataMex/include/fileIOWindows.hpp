#ifndef __FILEIOWINDOWS_HPP__
#define __FILEIOWINDOWS_HPP__

#include <windows.h>
#include <iostream>
#include <stdio.h>
#include <string>
#include <fstream>
#include <system_error>

void writeBinFileWindows(const char *fname, int16_t *int_data, size_t numel, size_t buf_size /*= 8*/);
void readBinFileWindows(const char *fname, int16_t *int_data, size_t numel);
std::string GetLastErrorAsString();

#endif