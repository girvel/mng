# mng

## Internal tools

## API

### `mng.start`

```lua
mng.start(...: string)
```

### `mng.finish`

```lua
mng.finish()
```

### `mng.cmd`

```lua
mng.cmd(command, ...)
```

### `mng.cmd_read`

```lua
mng.cmd_read(command: string, ...) -> string, integer?
```

### `mng.cmd_quote`

```lua
mng.cmd_quote(expr)
```

### `mng.package`

```lua
mng.package(packages) -> was_updated: boolean
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

### `mng.as_user`

```lua
mng.as_user(new_user, f)
```

### `mng.shell`

```lua
mng.shell(path)
```

### `mng.shell_get`

```lua
mng.shell_get(this_user)
```

### `mng.shell_set`

```lua
mng.shell_set(path)
```

### `mng.dir`

```lua
mng.dir(path: string) -> was_updated: boolean
```

### `mng.dir_exists`

```lua
mng.dir_exists(path)
```

### `mng.file_exists`

```lua
mng.file_exists(path)
```

### `mng.file`

```lua
mng.file(path, content) -> was_updated: boolean
```

Ensure exact file content

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

### `mng.hostname_get`

```lua
mng.hostname_get()
```

### `mng.symlink`

```lua
mng.symlink(path, value) -> was_updated: boolean
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

### `mng.service_on`

```lua
mng.service_on(...)
```

### `mng.service_off`

```lua
mng.service_off(...)
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