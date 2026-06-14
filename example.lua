local mng = require("mng")
local gnome = require("mng.gnome")


--- @diagnostic disable-next-line:unused-function
local use_gnome = function()
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
end

local use_niri = function()
  mng.package(
    "dbus elogind niri fuzzel Waybar wl-clipboard pipewire wireplumber font-awesome pavucontrol"
    .." alsa-utils xclip xwayland-satellite"
  )
  mng.service_on("dbus", "elogind")  -- TODO unify syntax with mng.package
  mng.as_user("girvel", function()
    mng.symlink("~/.config/niri/config.kdl", "./example/assets/niri_config.kdl")
    mng.symlink("~/.config/waybar/config.jsonc", "./example/assets/waybar_config.jsonc")
    mng.symlink("~/.config/waybar/style.css", "./example/assets/waybar_style.css")
  end)
end

mng.start(...)

local hostname = mng.hostname_get()
if hostname == "sovngard1" then
  mng.package("mesa-dri virtualbox-ose-guest virtualbox-ose-guest virtualbox-ose-guest-dkms")
  mng.service_on("vboxservice")
elseif hostname == "valholl" then
  mng.package("void-repo-nonfree")
  mng.package("nvidia")
else
  error("No machine-specific configuration for "..hostname)
end

if hostname ~= "sovngard1" then
  mng.package("keyd")
  mng.dir("/etc/keyd")
  mng.symlink("/etc/keyd/remap.conf", "./example/assets/remap.conf")
  mng.service_on("keyd")
end

mng.package [[
  xdg-utils fuse
  zsh git stow curl wget neovim ripgrep eza github-cli love htop tree jq redsocks
  ghostty firefox vlc obs kdenlive audacity ttf-ubuntu-font-family dejavu-fonts-ttf
]]

-- use_gnome()
use_niri()

mng.service_on("redsocks")

local ldtk = "/usr/local/bin/ldtk"
if not mng.file_exists(ldtk) then
  mng.cmd("wget https://github.com/deepnight/ldtk/releases/download/v1.5.3/ubuntu-distribution.zip -O/tmp/ldtk.zip")
  mng.cmd("unzip /tmp/ldtk.zip")
  mng.cmd("mv LDtk*.AppImage %s", ldtk)
  mng.cmd("chmod +x %s", ldtk)
end
mng.desktop_file("./example/assets/ldtk.desktop")
mng.icon("./example/assets/ldtk.png")

mng.as_user("girvel", function()
  mng.shell("/usr/bin/zsh")
  if not mng.dir_exists("~/.oh-my-zsh") then
    mng.cmd [[
      sh -c \
        "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    ]]
  end
  mng.dir("~/workshop")
  mng.dir("~/.mozilla/firefox/girvel")
  mng.dir("~/.config")
  mng.dir("~/.local/bin")
  mng.git_repo("https://github.com/girvel/dotfiles", "~/dotfiles", true)
  mng.stow("~/dotfiles", "~")
  mng.file_set("~/.zshrc", mng.file_get("./example/assets/.zshrc"))

  mng.git_repo("https://github.com/girvel/autoproxy", "~/workshop/autoproxy")
  mng.as_user(nil, function()
    mng.symlink("/etc/redsocks.conf", "~/workshop/autoproxy/redsocks.conf")
  end)
  mng.desktop_file("./example/assets/autoproxy_1")
  mng.desktop_file("./example/assets/autoproxy_2")
end)

mng.finish()
