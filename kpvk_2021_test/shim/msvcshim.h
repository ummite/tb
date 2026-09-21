#ifndef MSVC_BUILTIN_SHIM_H
#define MSVC_BUILTIN_SHIM_H
/*
  GCC-builtin shims for MSVC.
  Build shim for the 2018 tbgenp.c experiment (2026-09-14).
  Force-included with /FI; no effect on non-MSVC builds.
*/
#if defined(_MSC_VER)

#include <intrin.h>

#ifndef __attribute__
#define __attribute__(x)
#endif
#ifndef __builtin_expect
#define __builtin_expect(x, v) (x)
#endif
#ifndef __builtin_prefetch
#define __builtin_prefetch(p, r, l) ((void)0)
#endif
#ifndef __builtin_unreachable
#define __builtin_unreachable() __assume(0)
#endif
#ifndef __builtin_bswap16
#define __builtin_bswap16(x) _byteswap_ushort((unsigned short)(x))
#endif
#ifndef __builtin_bswap32
#define __builtin_bswap32(x) _byteswap_ulong((unsigned long)(x))
#endif
#ifndef __builtin_bswap64
#define __builtin_bswap64(x) _byteswap_uint64(x)
#endif
#ifndef __builtin_clzll
#define __builtin_clzll(x) __lzcnt64(x)
#endif
#ifndef __builtin_ctzll
#define __builtin_ctzll(x) __tzcnt64(x)
#endif
#ifndef __builtin_clz
#define __builtin_clz(x) __lzcnt((unsigned int)(x))
#endif
#ifndef __builtin_ctz
#define __builtin_ctz(x) __tzcnt((unsigned int)(x))
#endif

#endif /* _MSC_VER */
#endif /* MSVC_BUILTIN_SHIM_H */
