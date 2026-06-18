package.path = package.path..";../?.lua"
local mng = require("mng")


mng.start(...)
mng.xbps_mirror("https://repo-de.voidlinux.org/current")

mng.module("hardware")
mng.module("console")
mng.module("desktop")

mng.package [[
  mesa-dri telegram-desktop transmission-gtk love redsocks
  ghostty firefox obs kdenlive audacity ttf-ubuntu-font-family dejavu-fonts-ttf vlc ffmpeg
]]

mng.service_on("redsocks")

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
  mng.symlink("~/.config/ghostty/config", "./assets/ghostty_config")

  mng.git_repo("https://github.com/girvel/autoproxy", "~/workshop/autoproxy")
  mng.as_user(nil, function()
    mng.symlink("/etc/redsocks.conf", "~/workshop/autoproxy/redsocks.conf")
  end)
  mng.desktop_file("./assets/autoproxy_1")
  mng.desktop_file("./assets/autoproxy_2")
end)

mng.finish()
