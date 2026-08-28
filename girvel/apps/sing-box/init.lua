local mng = require("mng")

mng.package("sing-box")
mng.symlink("/etc/sing-box/config.json", "./apps/sing-box/config.json")
mng.service_on("sing-box")
