local mng = require("mng")


local flatpak = {}

flatpak.on = function(user)
  mng.package("flatpak")
  mng.as_user(user, function()
    mng.cmd("flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo")
  end)
end

flatpak.package = function(packages)
  for _, pkg in ipairs(mng.tokenize(packages)) do
    if not flatpak.package_is_installed(pkg) then
      flatpak.package_install(pkg)
    end
  end
end

flatpak.package_is_installed = function(pkg)
  return mng.cmd_read("flatpak list"):find(pkg, 1, true)
end

flatpak.package_install = function(pkg)
  mng.cmd("flatpak install -y flathub %s", pkg)
end

return flatpak
