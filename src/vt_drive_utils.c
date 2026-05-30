/*
  Windows implementation of drive discovery + benchmarking for VirtualTable.
*/

#ifdef _WIN32

#include "vt_drive_utils.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <windows.h>

#define BENCH_BUFFER_SIZE (64 * 1024 * 1024)  /* 64 MB buffer for speed */

DriveList *vt_enum_drives(void)
{
    DWORD drives_mask = GetLogicalDrives();
    if (drives_mask == 0) return NULL;

    DriveList *list = (DriveList *)calloc(1, sizeof(DriveList));
    if (!list) return NULL;

    list->drives = (DriveInfo *)calloc(26, sizeof(DriveInfo)); /* max 26 letters */
    if (!list->drives) {
        free(list);
        return NULL;
    }

    int idx = 0;
    for (int i = 0; i < 26; i++) {
        if (drives_mask & (1u << i)) {
            char root[4] = { 'A' + i, ':', '\\', 0 };
            UINT type = GetDriveTypeA(root);

            if (type == DRIVE_FIXED || type == DRIVE_REMOTE) {
                ULARGE_INTEGER free_bytes, total_bytes;
                if (GetDiskFreeSpaceExA(root, &free_bytes, &total_bytes, NULL)) {
                    DriveInfo *d = &list->drives[idx];
                    d->letter = 'A' + i;
                    strcpy(d->root, root);
                    d->total_bytes = total_bytes.QuadPart;
                    d->free_bytes = free_bytes.QuadPart;
                    d->is_fixed = (type == DRIVE_FIXED);
                    d->is_network = (type == DRIVE_REMOTE);
                    idx++;
                }
            }
        }
    }
    list->count = idx;
    return list;
}

void vt_free_drive_list(DriveList *list)
{
    if (list) {
        free(list->drives);
        free(list);
    }
}

int vt_get_ram_info(RamInfo *info)
{
    if (!info) return 0;

    MEMORYSTATUSEX mem = {0};
    mem.dwLength = sizeof(mem);
    if (!GlobalMemoryStatusEx(&mem)) return 0;

    info->total_physical = mem.ullTotalPhys;
    info->available_physical = mem.ullAvailPhys;
    info->total_virtual = mem.ullTotalVirtual;
    info->available_virtual = mem.ullAvailVirtual;
    return 1;
}

DriveBenchmark vt_benchmark_drive(const char *root_path, uint64_t test_size_bytes)
{
    DriveBenchmark result = {0};

    char test_file[MAX_PATH];
    snprintf(test_file, sizeof(test_file), "%s\\vt_bench_test.tmp", root_path);

    HANDLE hFile = CreateFileA(test_file, GENERIC_READ | GENERIC_WRITE,
                               0, NULL, CREATE_ALWAYS,
                               FILE_ATTRIBUTE_TEMPORARY | FILE_FLAG_NO_BUFFERING | FILE_FLAG_WRITE_THROUGH,
                               NULL);

    if (hFile == INVALID_HANDLE_VALUE) {
        /* Retry without NO_BUFFERING (some drives don't like it for large files) */
        hFile = CreateFileA(test_file, GENERIC_READ | GENERIC_WRITE,
                            0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_TEMPORARY, NULL);
        if (hFile == INVALID_HANDLE_VALUE) return result;
    }

    uint64_t buffer_size = BENCH_BUFFER_SIZE;
    char *buffer = (char *)VirtualAlloc(NULL, buffer_size, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
    if (!buffer) {
        CloseHandle(hFile);
        DeleteFileA(test_file);
        return result;
    }

    /* Fill with some pattern */
    for (size_t i = 0; i < buffer_size; i++) buffer[i] = (char)(i & 0xFF);

    LARGE_INTEGER freq, start, end;
    QueryPerformanceFrequency(&freq);

    /* Write test */
    QueryPerformanceCounter(&start);
    uint64_t written = 0;
    while (written < test_size_bytes) {
        DWORD to_write = (DWORD)min(buffer_size, test_size_bytes - written);
        DWORD written_now = 0;
        if (!WriteFile(hFile, buffer, to_write, &written_now, NULL)) break;
        written += written_now;
    }
    FlushFileBuffers(hFile);
    QueryPerformanceCounter(&end);

    double write_seconds = (double)(end.QuadPart - start.QuadPart) / freq.QuadPart;
    result.write_mbs = (written / (1024.0 * 1024.0)) / write_seconds;

    /* Read test */
    SetFilePointerEx(hFile, (LARGE_INTEGER){0}, NULL, FILE_BEGIN);
    QueryPerformanceCounter(&start);
    uint64_t read = 0;
    while (read < test_size_bytes) {
        DWORD to_read = (DWORD)min(buffer_size, test_size_bytes - read);
        DWORD read_now = 0;
        if (!ReadFile(hFile, buffer, to_read, &read_now, NULL)) break;
        read += read_now;
    }
    QueryPerformanceCounter(&end);

    double read_seconds = (double)(end.QuadPart - start.QuadPart) / freq.QuadPart;
    result.read_mbs = (read / (1024.0 * 1024.0)) / read_seconds;

    result.success = 1;

    VirtualFree(buffer, 0, MEM_RELEASE);
    CloseHandle(hFile);
    DeleteFileA(test_file);

    return result;
}

void vt_print_drive_summary(const DriveList *drives, const DriveBenchmark *benches)
{
    printf("\n=== Available drives for Syzygy swap ===\n");
    printf("%-6s %-12s %-12s %-10s %-10s\n", "Drive", "Free (GB)", "Total (GB)", "Write MB/s", "Read MB/s");
    printf("----------------------------------------------------------\n");

    for (int i = 0; i < drives->count; i++) {
        const DriveInfo *d = &drives->drives[i];
        const DriveBenchmark *b = &benches[i];

        double free_gb = d->free_bytes / (1024.0 * 1024 * 1024);
        double total_gb = d->total_bytes / (1024.0 * 1024 * 1024);

        printf("%-6s %10.1f %10.1f ", d->root, free_gb, total_gb);

        if (b->success) {
            printf("%10.1f %10.1f\n", b->write_mbs, b->read_mbs);
        } else {
            printf("%10s %10s\n", "N/A", "N/A");
        }
    }
    printf("\n");
}

#endif /* _WIN32 */