#ifdef _MSC_VER
#define _MSC_VER_DEFINED
#endif

#ifdef _MSC_VER_DEFINED
#define _MSC_VER_IS_DEFINED 1
#else
#define _MSC_VER_IS_DEFINED 0
#endif

#define TEST_MACRO(x) x * 2

#include <stdio.h>

int main() {
    printf("_MSC_VER defined: %d\n", _MSC_VER_IS_DEFINED);
    printf("_MSC_VER value: %d\n", _MSC_VER);
    printf("TEST_MACRO(5) = %d\n", TEST_MACRO(5));
    return 0;
}
