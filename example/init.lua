package.path = package.path..";../?.lua"
local mng = require("mng")


mng.start(...)
mng.xbps_mirror("https://repo-de.voidlinux.org/current")
mng.repo("void-repo-nonfree void-repo-multilib void-repo-multilib-nonfree")

mng.module("hardware")
mng.module("console")
mng.module("desktop")
mng.module("gui")

mng.package [[
  docker docker-buildx
  virtualbox-ose virtualbox-ose-dkms
  wine wine-mono winetricks
]]
mng.service_on("docker")
mng.cmd("usermod -aG docker girvel")
-- TODO `winetricks dxvk` needs to be run once; consider --heavy flag? or --light?

mng.finish()
