# mng

### `mng.start`

```lua
mng.start(...: string)
```

Ensures that the $USER is root, parses CLI args

#### Args
- `...`: `string` — CLI args; pass `...` here

### `mng.finish`

```lua
mng.finish()
```

Runs finalizers, s.a. cleaning with --clean

### `mng.as_user`

```lua
mng.as_user(new_user: string, f: fun())
```

Runs code as a given user

### `mng.package`

```lua
mng.package(packages: string) -> was_updated: boolean
```

Ensures that the listed packages are installed

#### Args
- `packages`: `string` — space-separated list of packages

### `mng.service_on`

```lua
mng.service_on(...: string)
```

Ensures services are turned on

#### Args
- `...`: `string` — service names

### `mng.service_off`

```lua
mng.service_off(...: string)
```

Ensures services are turned off

#### Args
- `...`: `string` — service names

### `mng.dir`

```lua
mng.dir(path: string) -> was_updated: boolean
```

Ensures directory exists

### `mng.file`

```lua
mng.file(path: string, content: string) -> was_updated: boolean
```

Ensures exact file content

### `mng.symlink`

```lua
mng.symlink(path: string, value: string) -> was_updated: boolean
```

Ensures symlinks exists & points to the exact file

#### Args
- `path`: `string` — where the symlink should be- `value`: `string` — what the symlink should point to

### `mng.shell`

```lua
mng.shell(path: string) -> was_updated: boolean
```

Ensures the current user's shell

#### Args
- `path`: `string` — Full path to the shell

### `mng.hostname_get`

```lua
mng.hostname_get() -> hostname: string
```

Gets hostname from /etc/hostname

### `mng.cmd`

```lua
mng.cmd(command: string, ...: string)
```

Formats like a string.format; runs using shell; output goes to stdout; considers the current user

### `mng.cmd_read`

```lua
mng.cmd_read(command: string, ...) -> string, integer?
```

Formats like a string.format; runs using shell; considers the current user

### `mng.cmd_quote`

```lua
mng.cmd_quote(expr)
```

### `mng.package_is_installed`

```lua
mng.package_is_installed(pkg)
```

### `mng.package_install`

```lua
mng.package_install(pkg)
```

### `mng.xbps_mirror`

```lua
mng.xbps_mirror(mirror)
```

### `mng.repo`

```lua
mng.repo(package_list)
```

### `mng.shell_get`

```lua
mng.shell_get(this_user)
```

### `mng.shell_set`

```lua
mng.shell_set(path)
```

### `mng.dir_exists`

```lua
mng.dir_exists(path)
```

### `mng.file_exists`

```lua
mng.file_exists(path)
```

### `mng.file_sync`

```lua
mng.file_sync(target, source) -> was_updated: boolean
```

Ensure target's content matches source's

### `mng.file_set`

```lua
mng.file_set(path, content)
```

### `mng.file_get`

```lua
mng.file_get(path) -> string?
```

### `mng.recursive_remove`

```lua
mng.recursive_remove(...)
```

### `mng.file_remove`

```lua
mng.file_remove(path)
```

### `mng.git_repo`

```lua
mng.git_repo(repo_path, destination, update)
```

### `mng.manual_stow`

```lua
mng.manual_stow(source, target, symlinks)
```

### `mng.stow`

```lua
mng.stow(source, target)
```

### `mng.symlink_exists`

```lua
mng.symlink_exists(path)
```

### `mng.symlink_get`

```lua
mng.symlink_get(path)
```

### `mng.symlink_set`

```lua
mng.symlink_set(path, value)
```

### `mng.desktop_file`

```lua
mng.desktop_file(path)
```

### `mng.icon`

```lua
mng.icon(path)
```

### `mng.module`

```lua
mng.module(folder_path: string, cannot_fail: boolean?)
```

### `mng.curl_file`

```lua
mng.curl_file(filepath, url)
```

### `mng.theme_installed`

```lua
mng.theme_installed(name, url) -> was_updated: boolean
```

### `mng.tokenize`

```lua
mng.tokenize(str: string) -> string[]
```