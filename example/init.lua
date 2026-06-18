package.path = package.path..";../?.lua"
local mng = require("mng")


mng.start(...)
mng.xbps_mirror("https://repo-de.voidlinux.org/current")

mng.module("hardware")
mng.module("desktop")

mng.package [[
  fuse mesa-dri man-pages-devel telegram-desktop transmission-gtk clang cmake
  zsh git stow curl wget neovim tree-sitter-cli ripgrep eza github-cli love htop tree jq redsocks
  ghostty firefox obs kdenlive audacity ttf-ubuntu-font-family dejavu-fonts-ttf zip unzip
  socklog-void chrony fzf vlc ffmpeg
]]

mng.service_on("redsocks", "socklog-unix", "nanoklogd", "chronyd")

mng.file("/etc/sysctl.d/20-quiet-console.conf", "kernel.printk = 3 4 1 3\n")  -- stop TTY spam

local ldtk = "/usr/local/bin/ldtk"
if not mng.file_exists(ldtk) then
  mng.cmd("wget https://github.com/deepnight/ldtk/releases/download/v1.5.3/ubuntu-distribution.zip -O/tmp/ldtk.zip")
  mng.cmd("unzip /tmp/ldtk.zip")
  mng.cmd("mv LDtk*.AppImage %s", ldtk)
  mng.cmd("chmod +x %s", ldtk)
end
mng.desktop_file("./assets/ldtk.desktop")
mng.icon("./assets/ldtk.png")

if mng.dir_exists("/opt/aseprite") then
  mng.symlink("/usr/local/bin/aseprite", "/opt/aseprite/aseprite")
else
  print("[WARN] /opt/aseprite is missing (build it from source)")
end
mng.desktop_file("./assets/aseprite.desktop")
mng.icon("./assets/aseprite.png")

local _, exit_code = mng.cmd_read("ls /usr/share/fonts/JetBrainsMono* 2>/dev/null")
if exit_code ~= 0 then
  mng.cmd("rm -rf /tmp/jbmono.zip")
  mng.cmd("wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip -O /tmp/jbmono.zip")
  mng.cmd("rm -rf /tmp/jbmono")
  mng.dir("/tmp/jbmono")
  mng.cmd("unzip /tmp/jbmono.zip -d /tmp/jbmono")
  mng.cmd("mv /tmp/jbmono/JetBrainsMono* /usr/share/fonts/")
end

mng.as_user("girvel", function()
  mng.shell("/usr/bin/zsh")
  if not mng.dir_exists("~/.oh-my-zsh") then
    mng.cmd [[
      sh -c \
        "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    ]]
  end
  mng.dir("~/workshop")
  mng.git_repo("https://github.com/girvel/dotfiles", "~/dotfiles", true)
  mng.symlink("~/workshop/dotfiles", "~/dotfiles")
  mng.manual_stow("~/dotfiles", "~", {
    ".config/alacritty",
    ".config/nvim",
    ".config/zsh",
    ".local/bin/cb",
    ".mozilla/firefox/girvel/chrome",
    ".mozilla/firefox/girvel/user.js",
    ".gitconfig",
  })
  mng.symlink("~/.zshrc", "./assets/.zshrc")
  mng.symlink("~/.config/ghostty/config", "./assets/ghostty_config")

  mng.git_repo("https://github.com/girvel/autoproxy", "~/workshop/autoproxy")
  mng.as_user(nil, function()
    mng.symlink("/etc/redsocks.conf", "~/workshop/autoproxy/redsocks.conf")
  end)
  mng.desktop_file("./assets/autoproxy_1")
  mng.desktop_file("./assets/autoproxy_2")
end)

mng.finish()
