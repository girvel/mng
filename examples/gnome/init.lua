package.path = package.path..";../../?.lua"
local mng = require("mng")
local gnome = require("mng.gnome")


mng.start(...)

-- MACHINE-SPECIFIC CONFIGURATION --

local hostname = mng.hostname_get()
if hostname == "sovngard1" then
  mng.xbps_mirror("https://repo-de.voidlinux.org/current")
  mng.package("mesa-dri virtualbox-ose-guest virtualbox-ose-guest virtualbox-ose-guest-dkms")
  mng.service_on("vboxservice")
elseif hostname == "valholl" then
  mng.xbps_mirror("https://repo-de.voidlinux.org/current")
  mng.package("void-repo-nonfree")
  mng.package("nvidia")
else
  error("No machine-specific configuration for "..hostname)
end

if hostname ~= "sovngard1" then
  mng.package("keyd")
  mng.dir("/etc/keyd")
  mng.symlink("/etc/keyd/remap.conf", "./remap.conf")
  mng.service_on("keyd")
end

-- GENERAL CONFIGURATION --

mng.package [[
  xdg-utils fuse
  zsh git stow curl wget neovim ripgrep eza github-cli love htop tree jq
  ghostty firefox vlc obs kdenlive audacity
]]

mng.as_user("girvel", function()
  mng.shell("/usr/bin/zsh")
  if not mng.dir_exists("~/.oh-my-zsh") then
    mng.cmd [[
      sh -c \
        "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    ]]
  end

  mng.git_repo("https://github.com/girvel/dotfiles", "~/dotfiles", true)
  mng.manual_stow("~/dotfiles", "~", {
    ".config/alacritty",
    ".config/nvim",
    ".config/zsh",
    ".local/bin/cb",
    ".mozilla/firefox/girvel/chrome",
    ".mozilla/firefox/girvel/user.js",
    ".gitconfig",
  })
  mng.symlink("~/.zshrc", "./.zshrc")
end)

-- GNOME --

gnome.on()

mng.as_user("girvel", function()
  gnome.gsettings("org.gnome.desktop.interface", "clock-show-weekday", "true")
  gnome.gsettings("org.gnome.desktop.interface", "color-scheme", "'prefer-dark'")
  gnome.gsettings("org.gnome.shell.keybindings", "show-screenshot-ui", "['<Super><Shift>s']")
  gnome.shortcut("custom0", "Open Ghostty", "ghostty", "<Ctrl><Alt>t")

  gnome.extension("dash-to-dock@micxgx.gmail.com")
    :gsettings("dock-position", "'LEFT'")
    :gsettings("extend-height", "true")
    :gsettings("dock-fixed", "true")
    :gsettings("dash-max-icon-size", "40")
    :gsettings("custom-theme-shrink", "true")
    :gsettings("custom-background-color", "true")
    :gsettings("background-color", "'#111111'")
    :gsettings("transparency-mode", "'FIXED'")
    :gsettings("background-opacity", "0.9")

  gnome.gsettings(
    "org.gnome.shell", "favorite-apps",
    "['firefox.desktop', 'autoproxy_1.desktop', 'com.mitchellh.ghostty.desktop', 'ldtk.desktop', 'audacity.desktop', 'telegram.desktop', 'com.obsproject.Studio.desktop', 'org.kde.kdenlive.desktop']"
  )
end)

mng.finish()
