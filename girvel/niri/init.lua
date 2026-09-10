local gnome = require("mng.gnome")
local mng = require("mng")


mng.package [[
  dbus elogind niri fuzzel Waybar wl-clipboard pipewire wireplumber pavucontrol alsa-pipewire
  alsa-utils xclip xwayland-satellite bluez blueman libspa-bluetooth qdirstat xdg-utils font-awesome
  qimgv Thunar thunar-archive-plugin tumbler ffmpegthumbnailer gedit awww
  xdg-desktop-portal xdg-desktop-portal-gnome xdg-desktop-portal-gtk wl-clip-persist
]]
mng.service_on("dbus", "bluetoothd")
mng.cmd("usermod -aG bluetooth girvel")

if mng.package("xdg-user-dirs") then
  mng.as_user("girvel", function()
    mng.cmd("xdg-user-dirs-update")
  end)
end

mng.package("lua51-cjson")
mng.as_user("girvel", function()
  mng.symlink("~/.local/bin/awww-paperd", "awww-paperd")
end)

-- Alsa-pipewire compatibility enabled
mng.symlink("/etc/alsa/conf.d/50-pipewire.conf",
            "/usr/share/alsa/alsa.conf.d/50-pipewire.conf")

mng.symlink("/etc/alsa/conf.d/99-pipewire-default.conf",
            "/usr/share/alsa/alsa.conf.d/99-pipewire-default.conf")

mng.file("/opt/keyd_fix/restart", "sv restart keyd", "770")
mng.file("/etc/sudoers.d/keyd_fix", "girvel ALL=(root) NOPASSWD: /opt/keyd_fix/restart")

mng.as_user("girvel", function()
  mng.symlink("~/.desktop", "./.desktop")
  mng.symlink("~/.config/niri/config.kdl", "./niri_config.kdl")
  mng.symlink("~/.config/waybar/config.jsonc", "./waybar_config.jsonc")
  mng.symlink("~/.config/waybar/style.css", "./waybar_style.css")
  mng.symlink("~/.config/fuzzel/fuzzel.ini", "./fuzzel_config.ini")
  mng.symlink("~/.config/pulse/client.conf", "./pulse_config_client.conf")
  mng.symlink("~/.config/xdg-terminals.list", "./xdg-terminals.list")
  mng.symlink("~/.local/bin/fallen_layout.sh", "./fallen_layout.sh")
  mng.symlink("~/.local/bin/power.lua", "./power.lua")
  mng.symlink("~/.config/mimeapps.list", "./mimeapps.list")
  mng.file("~/.config/xfce4/helpers.rc", "TerminalEmulator=ghostty")

  mng.symlink("~/.local/share/icons/Vimix", "Vimix")
  mng.symlink("~/Pictures/wallpapers", "wallpapers")
  gnome.gsettings("org.blueman.general", "plugin-list", "['!AutoConnect', '!ConnectionNotifier']")

  gnome.gsettings("org.gnome.desktop.interface", "color-scheme", "'prefer-dark'")
  gnome.gsettings("org.gnome.desktop.interface", "monospace-font-name", "'JetBrainsMono Nerd Font'")
  mng.theme_installed("Dark-Olympic", "https://mxrepo.com/mx/repo/pool/main/d/dark-olympic-gtk-theme/dark-olympic-gtk-theme_1.2.2.orig.tar.xz")
  mng.symlink("~/.config/gtk-3.0/settings.ini", "gtk-settings.ini")

  gnome.gsettings("org.gnome.gedit.preferences.editor", "use-default-font", "true")
  gnome.gsettings("org.gnome.gedit.preferences.editor", "tabs-size", "4")
  gnome.gsettings("org.gnome.gedit.preferences.editor", "insert-spaces", "true")
end)
