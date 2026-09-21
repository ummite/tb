/*
  Minimal unistd.h shim for MSVC (open/close/unlink -> CRT aliases).
  Build shim for the 2018 tbgenp.c experiment (2026-09-14).
*/
#ifndef SHIM_UNISTD_H
#define SHIM_UNISTD_H

#include <io.h>

#ifndef open
#define open _open
#endif
#ifndef close
#define close _close
#endif
#ifndef unlink
#define unlink _unlink
#endif

#endif /* SHIM_UNISTD_H */
