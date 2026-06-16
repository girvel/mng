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
  mng.package [[
    dbus elogind niri fuzzel Waybar wl-clipboard pipewire wireplumber font-awesome pavucontrol
    alsa-utils xclip xwayland-satellite bluez blueman libspa-bluetooth qdirstat
  ]]
  mng.service_on("dbus", "bluetoothd")  -- TODO unify syntax with mng.package

  if mng.package("xdg-user-dirs") then
    mng.as_user("girvel", function()
      mng.cmd("xdg-user-dirs-update")
    end)
  end

  mng.package("lua51-cjson")
  mng.as_user("girvel", function()
    mng.symlink("~/.local/bin/awww-paperd", "./example/assets/awww-paperd")
  end)

  mng.as_user("girvel", function()
    mng.symlink("~/.config/niri/config.kdl", "./example/assets/niri_config.kdl")
    mng.symlink("~/.config/waybar/config.jsonc", "./example/assets/waybar_config.jsonc")
    mng.symlink("~/.config/waybar/style.css", "./example/assets/waybar_style.css")
    mng.symlink("~/.config/pulse/client.conf", "./example/assets/pulse_config_client.conf")
    mng.symlink("~/.local/share/icons/Vimix", "./example/assets/Vimix")
    mng.symlink("~/Pictures/wallpapers", "./example/assets/wallpapers")
  end)
end

mng.start(...)

local hostname = mng.hostname_get()
if hostname == "sovngard1" then
  mng.package("virtualbox-ose-guest virtualbox-ose-guest virtualbox-ose-guest-dkms")
  mng.service_on("vboxservice")
elseif hostname == "valholl" then
  mng.package("void-repo-nonfree")
  mng.package("nvidia")
  if mng.file("/etc/modprobe.d/nvidia_drm.conf", "options nvidia_drm modeset=1\n") then
    mng.cmd("xbps-reconfigure -a")
  end
  mng.dir("/mnt/c")  -- TODO common syntax with mng.package
  mng.dir("/mnt/d")
  mng.dir("/mnt/vault")
  mng.file_sync("/etc/fstab", "./example/assets/fstab")
else
  error("No machine-specific configuration for "..hostname)
end

if hostname ~= "sovngard1" then
  mng.package("keyd")
  mng.dir("/etc/keyd")
  mng.service_on("keyd")
  mng.file("/etc/sv/keyd/run", "#!/bin/sh\nexec keyd 2>&1")  -- or else it crashes
  mng.symlink("/etc/keyd/remap.conf", "./example/assets/remap.conf")
  mng.file("/etc/rc.conf", "HARDWARECLOCK=localtime\nTIMEZONE=Asia/Yekaterinburg")
end

mng.xbps_mirror("https://repo-de.voidlinux.org/current")
mng.package [[
  xdg-utils fuse mesa-dri man-pages-devel telegram-desktop transmission
  zsh git stow curl wget neovim ripgrep eza github-cli love htop tree jq redsocks
  ghostty firefox vlc obs kdenlive audacity ttf-ubuntu-font-family dejavu-fonts-ttf zip unzip awww
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

local _, exit_code = mng.cmd_read("ls /usr/share/fonts/JetBrainsMono* 2>/dev/null")
if exit_code ~= 0 then
  mng.cmd("rm -rf /tmp/jbmono.zip")
  mng.cmd("wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip -O /tmp/jbmono.zip")
  mng.cmd("rm -rf /tmp/jbmono")
  mng.dir("/tmp/jbmono")
  mng.cmd("unzip /tmp/jbmono.zip -d /tmp/jbmono")
  mng.cmd("mv /tmp/jbmono/JetBrainsMono* /usr/share/fonts/")
end

mng.cmd("usermod -aG bluetooth girvel")
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
  mng.manual_stow("~/dotfiles", "~", {
    ".config/alacritty",
    ".config/nvim",
    ".config/zsh",
    ".local/bin/cb",
    ".mozilla/firefox/girvel/chrome",
    ".mozilla/firefox/girvel/user.js",
    ".gitconfig",
  })
  mng.symlink("~/.zshrc", "./example/assets/.zshrc")
  mng.symlink("~/.config/ghostty/config", "./example/assets/ghostty_config")

  mng.git_repo("https://github.com/girvel/autoproxy", "~/workshop/autoproxy")
  mng.as_user(nil, function()
    mng.symlink("/etc/redsocks.conf", "~/workshop/autoproxy/redsocks.conf")
  end)
  mng.desktop_file("./example/assets/autoproxy_1")
  mng.desktop_file("./example/assets/autoproxy_2")
end)

mng.finish()
