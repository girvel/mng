package.path = package.path..";../?.lua"
local mng = require("mng")


mng.start(...)
mng.xbps_mirror("https://repo-de.voidlinux.org/current")

mng.module("hardware")
mng.module("console")
mng.module("desktop")
mng.module("gui")

mng.finish()
