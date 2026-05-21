local mng = require("mng")
local gnome = require("mng.gnome")


if os.getenv("USER") ~= "root" then
  error("Expected $USER to be root; please run with sudo.")
end

local hostname = mng.hostname_get()
if hostname == "sovngard1" then
  mng.package("mesa-dri virtualbox-ose-guest virtualbox-ose-guest virtualbox-ose-guest-dkms")
  mng.service_on("vboxservice")
else
  error("No machine-specific configuration for "..hostname)
end

gnome.on()
mng.package [[
  xdg-utils fuse
  zsh git stow curl wget neovim ripgrep eza github-cli love htop tree
  ghostty firefox vlc obs kdenlive audacity
]]

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
  mng.dir("~/.mozilla/firefox/girvel")
  mng.dir("~/.config")
  mng.dir("~/.local/bin")
  mng.git_repo("https://github.com/girvel/dotfiles", "~/dotfiles", true)
  mng.stow("~/dotfiles", "~")
  mng.file_set("~/.zshrc", mng.file_get("./example/.zshrc"))

  gnome.gsettings("org.gnome.desktop.interface", "clock-show-weekday", "true")
  gnome.gsettings("org.gnome.desktop.interface", "color-scheme", "'prefer-dark'")
  gnome.gsettings("org.gnome.shell.keybindings", "show-screenshot-ui", "['<Super><Shift>s']")
  gnome.shortcut("custom0", "Open Ghostty", "ghostty", "<Ctrl><Alt>t")
end)
