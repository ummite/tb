/*
  Minimal POSIX-compatible getopt/getopt_long for MSVC.
  Build shim for the 2018 tbgenp.c experiment (2026-09-14).
  Implements GNU-style permutation: non-options are rotated to the
  end so options may appear after positional arguments.
*/
#include "getopt.h"

#include <stdio.h>
#include <string.h>

int optind = 1;
int optopt;
char *optarg;

static char *nextchar;  /* next char inside current short option, or NULL */
static int zone_start;  /* first index of the permuted trailing non-options */

enum { ADV_EOF, ADV_SHORT, ADV_LONG };

static int move_nonopt(char *argv[], int i)
{
  char *tmp = argv[i];
  int j;
  for (j = i; j + 1 < zone_start; j++)
    argv[j] = argv[j + 1];
  argv[zone_start - 1] = tmp;
  zone_start--;
  return i + 1;
}

/* Scan for the next option.
   Returns ADV_EOF, ADV_SHORT (c = option char) or
   ADV_LONG (c = option val, lopt = matched entry, value = "=arg" or NULL). */
static int advance(char *argv[], int argc, const struct option *longopts,
                   int *c, const struct option **lopt, char **value)
{
  for (;;) {
    if (nextchar == NULL) {
      char *a;
      if (optind >= argc || optind >= zone_start) {
        optind = (zone_start < argc) ? zone_start : argc;
        return ADV_EOF;
      }
      a = argv[optind];
      if (a[0] == '-' && a[1] == '-' && a[2] == '\0') {
        optind++;
        zone_start = optind;
        optind = (zone_start < argc) ? zone_start : argc;
        return ADV_EOF;
      }
      if (a[0] != '-') {
        optind = move_nonopt(argv, optind);
        continue;
      }
      if (a[1] == '-') {
        const char *name = a + 2;
        const char *eq;
        if (longopts == NULL) {
          optind++;
          nextchar = NULL;
          return ADV_EOF;
        }
        eq = strchr(name, '=');
        {
          size_t len = eq ? (size_t)(eq - name) : strlen(name);
          int i;
          for (i = 0; longopts[i].name != NULL; i++) {
            if (strlen(longopts[i].name) == len &&
                strncmp(longopts[i].name, name, len) == 0) {
              optind++;
              nextchar = NULL;
              *c = longopts[i].val;
              *lopt = &longopts[i];
              *value = eq ? (char *)(eq + 1) : NULL;
              return ADV_LONG;
            }
          }
        }
        fprintf(stderr, "getopt: unrecognized option '--%s'\n", name);
        optind++;
        nextchar = NULL;
        *c = '?';
        *lopt = NULL;
        *value = NULL;
        return ADV_LONG;
      }
      nextchar = a + 1;
    }
    *c = (int)(unsigned char)*nextchar;
    if (nextchar[1] == '\0') {
      optind++;
      nextchar = NULL;
    } else {
      nextchar++;
    }
    *lopt = NULL;
    *value = NULL;
    return ADV_SHORT;
  }
}

static int do_short(int c, char *argv[], int argc, const char *optstring)
{
  const char *p = strchr(optstring, (char)c);
  if (p == NULL || c == ':') {
    fprintf(stderr, "getopt: unrecognized option '-%c'\n", c);
    optopt = c;
    return '?';
  }
  if (p[1] == ':') {
    if (nextchar != NULL) {
      optarg = nextchar;
      optind++;
      nextchar = NULL;
    } else {
      optind++;
      if (optind >= argc) {
        fprintf(stderr, "getopt: option requires an argument -- '%c'\n", c);
        optopt = c;
        return ':';
      }
      optarg = argv[optind++];
    }
  } else {
    if (nextchar != NULL) {
      optind++;
      nextchar = NULL;
    }
    optarg = NULL;
  }
  return c;
}

int getopt(int argc, char *argv[], const char *optstring)
{
  int c;
  const struct option *lopt = NULL;
  char *value = NULL;
  int r = advance(argv, argc, NULL, &c, &lopt, &value);
  if (r == ADV_EOF)
    return EOF;
  if (r == ADV_LONG)
    return '?';
  return do_short(c, argv, argc, optstring);
}

int getopt_long(int argc, char *argv[], const char *optstring,
                const struct option *longopts, int *longindex)
{
  int c;
  const struct option *lopt = NULL;
  char *value = NULL;
  int r = advance(argv, argc, longopts, &c, &lopt, &value);
  if (longindex)
    *longindex = (r == ADV_LONG && lopt != NULL)
                     ? (int)(lopt - longopts)
                     : -1;
  if (r == ADV_EOF)
    return EOF;
  if (r == ADV_LONG) {
    if (lopt == NULL)
      return '?';
    if (lopt->has_arg == required_argument) {
      if (value != NULL) {
        optarg = value;
      } else {
        optind++;
        if (optind >= argc) {
          fprintf(stderr, "getopt: option --%s requires an argument\n",
                  lopt->name);
          return '?';
        }
        optarg = argv[optind++];
      }
    } else if (lopt->has_arg == optional_argument) {
      optarg = value;
    } else {
      optarg = NULL;
    }
    if (lopt->flag != NULL) {
      *lopt->flag = 1;
      return lopt->val;
    }
    return lopt->val;
  }
  return do_short(c, argv, argc, optstring);
}
