local mng = require("mng")

if mng.package("arduino-cli") then
  pcall(mng.cmd, "sudo usermod -aG dialout girvel")
  mng.as_user("girvel", function()
    mng.cmd("arduino-cli config init")
  end)
end
