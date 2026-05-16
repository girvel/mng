//--------------------------------------------------------------------------------------------------
// [SECTION] API
//--------------------------------------------------------------------------------------------------

#ifndef MNG_H
#define MNG_H

// TODO don't count automatically installed packages?
// Checks if the package is installed (as a dependency or manually)
bool mng_is_installed(const char *package) __attribute__((warn_unused_result));

// Installs the package if not installed yet
void mng_ensure_installed(const char *package);

#endif // MNG_H

//--------------------------------------------------------------------------------------------------
// [SECTION] Implementation
//--------------------------------------------------------------------------------------------------

#ifdef MNG_IMPLEMENTATION

bool
mng_is_installed(const char *package)
{
    char buf[256];
    if (snprintf(buf, sizeof(buf), "xbps-query %s -p state", package) >= (int)sizeof(buf)) {
        // TODO single pretty inlined error function? Or perror?
        fprintf(stderr, "ERROR: package name `%s` is too long", package);
        exit(1);
    }

    FILE *fp = popen(buf, "r");
    if (fp == NULL) {
        perror("popen failed");
        exit(1);
    }

    bool result = false;
    if (fgets(buf, sizeof(buf), fp) != NULL) {
        const char *state = "installed";
        if (strncmp(state, buf, sizeof(state) - 1) == 0) {
            result = true;
            goto end;
        }
    }

end:
    int status = pclose(fp);
    if (status == -1) {
        perror("pclose failed");
    }
    return result;
}

void
mng_ensure_installed(const char *package)
{
    if (mng_is_installed(package)) return;
    printf("install %s\n", package);

    char buf[256];
    if (snprintf(buf, sizeof(buf), "xbps-install -S %s", package) >= (int)sizeof(buf)) {
        exit(1);
    }

    int status = system(buf);
    printf("Status: %d\n", status);
}

#endif
