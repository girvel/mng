# So what's the idea?

## The small one

Just a library mng.lua, that allows basic package installation and configuration. Not really a big manager of packages, more like a straightforward installation script. Can:

- Make sure packages are installed
- Stow shit
- Enable services
- Change shells

```lua
local mng = require("mng")

mng.ensure_installed("zsh")
mng.chsh("/usr/bin/zsh")
mng.mkdir("~/workshop")
mng.git_clone("github.com/girvel/dotfiles", "~/workshop/dotfiles")
mng.stow("~/workshop/dotfiles")
mng.stow("/etc/mng.d/root", "/")
```

## The big one

NixOS-like configuration, but imperative instead of declarative, using the nice Lua. Not 100% reproducible, it's just normal Linux experience, but you can keep all the configuration in a git-managed project.

- The configuration file is /etc/mng.d/init.lua
- There's a command line tool, that can do like "mng build" (just reruns the script), "mng edit" (opens the script in the editor of choice and builds afterwards), "mng clean" (removes any packages besides listed in init.lua)
