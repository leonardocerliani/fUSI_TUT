#include "saveFunctions.hpp"

int saveBinFile(const char *fname, int16_t *int_data, size_t numel)
{
    // create output file
    HANDLE file = CreateFileA(fname,
                              GENERIC_WRITE,
                              0,
                              NULL,
                              CREATE_ALWAYS,
                              FILE_FLAG_SEQUENTIAL_SCAN,
                              NULL);
    if (file == INVALID_HANDLE_VALUE)
    {
        std::cout << "[WRITE ERROR] Invalid file: " << file << std::endl;
        std::cout << "[WRITE ERROR] " << GetLastErrorAsString() << std::endl;
        return 1;
    }

#if COPY_DATA_THREAD
    // save mode, copy the data to the thread to be detached
    size_t part = 1024 * 1024; // 1 MiB block size
    size_t blocks = (size_t)numel / part;
    size_t rem = numel % part;
    int16_t *data_cpy = new int16_t[numel];

#pragma omp parallel for
    for (long long start = 0; start <= numel - part; start += part)
        std::copy(int_data + start, int_data + start + part, data_cpy + start);
    // and the remainder
    if (rem)
        std::copy(int_data + numel - rem, int_data + numel, data_cpy + numel - rem);
    int_data = data_cpy; // overwrite data ptr
#endif

    // call the write function and detach
#if DETACH_WRITE_THREAD
    std::thread t(saveBinFile_detach, fname, file, int_data, numel);
    t.detach();
    // try
    // {
    //     t.detach();
    // }
    // catch (const std::system_error &e)
    // {
    //     std::cout << "Caught system_error with code " << e.code()
    //               << " meaning " << e.what() << '\n';
    //     CloseHandle(file);
    // }
#else
    saveBinFile_detach(fname, file, int_data, numel); // for debugging
#endif

    return 0;
}

void saveBinFile_detach(const char *fname, HANDLE file, int16_t *int_data, size_t numel)
{
    // get some samples for validation
    // int16_t *val_data = new int16_t[NUM_SAMPLES_VALIDATION * 2]; // for now first 2 and last 2 samples
    // for (size_t i = 0; i < NUM_SAMPLES_VALIDATION; i++)
    // {
    //     val_data[i] = int_data[i];
    //     val_data[i + NUM_SAMPLES_VALIDATION] = int_data[numel - NUM_SAMPLES_VALIDATION + i];
    // }

    // write data
    writeData(file, int_data, numel, 8);

    // read some samples
    // bool success = validateDataWindows(fname, val_data, numel);
    // if (!success)
    //     _DEBUG_MSG("DATA IS DIFFERENT");
    // else
    //     _DEBUG_MSG("DATA IS EQUAL");
    // _DEBUG_MSG("success = " << success);

    // rwTODO(#11): validate written data by either calculating the HASH, or better,
    // keeping a couple samples in memory and reading a couple samples at the
    // beginning and end of the file
}

void writeData(HANDLE file, int16_t *int_data, size_t numel, size_t buf_size /*= 8*/)
{
    size_t part = buf_size * 1024 * 1024;
    size_t size = numel * sizeof(int16_t);
    char *data = reinterpret_cast<char *>(int_data);

    // Expand file size
    SetFilePointer(file, size, NULL, FILE_BEGIN);
    SetEndOfFile(file);
    SetFilePointer(file, 0, NULL, FILE_BEGIN);

    DWORD written;
    if (size < part)
    {
        WriteFile(file, data, size, &written, NULL);
        CloseHandle(file);
        return;
    }

    size_t rem = size % part;
    for (size_t i = 0; i < size - rem; i += part)
        WriteFile(file, data + i, part, &written, NULL);
    if (rem)
        WriteFile(file, data + size - rem, rem, &written, NULL);
    CloseHandle(file);

#if COPY_DATA_THREAD
    delete[] data; // and delete data in this thread
#endif
}

bool validateDataWindows(const char *fname, int16_t *val_data, size_t numel)
{
    HANDLE file = CreateFileA(fname,
                              GENERIC_READ,
                              0,
                              NULL,
                              OPEN_EXISTING,
                              FILE_FLAG_SEQUENTIAL_SCAN,
                              NULL);

    // if (file == INVALID_HANDLE_VALUE)
    // {
    //     std::cout << "[READ ERROR] Invalid file: " << file << std::endl;
    //     std::cout << "[READ ERROR] " << GetLastErrorAsString() << std::endl;
    //     return false;
    // }

    int16_t *val_data_read = new int16_t[NUM_SAMPLES_VALIDATION * 2];
    char *data_buffer = reinterpret_cast<char *>(val_data_read);
    DWORD read;
    int success;

    // read first 2 samples
    success = ReadFile(file, data_buffer, NUM_SAMPLES_VALIDATION * sizeof(int16_t), &read, NULL);
    // read last 2 samples
    SetFilePointer(file, (numel - NUM_SAMPLES_VALIDATION) * sizeof(int16_t), NULL, FILE_BEGIN);
    success = ReadFile(file, data_buffer + NUM_SAMPLES_VALIDATION * sizeof(int16_t), NUM_SAMPLES_VALIDATION * sizeof(int16_t), &read, NULL);

    if (success == FALSE)
        std::cout << "[READ ERROR] " << GetLastErrorAsString() << std::endl;
    CloseHandle(file);

    bool different = false;
    for (size_t i = 0; i < NUM_SAMPLES_VALIDATION * 2; i++)
    {
        different |= (val_data_read[i] != val_data[i]);
        _DEBUG_MSG("i\t" << i << "\t" << val_data[i] << "\t" << val_data_read[i]);
    }
    delete[] val_data_read; // clean up
    return (!different);
}