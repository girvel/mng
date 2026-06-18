local mng = require("mng")


local hostname = mng.hostname_get()
if hostname == "sovngard1" then
  mng.package("virtualbox-ose-guest virtualbox-ose-guest virtualbox-ose-guest-dkms")
  mng.service_on("vboxservice")
elseif hostname == "valholl" then
  mng.package("void-repo-nonfree")
  mng.package("nvidia nvidia-vaapi-driver")

  -- fixes boot hangs (maybe)
  local was_drm_updated = mng.file(
    "/etc/modprobe.d/nvidia_drm.conf",
    "options nvidia_drm modeset=1 fbdev=1\n"
  )
  local was_dracut_updated = mng.file(
    "/etc/dracut.conf.d/10-early-kms.conf",
    'force_drivers+=" nvidia nvidia_modeset nvidia_uvm nvidia_drm "\n'
  )
  if was_drm_updated or was_dracut_updated then
    mng.cmd("xbps-reconfigure -a")
  end

  -- TODO mng.fstab instead?
  mng.dir("/mnt/c")  -- TODO common syntax with mng.package
  mng.dir("/mnt/d")
  mng.dir("/mnt/vault")
  mng.dir("/mnt/ubuntu")
  if mng.file_sync("/etc/fstab", "./hardware/valholl/fstab") then
    mng.cmd("mount -a")
  end
else
  error("No machine-specific configuration for "..hostname)
end

if hostname ~= "sovngard1" then
  mng.package("keyd")
  mng.dir("/etc/keyd")
  mng.service_on("keyd")
  mng.file("/etc/sv/keyd/run", "#!/bin/sh\nexec keyd 2>&1")  -- or else it crashes
  mng.symlink("/etc/keyd/remap.conf", "./hardware/remap.conf")
  mng.file("/etc/rc.conf", "HARDWARECLOCK=localtime\nTIMEZONE=Asia/Yekaterinburg")
end
