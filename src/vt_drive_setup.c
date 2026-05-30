/*
  Small interactive tool: vt_drive_setup.exe

  Purpose:
  - Detect local fixed + network drives.
  - Run quick benchmarks.
  - Show available RAM.
  - Let the user choose:
      * How much RAM to use as cache (with smart suggestion)
      * Which drives to use for swap files (multi-select supported)
  - Output a ready-to-use configuration snippet.

  Compile with Visual Studio 2026 (C11 mode).
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#include "vt_drive_utils.h"

int main(void)
{
    printf("=== Syzygy Virtual Table - Drive & Cache Setup ===\n\n");

    RamInfo ram;
    if (!vt_get_ram_info(&ram)) {
        fprintf(stderr, "Failed to query RAM information.\n");
        return 1;
    }

    double total_gb = ram.total_physical / (1024.0 * 1024 * 1024);
    double avail_gb = ram.available_physical / (1024.0 * 1024 * 1024);

    printf("System RAM:\n");
    printf("  Total physical   : %.1f GB\n", total_gb);
    printf("  Available        : %.1f GB\n\n", avail_gb);

    /* Smart default suggestion: leave 8-16 GB for OS + generator overhead */
    double suggested = avail_gb - 12.0;
    if (suggested < 8.0) suggested = avail_gb * 0.6;
    if (suggested > avail_gb - 4.0) suggested = avail_gb - 4.0;

    printf("Recommended cache size: %.0f GB (you have %.1f GB available)\n", suggested, avail_gb);
    printf("Enter cache size in GB (press Enter for %.0f): ", suggested);

    char line[64];
    fgets(line, sizeof(line), stdin);
    double chosen_cache = suggested;
    if (sscanf(line, "%lf", &chosen_cache) != 1) {
        chosen_cache = suggested;
    }
    if (chosen_cache > avail_gb - 2.0) chosen_cache = avail_gb - 2.0;
    if (chosen_cache < 2.0) chosen_cache = 2.0;

    printf("\nUsing %.0f GB as RAM cache.\n\n", chosen_cache);

    /* Drive enumeration + benchmarking */
    DriveList *drives = vt_enum_drives();
    if (!drives || drives->count == 0) {
        fprintf(stderr, "No drives found.\n");
        return 1;
    }

    DriveBenchmark *benches = (DriveBenchmark *)calloc(drives->count, sizeof(DriveBenchmark));

    printf("Running quick benchmarks (this will take ~10-30 seconds)...\n");
    for (int i = 0; i < drives->count; i++) {
        const DriveInfo *d = &drives->drives[i];
        printf("  Benchmarking %s ... ", d->root);
        fflush(stdout);

        /* Use ~4 GB test size for decent measurement without taking forever */
        benches[i] = vt_benchmark_drive(d->root, 4ULL * 1024 * 1024 * 1024);
        printf("done (W: %.1f MB/s  R: %.1f MB/s)\n", benches[i].write_mbs, benches[i].read_mbs);
    }

    vt_print_drive_summary(drives, benches);

    /* Let user select drives for swap */
    printf("\nSelect drives to use for swap files (comma separated, e.g. 0,2,3):\n");
    for (int i = 0; i < drives->count; i++) {
        const DriveInfo *d = &drives->drives[i];
        printf("  [%d] %s  (%.1f GB free, ~%.0f MB/s write)\n",
               i, d->root, d->free_bytes / (1024.0*1024*1024), benches[i].write_mbs);
    }

    printf("\nYour choice: ");
    fgets(line, sizeof(line), stdin);

    int selected[26];
    int sel_count = 0;
    char *tok = strtok(line, " ,\n\r");
    while (tok && sel_count < 26) {
        int idx = atoi(tok);
        if (idx >= 0 && idx < drives->count) {
            selected[sel_count++] = idx;
        }
        tok = strtok(NULL, " ,\n\r");
    }

    if (sel_count == 0) {
        printf("No drives selected. Exiting.\n");
        free(benches);
        vt_free_drive_list(drives);
        return 0;
    }

    printf("\n=== Suggested configuration for VirtualTable ===\n\n");

    printf("VTConfig config = {\n");
    printf("    .total_size = <size of your 7pc table in bytes>,\n");
    printf("    .cache_size = %.0fULL * 1024 * 1024 * 1024,   // %.0f GB RAM cache\n", chosen_cache, chosen_cache);
    printf("    .reserve_gb = 8,\n");
    printf("    .num_backings = %d,\n", sel_count);
    printf("    .backings = (VTBackingStore[]){\n");

    for (int i = 0; i < sel_count; i++) {
        int idx = selected[i];
        const DriveInfo *d = &drives->drives[idx];
        int priority = 10 - i;  // higher = faster
        printf("        { \"%sSyzygySwap.bin\", VT_BACKING_FILE, %d, 0 },\n",
               d->root, priority);
    }

    printf("    },\n");
    printf("    .use_memory_mapping = 1,\n");
    printf("    .enable_prefetch = 1,\n");
    printf("    .page_size_shift = 20,   // 1 MB pages\n");
    printf("};\n\n");

    printf("You can copy the above into your code or generator when enabling virtual table mode.\n");
    printf("The tool will automatically use the fastest selected drives first.\n");

    free(benches);
    vt_free_drive_list(drives);

    printf("\nDone.\n");
    return 0;
}