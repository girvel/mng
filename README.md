[API](docs/)

# mng

> [!WARNING]
> It's a rough sketch of the idea, not a stable product

**The point:** Portable OS configuration in one folder, like NixOS but not weird

You describe in Lua script how you want your system to be and run it. You need to change something -- edit and rerun your script. A single library, implementation kept simple and obvious for ease of use.

## The rationale

Basically I tried NixOS, I liked the idea of having all configuration in one place, so you can see the whole setup at once & switch machines if needed. I did not like the following things:

- A weird functional language for configuration, and not even a mainstream one
- Weird sandboxing => a lot of linux things are broken
- It is really hard to fix and understand things, it's not normal linux, most linux admin skills go out the window

They are trade-offs that are used to achieve perfect reproducibility; my idea is that I don't really need it to be perfect, I don't switch machines that often, but I would rather the system itself would be a normal comfortable linux. So, my solution is:

- Instead of weird functional language, you describe everything you need in Lua (the style is called Immediate Mode, inspired by my recent work with game UIs)
- It's not a separate OS, it's just a decent linux distribution (Void Linux) + a library
- You have a single file (or you can split it into multiple if you want) that describes all the important system configuration
- There is no magic, everything is very straightforward, you just ask like "please make sure these packages are installed, these configuration files are set and my shell is zsh" and mng does it

## Show me the code

The most basic example would be:

```lua
local mng = require("mng")

mng.start(...)
  mng.package("neovim git zsh")  -- make sure your favourite xbps packages are installed
  mng.as_user("girvel", function()  -- set up your user
    mng.shell("/usr/bin/zsh")  -- ensure the shell is zsh
    mng.file_set("~/.zshrc", 'export EDITOR="nvim"')  -- ensure zsh configuration
  end)
mng.stop()
```

## I want to try examples

Fair warning: this is a prototype, the installation can be rough: you may need to reboot, and oh-my-zsh launches zsh in the middle of installation, so the first time you need to manually exit it.

- A simple example: my Ubuntu configuration recreated as GNOME + customizations, folder is `examples/gnome`
- A complex example: my real current setup of two machines: PC with Niri as a compositor and an old laptop with no graphics, folder is `girvel`

To launch an example, you need to:

1. Have a fresh void linux installation on Virtualbox 
2. Install git & LuaJIT
3. Set the hostname to sovgnard1
4. Clone this repo
5. Go to the folder of the example you want to run
6. Run `sudo luajit init.lua`
7. You may need to reboot the system & rerun the script if something failed to install

## Installation & usage

1. Install LuaJIT
2. Copy the `mng.lua` and `mng/` into /usr/local/share/lua/5.1/
3. Start writing your script, put it wherever you like
4. Don't forget to do `mng.start(...)` at the start of the script and `mng.stop()` at the end

## Documentation

See [docs/](docs/)

## On AI

Not a single line of code was written using AI; it was, however, used in research and review.
