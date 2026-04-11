/*
  Windows compatibility functions
*/

#include <string.h>
#include "wincompat.h"

char *optarg = NULL;
int optind = 1;
int opterr = 1;
int optopt = 0;

int _getopt(int argc, char *argv[], const char *optstring)
{
  static int optpos = 1;
  char *cp;

  if (optpos == 1) {
    optind = 1;
  }

  if (optind >= argc || argv[optind][0] != '-') {
    return -1;
  }

  if (strcmp(argv[optind], "--") == 0) {
    optind++;
    return -1;
  }

  if (strcmp(argv[optind], "-") == 0) {
    return -1;
  }

  optarg = NULL;

  if (optpos == 0 || optpos >= (int)strlen(argv[optind])) {
    optpos = 1;
  }

  optopt = argv[optind][optpos];
  cp = strchr(optstring, optopt);

  if (cp == NULL || optopt == ':') {
    if (opterr) {
      fprintf(stderr, "getopt: illegal option -- %c\n", optopt);
    }
    optpos = 0;
    optind++;
    return '?';
  }

  if (cp[1] == ':') {
    if (optpos + 1 < (int)strlen(argv[optind])) {
      optarg = argv[optind] + optpos + 1;
    } else if (optind + 1 < argc) {
      optarg = argv[++optind];
    } else {
      if (opterr) {
        fprintf(stderr, "getopt: option requires an argument -- %c\n", optopt);
      }
      optopt = ':';
      return optopt;
    }
  }

  optpos = 0;
  optind++;

  return optopt;
}

/* getopt_long implementation */
int getopt_long(int argc, char *argv[], const char *optstring,
                const struct option *longopts, int *longindex)
{
  int i, j;
  int opt;

  if (longindex) {
    *longindex = -1;
  }

  /* Check for long options */
  if (optind < argc && strcmp(argv[optind], "--") == 0) {
    optind++;
    return -1;
  }

  if (optind < argc && argv[optind][0] == '-' && argv[optind][1] == '-') {
    /* Long option */
    const char *optname = argv[optind] + 2;
    char *arg = NULL;

    /* Check for = separator */
    char *eq = strchr(optname, '=');
    if (eq) {
      *eq = '\0';
      arg = eq + 1;
    }

    for (i = 0; longopts[i].name != NULL; i++) {
      if (strcmp(optname, longopts[i].name) == 0) {
        if (longindex) {
          *longindex = i;
        }

        if (longopts[i].has_arg == required_argument ||
            longopts[i].has_arg == optional_argument) {
          if (arg == NULL && optind + 1 < argc) {
            arg = argv[++optind];
          }
          if (longopts[i].has_arg == required_argument && arg == NULL) {
            if (opterr) {
              fprintf(stderr, "getopt_long: option --%s requires an argument\n",
                      longopts[i].name);
            }
            return ':';
          }
          optarg = arg;
        } else {
          optarg = NULL;
        }

        if (longopts[i].flag != NULL) {
          *longopts[i].flag = longopts[i].val;
          return 0;
        }
        return longopts[i].val;
      }
    }

    /* Short option prefix */
    if (optname[0] == '-' && optname[1] == '\0') {
      optind++;
      return -1;
    }

    if (opterr) {
      fprintf(stderr, "getopt_long: unrecognized option --%s\n", optname);
    }
    optind++;
    return '?';
  }

  /* Fall back to getopt for short options */
  opt = getopt(argc, argv, optstring);

  /* Check if it matches a long option with single character val */
  if (longindex && opt != -1 && opt != '?') {
    for (i = 0; longopts[i].name != NULL; i++) {
      if (longopts[i].val == opt) {
        *longindex = i;
        break;
      }
    }
  }

  return opt;
}
