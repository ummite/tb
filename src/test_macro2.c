/* Test if _MSC_VER is defined and macros work */

#ifdef _MSC_VER
#define MSC_VER_VALUE _MSC_VER
#else
#define MSC_VER_VALUE 0
#endif

/* Test the MARK_PIVOT0_1_ARG macro */
#ifdef _MSC_VER
#define MARK_PIVOT0_1_ARG(func, type, name) \
static void func##_pivot0(uint8_t *table, uint64_t idx, bitboard occ, int *p, type name)

#define DEBUG_MSC_VER_DEFINED 1
#else
#define MARK_PIVOT0(func, ...) \
static void func##_pivot0(uint8_t *table, uint64_t idx, bitboard occ, int *p, ##__VA_ARGS__)

#define DEBUG_MSC_VER_DEFINED 0
#endif

#include <stdio.h>
#include <stdint.h>

typedef uint64_t bitboard;

/* Test the macro */
MARK_PIVOT0_1_ARG(test_func, uint8_t, v)
{
    printf("Test function called with v=%d\n", v);
}

int main(void) {
    printf("_MSC_VER is %d\n", MSC_VER_VALUE);
    printf("DEBUG_MSC_VER_DEFINED is %d\n", DEBUG_MSC_VER_DEFINED);
    return 0;
}
