#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>

#define MNG_IMPLEMENTATION
#include "mng.h"

// Concept: mng.h is a single-header library
// I'm not sure where would configuration files go/who would run them, but for now we'll test in
// mng.c

int
main()
{
    mng_ensure_installed("fish-shell");
    return 0;
}
