# So what's the idea?

## The small one

Just a library mng.h, that allows basic package installation and configuration. Not really a big manager of packages, more like a straightforward installation script. Can:

- Make sure packages are installed
- Stow shit
- Enable services
- Change shells

```c
#define MNG_IMPLEMENTATION
#include <mng.h>

int main() {
    mng_ensure_installed("zsh");
    return 0;
}
```

## The big one

NixOS-like configuration, but imperative instead of declarative, using a nice C. Not 100% reproducible, it's just normal Linux experience, but you can keep all the configuration in a git-managed project.

- The configuration file is /etc/mng.d/main.c
- There's a command line tool, that can do like "mng build" (just reruns the script), "mng edit" (opens the script in the editor of choice and builds afterwards), "mng clean" (removes any packages besides listed in main.c)
