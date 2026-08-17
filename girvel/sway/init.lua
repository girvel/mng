local mng = require("mng")

mng.package [[
  dbus elogind polkit
  sway xwayland-satellite
  pipewire wireplumber alsa-utils pavucontrol
  fuzzel wl-clipboard wl-clip-persist
  ttf-ubuntu-font-family dejavu-fonts-ttf
  zramen
]]

mng.service_on("dbus", "polkitd", "zramen")

mng.as_user("girvel", function()
  mng.symlink("~/.config/sway/config", "./sway/config")
end)
