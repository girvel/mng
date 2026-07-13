local mng = require("mng")


mng.as_user("girvel", function()
  if not mng.git_repo("~/workshop/remote", "github.com/girvel/remote", true) then return end

  mng.dir_in("~/workshop/remote", function()
    mng.cmd("pwd")
    if not mng.file_exists("nob") then
      mng.cmd("cc nob.c -o nob")
    end
    mng.cmd("./nob")
  end)
end)

mng.symlink("/etc/sv/remote/run", "./apps/remote/run")
mng.symlink("/etc/sv/remote/log/run", "./apps/remote/log_run")
mng.service_on("remote")
