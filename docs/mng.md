

The main module

 Contains universal functionality, s.a. essential functions, managing packages, files, services

# Essentials

Essential functions you need to know before starting

## `mng.start`

```lua
mng.start(...: string)
```

Should be called in the beginning of the configuration file

Ensures that the $USER is root, parses CLI args

- `...`: `string` — CLI args; pass `...` here

## `mng.finish`

```lua
mng.finish()
```

Should be called in the end of the configuration file

Runs finalizers, s.a. cleaning with --clean

# Core functionality

Functions representing core features of mng: managing packages, services, files

## `mng.package`

```lua
mng.package(packages: string) -> was_updated: boolean
```

Ensures that the listed packages are installed

- `packages`: `string` — space-separated list of packages

## `mng.service_on`

```lua
mng.service_on(...: string)
```

Ensures services are turned on

- `...`: `string` — service names

## `mng.service_off`

```lua
mng.service_off(...: string)
```

Ensures services are turned off

- `...`: `string` — service names

## `mng.dir`

```lua
mng.dir(path: string) -> was_updated: boolean
```

Ensures directory exists

## `mng.file`

```lua
mng.file(path: string, content: string) -> was_updated: boolean
```

Ensures exact file content

## `mng.file_sync`

```lua
mng.file_sync(target, source) -> was_updated: boolean
```

Ensure target's content matches source's

## `mng.symlink`

```lua
mng.symlink(path: string, value: string) -> was_updated: boolean
```

Ensures symlinks exists & points to the exact file

- `path`: `string` — where the symlink should be
- `value`: `string` — what the symlink should point to

## `mng.git_repo`

```lua
mng.git_repo(destination: string, url: string, update: boolean?) -> was_updated: boolean
```

Ensures there is a git repo at that path

- `destination`: `string` — path of the destination folder
- `url`: `string` — if does not start with protocol, defaults to https
- `update`: `boolean?` — whether to keep git pull-ing 

## `mng.shell`

```lua
mng.shell(path: string) -> was_updated: boolean
```

Ensures the current user's shell

- `path`: `string` — Full path to the shell

## `mng.xbps_mirror`

```lua
mng.xbps_mirror(mirror: string) -> was_updated: boolean
```

Sets the main mirror for xbps

## `mng.xbps_repo`

```lua
mng.xbps_repo(package_list: string) -> was_updated: boolean
```

Enables xbps repos

- `package_list`: `string` — space-separated list of xbps repos

## `mng.manual_stow`

```lua
mng.manual_stow(target: string, source: string, symlinks: string[]) -> was_updated: boolean
```

Does the same thing as stow command but controlled

The stow sometimes creates symlinks wrong, like symlinking ~/.config instead of ~/.config/nvim;`mng.manual_stow` accepts a list of things that need to be symlinked.

- `target`: `string` — directory to create symlinks in
- `source`: `string` — directory where would symlinks lead
- `symlinks`: `string[]` — list of files in `source` that need symlinking

## `mng.desktop_file`

```lua
mng.desktop_file(path: string) -> was_updated: boolean
```

Installs a desktop file

## `mng.icon`

```lua
mng.icon(path: string) -> was_updated: boolean
```

Installs an icon

## `mng.as_user`

```lua
mng.as_user(new_user: string?, f: fun())
```

Runs code as a given user

- `new_user`: `string?` — if nil, runs as root

## `mng.dir_in`

```lua
mng.dir_in(path: string, f: fun())
```

Runs the function f with given working directory

## `mng.module`

```lua
mng.module(folder_path: string, cannot_fail: boolean?)
```

Runs a module: a folder with init.lua

## `mng.cmd`

```lua
mng.cmd(command: string, ...: string)
```

Runs a command

Formats like a string.format; runs using shell; output goes to stdout; considers the current user

## `mng.cmd_read`

```lua
mng.cmd_read(command: string, ...) -> string, integer?
```

Runs a command silently, returns stdout and exit code

Formats like a string.format; runs using shell; considers the current user

## `mng.cmd_quote`

```lua
mng.cmd_quote(expr: string) -> string
```

Wraps the string into single quotes for shell usage, escapes inner single quotes

## `mng.hostname_get`

```lua
mng.hostname_get() -> hostname: string
```

Gets hostname from /etc/hostname

Conventionally hostname is used when you manage multiple machines and need to have separateconfigurations for them; you set different hostnames during initial installation and then use`mng.hostname_get` to differentiate machines.

## `mng.package_is_installed`

```lua
mng.package_is_installed(pkg: string) -> boolean
```

- `pkg`: `string` — A single package name

## `mng.package_install`

```lua
mng.package_install(pkg: string)
```

## `mng.shell_get`

```lua
mng.shell_get() -> string
```

## `mng.shell_set`

```lua
mng.shell_set(path: string)
```

## `mng.dir_exists`

```lua
mng.dir_exists(path: string) -> boolean
```

## `mng.file_exists`

```lua
mng.file_exists(path: string) -> boolean
```

## `mng.file_set`

```lua
mng.file_set(path: string, content: string)
```

## `mng.file_get`

```lua
mng.file_get(path: string) -> string?
```

## `mng.rm_rf`

```lua
mng.rm_rf(...: string)
```

## `mng.file_remove`

```lua
mng.file_remove(path: string)
```

## `mng.symlink_exists`

```lua
mng.symlink_exists(path: string) -> boolean
```

## `mng.symlink_get`

```lua
mng.symlink_get(path: string) -> string
```

## `mng.symlink_set`

```lua
mng.symlink_set(path: string, value: string)
```

## `mng.curl_file`

```lua
mng.curl_file(filepath, url)
```

## `mng.theme_installed`

```lua
mng.theme_installed(name, url) -> was_updated: boolean
```

@class cli_args @field clean boolean @field light boolean @field module string? @field verbose boolean @field no_sync boolean @type cli_args

@type string?