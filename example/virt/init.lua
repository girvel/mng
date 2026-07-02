local mng = require("mng")


mng.package [[
  docker docker-buildx
  virtualbox-ose virtualbox-ose-dkms
  wine wine-mono winetricks
]]
mng.service_on("docker")
mng.cmd("usermod -aG docker girvel")

if not mng.cli_args.light then
  mng.as_user("girvel", function()
    mng.cmd("winetricks dxvk")
  end)
end

