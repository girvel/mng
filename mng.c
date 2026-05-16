#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>

#define MNG_IMPLEMENTATION
#include "mng.h"

int
main()
{
    mng_ensure_installed("fish-shell");
    mng_set_shell("/usr/bin/zsh");
    return 0;
}
