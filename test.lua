local mng = require("mng")

if os.getenv("USER") ~= "root" then
  io.stderr:write("Expected $USER to be root; please run with sudo.\n")
  os.exit(1)
end

mng.ensure_installed("zsh", "git", "stow", "curl", "neovim", "ripgrep")

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
