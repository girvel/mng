local mng = require("mng")
local gnome = require("mng.gnome")


if os.getenv("USER") ~= "root" then
  error("Expected $USER to be root; please run with sudo.")
end

local hostname = mng.hostname_get()
if hostname == "sovngard1" then
  mng.package(
    "mesa-dri", "virtualbox-ose-guest", "virtualbox-ose-guest", "virtualbox-ose-guest-dkms"
  )
  mng.service_on("vboxservice")
else
  error("No machine-specific configuration for "..hostname)
end

gnome.on()
mng.package(
  "zsh", "git", "stow", "curl", "neovim", "ripgrep", "eza",
  "ghostty"
)

mng.service_off("dhcpcd", "wpa_supplicant")
mng.service_on("dbus", "NetworkManager", "gdm")

mng.as_user("girvel", function()
  mng.shell("/usr/bin/zsh")
  if not mng.dir_exists("~/.oh-my-zsh") then
    mng.cmd [[
      sh -c \
        "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    ]]
  end
  mng.dir("~/workshop")
  mng.git_repo("https://github.com/girvel/dotfiles", "/home/girvel/dotfiles")
  mng.stow("/home/girvel/dotfiles", "/home/girvel")
  mng.file_set("/home/girvel/.zshrc", mng.file_get("./.zshrc"))

  gnome.gsettings("org.gnome.desktop.interface", "clock-show-weekday", "true")
  gnome.shortcut("custom0", "Open Ghostty", "ghostty", "<Ctrl><Alt>t")
end)
