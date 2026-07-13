package.path = package.path..";../?.lua"
local mng = require("mng")


mng.start(...)
mng.xbps_mirror("https://repo-de.voidlinux.org/current")
mng.repo("void-repo-nonfree void-repo-multilib void-repo-multilib-nonfree")

mng.module("hardware", true)
mng.module("console")

local hostname = mng.hostname_get()

if hostname == "valholl" then
  mng.module("desktop")
  mng.module("gui")
  mng.module("virt")
  mng.module("apps/remote")
  mng.module("apps/autoproxy")
  mng.module("apps/arduino-cli")
elseif hostname == "gjoll" then
  mng.module("apps/arduino-cli")
end

mng.finish()
