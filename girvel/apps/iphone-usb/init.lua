--- Usage:
---
--- ```zsh
--- idevicepair pair
--- ifuse ~/mnt/iphone
--- ```
local mng = require("mng")


mng.package("libimobiledevice ifuse gvfs-afc gvfs-gphoto2")
mng.service_on("usbmuxd")
mng.as_user("girvel", function()
  mng.dir("~/mnt/iphone")
end)
