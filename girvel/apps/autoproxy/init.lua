local flatpak = require("mng.flatpak")
local mng = require("mng")

mng.package("redsocks")
flatpak.on("girvel")
-- TODO check before doing, do something like mng.group and mng.group_user
pcall(mng.cmd, "groupadd -r redsocks")
pcall(mng.cmd, "useradd -r -g redsocks -s /bin/false -d /var/empty redsocks")

mng.as_user("girvel", function()
  flatpak.package("com.google.Chrome")
  if not mng.cli_args.light then
    mng.cmd("flatpak override --user --filesystem=home com.google.Chrome")
  end

  mng.git_repo("~/workshop/autoproxy", "github.com/girvel/autoproxy")
  mng.dir_in("~/workshop/autoproxy", function()
    mng.desktop_file("autoproxy_1.desktop")
    mng.desktop_file("autoproxy_2.desktop")
    mng.icon("autoproxy.png")
  end)
end)

mng.dir("/opt/autoproxy")
mng.file_sync("/opt/autoproxy/up.sh", "/home/girvel/workshop/autoproxy/up.sh")
mng.file_sync("/opt/autoproxy/down.sh", "/home/girvel/workshop/autoproxy/down.sh")
mng.file_sync("/opt/autoproxy/cgroup_add.sh", "/home/girvel/workshop/autoproxy/cgroup_add.sh")
mng.file_sync("/opt/autoproxy/redsocks.conf", "/home/girvel/workshop/autoproxy/redsocks.conf")
mng.file_sync("/etc/sudoers.d/autoproxy", "./apps/autoproxy/sudoers_autoproxy")
