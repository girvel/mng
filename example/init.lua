package.path = package.path..";../?.lua"
local mng = require("mng")


mng.start(...)
mng.xbps_mirror("https://repo-de.voidlinux.org/current")
mng.repo("void-repo-nonfree void-repo-multilib void-repo-multilib-nonfree")

mng.module("hardware", true)

local hostname = mng.hostname_get()
mng.module("console")
if hostname ~= "gjoll" then
  mng.module("desktop")
  mng.module("gui")
  mng.module("virt")
end

mng.finish()
