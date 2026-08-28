local mng = require("mng")


mng.package [[
  mesa-dri vulkan-loader ttf-ubuntu-font-family dejavu-fonts-ttf
  telegram-desktop transmission-gtk love ImageMagick ghostty firefox
  obs kdenlive audacity mpv ffmpeg qt5-wayland libreoffice
]]

local ldtk = "/usr/local/bin/ldtk"
if not mng.file_exists(ldtk) then
  mng.cmd("wget https://github.com/deepnight/ldtk/releases/download/v1.5.3/ubuntu-distribution.zip -O/tmp/ldtk.zip")
  mng.cmd("unzip /tmp/ldtk.zip")
  mng.cmd("mv LDtk*.AppImage %s", ldtk)
  mng.cmd("chmod +x %s", ldtk)
end
mng.desktop_file("./gui/ldtk.desktop")
mng.icon("./gui/ldtk.png")

if mng.dir_exists("/opt/aseprite") then
  mng.symlink("/usr/local/bin/aseprite", "/opt/aseprite/aseprite")
else
  print("[WARN] /opt/aseprite is missing (build it from source)")
end
mng.desktop_file("./gui/aseprite.desktop")
mng.icon("./gui/aseprite.png")

mng.as_user("girvel", function()
  mng.symlink("~/.config/ghostty/config", "./gui/ghostty_config")
end)

