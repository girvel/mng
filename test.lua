local mng = require("mng")

if os.getenv("USER") ~= "root" then
  error("Expected $USER to be root; please run with sudo.")
end

mng.ensure_installed("void-vepo-nonfree")

local hostname = mng.hostname_get()
if hostname == "sovngard1" then
  mng.ensure_installed(
    "mesa-dri", "virtualbox-ose-guest", "virtualbox-ose-guest", "virtualbox-ose-guest-dkms"
  )
  -- TODO enable virtualbox service
else
  error("No machine-specific configuration for "..hostname)
end

mng.ensure_installed(
  "zsh", "git", "stow", "curl", "neovim", "ripgrep"
)

mng.as_user("girvel", function()
  mng.chsh("/usr/bin/zsh")
  if not mng.directory_exists("~/.oh-my-zsh") then
    mng.cmd [[
      sh -c \
        "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    ]]
  end
  mng.mkdir("~/workshop")
  mng.git_clone("https://github.com/girvel/dotfiles", "/home/girvel/dotfiles")
  mng.stow("/home/girvel/dotfiles", "/home/girvel")
  mng.file_set("/home/girvel/.zshrc", mng.file_get("./.zshrc"))
end)
