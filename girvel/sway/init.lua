local mng = require("mng")

mng.package [[
  dbus elogind polkit
  sway
  pipewire wireplumber alsa-utils pavucontrol
  fuzzel wl-clipboard
  ttf-ubuntu-font-family dejavu-fonts-ttf
]]

mng.service_on("dbus", "polkitd")

mng.as_user("girvel", function()
  mng.symlink("~/.config/sway/config", "./sway/config")
end)
