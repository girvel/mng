local gnome = require("mng.gnome")
local mng = require("mng")


mng.package [[
  dbus elogind niri fuzzel Waybar wl-clipboard pipewire wireplumber font-awesome pavucontrol
  alsa-utils xclip xwayland-satellite bluez blueman libspa-bluetooth qdirstat xdg-utils
  qimgv Thunar gedit awww
]]
mng.service_on("dbus", "bluetoothd")  -- TODO unify syntax with mng.package
mng.cmd("usermod -aG bluetooth girvel")

if mng.package("xdg-user-dirs") then
  mng.as_user("girvel", function()
    mng.cmd("xdg-user-dirs-update")
  end)
end

mng.package("lua51-cjson")
mng.as_user("girvel", function()
  mng.symlink("~/.local/bin/awww-paperd", "./desktop/awww-paperd")
end)

mng.as_user("girvel", function()
  mng.symlink("~/.config/niri/config.kdl", "./desktop/niri_config.kdl")
  mng.symlink("~/.config/waybar/config.jsonc", "./desktop/waybar_config.jsonc")
  mng.symlink("~/.config/waybar/style.css", "./desktop/waybar_style.css")
  mng.symlink("~/.config/pulse/client.conf", "./desktop/pulse_config_client.conf")
  mng.symlink("~/.config/xdg-terminals.list", "xdg-terminals.list")
  mng.symlink("~/.config/mimeapps.list", "./desktop/mimeapps.list")
  mng.file("~/.config/xfce4/helpers.rc", "TerminalEmulator=ghostty")

  mng.symlink("~/.local/share/icons/Vimix", "./desktop/Vimix")
  mng.symlink("~/Pictures/wallpapers", "./desktop/wallpapers")
  gnome.gsettings("org.blueman.general", "plugin-list", "['!AutoConnect', '!ConnectionNotifier']")
end)
