local flatpak = require("mng.flatpak")
local mng = require("mng")


mng.package [[
  mesa-dri vulkan-loader ttf-ubuntu-font-family dejavu-fonts-ttf
  telegram-desktop transmission-gtk love redsocks ghostty firefox
  obs kdenlive audacity vlc ffmpeg qt5-wayland libreoffice
]]
flatpak.on("girvel")

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
  mng.symlink("~/.config/ghostty/config", "./gui/ghostty_config")

  flatpak.package("com.google.Chrome")
  mng.git_repo("github.com/girvel/autoproxy", "~/workshop/autoproxy")
  mng.desktop_file("~/workshop/autoproxy/autoproxy_1.desktop")
  mng.desktop_file("~/workshop/autoproxy/autoproxy_2.desktop")
end)

mng.symlink("/etc/redsocks.conf", "~/workshop/autoproxy/redsocks.conf")
-- TODO check before doing, do something like mng.group and mng.group_user
pcall(mng.cmd, "groupadd -r redsocks")
pcall(mng.cmd, "useradd -r -g redsocks -s /bin/false -d /var/empty redsocks")

