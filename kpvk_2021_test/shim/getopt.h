/*
  Minimal POSIX-compatible getopt/getopt_long for MSVC.
  Build shim for the 2018 tbgenp.c experiment (2026-09-14).
  GNU-style permutation of non-options is implemented.
*/
#ifndef SHIM_GETOPT_H
#define SHIM_GETOPT_H

#ifdef __cplusplus
extern "C" {
#endif

extern int optind;
extern int optopt;
extern char *optarg;

struct option {
  const char *name;
  int has_arg;
  int *flag;
  int val;
};

#define no_argument 0
#define required_argument 1
#define optional_argument 2

int getopt(int argc, char *argv[], const char *optstring);
int getopt_long(int argc, char *argv[], const char *optstring,
                const struct option *longopts, int *longindex);

#ifdef __cplusplus
}
#endif

#endif /* SHIM_GETOPT_H */
