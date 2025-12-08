#include "fileIOWindows.hpp"

void writeBinFileWindows(const char *fname, int16_t *int_data, size_t numel, size_t buf_size /*= 8*/)
{
    size_t part = buf_size * 1024 * 1024;
    size_t size = numel * sizeof(int16_t);
    char *data = reinterpret_cast<char *>(int_data);

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
        return;
    }

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
}

void readBinFileWindows(const char *fname, int16_t *int_data, size_t numel)
{
    HANDLE file = CreateFileA(fname,
                              GENERIC_READ,
                              0,
                              NULL,
                              OPEN_EXISTING,
                              FILE_FLAG_SEQUENTIAL_SCAN,
                              NULL);

    if (file == INVALID_HANDLE_VALUE)
    {
        std::cout << "[READ ERROR] Invalid file: " << file << std::endl;
        std::cout << "[READ ERROR] " << GetLastErrorAsString() << std::endl;
        return;
    }

    char *data_buffer = reinterpret_cast<char *>(int_data);
    DWORD read;
    int success = ReadFile(file, data_buffer, numel * sizeof(int16_t), &read, NULL);

    if (success == FALSE || (read != numel * sizeof(int16_t)))
        std::cout << "[READ ERROR] " << GetLastErrorAsString() << std::endl;

    CloseHandle(file);
}

// Returns the last Win32 error, in string format. Returns an empty string if there is no error.
std::string GetLastErrorAsString()
{
    // Get the error message ID, if any.
    DWORD errorMessageID = ::GetLastError();
    if (errorMessageID == 0)
        return std::string(); // No error message has been recorded
    LPSTR messageBuffer = nullptr;
    // Ask Win32 to give us the string version of that message ID.
    // The parameters we pass in, tell Win32 to create the buffer that holds the message for us (because we don't yet know how long the message string will be).
    size_t size = FormatMessageA(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                                 NULL, errorMessageID, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), (LPSTR)&messageBuffer, 0, NULL);
    // Copy the error message into a std::string.
    std::string message(messageBuffer, size);
    // Free the Win32's string's buffer.
    LocalFree(messageBuffer);
    return message;
}