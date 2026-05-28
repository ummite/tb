/* Test file to verify _MSC_VER is defined */

#ifdef _MSC_VER
#define MSC_VER_VALUE _MSC_VER
#else
#define MSC_VER_VALUE 0
#endif

/* Test the RETRO macros */
#ifdef _MSC_VER
#define RETRO_NO_ARG(func) \
  do { int j; \
    j = 0; \
    if (pcs_opp[0] == 0) { \
      func##_pivot0(table_opp, idx & ~mask[0], occ, p); \
      j = 1; \
    } \
    for (; pcs_opp[j] >= 0; j++) { \
      int k = pcs_opp[j]; \
      func(k, table_opp, idx & ~mask[k], occ, p); \
    } \
  } while (0)

#define RETRO_1_ARG(func, arg1) \
  do { int j; \
    j = 0; \
    if (pcs_opp[0] == 0) { \
      func##_pivot1(table_opp, idx & ~mask[0], occ, p, arg1); \
      j = 1; \
    } \
    for (; pcs_opp[j] >= 0; j++) { \
      int k = pcs_opp[j]; \
      func(k, table_opp, idx & ~mask[k], occ, p, arg1); \
    } \
  } while (0)

#define RETRO(func, ...) RETRO_NO_ARG(func)

#define DEBUG_MSC_VER_DEFINED 1
#else
#define RETRO(func, ...) \
  do { int j; \
    j = 0; \
    if (pcs_opp[0] == 0) { \
      func##_pivot(table_opp, idx & ~mask[0], occ, p, ##__VA_ARGS__); \
      j = 1; \
    } \
    for (; pcs_opp[j] >= 0; j++) { \
      int k = pcs_opp[j]; \
      func(k, table_opp, idx & ~mask[k], occ, p , ##__VA_ARGS__); \
    } \
  } while (0)

#define DEBUG_MSC_VER_DEFINED 0
#endif

#include <stdio.h>

int main(void) {
    printf("_MSC_VER is %d\n", MSC_VER_VALUE);
    printf("DEBUG_MSC_VER_DEFINED is %d\n", DEBUG_MSC_VER_DEFINED);
    return 0;
}
