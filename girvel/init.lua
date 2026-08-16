package.path = package.path..";../?.lua"
local mng = require("mng")


mng.start(...)
mng.xbps_mirror("https://repo-default.voidlinux.org/current")
mng.xbps_repo("void-repo-nonfree void-repo-multilib void-repo-multilib-nonfree")

mng.module("hardware", true)
mng.module("console")

local hostname = mng.hostname_get()

if hostname == "valholl" then
  mng.module("desktop")
  mng.module("gui")
  mng.module("virt")
  mng.module("apps/jbmono")
  mng.module("apps/remote")
  mng.module("apps/autoproxy")
  mng.module("apps/arduino-cli")
  mng.module("apps/iphone-usb")
elseif hostname == "sovngard1" then
  mng.module("desktop")
  mng.module("gui")
  mng.module("apps/jbmono")
elseif hostname == "gjoll" then
  mng.module("sway")
  mng.module("apps/jbmono")
  mng.module("apps/arduino-cli")
  mng.module("apps/sing-box")
end

mng.finish()
