local mng = require("mng")


mng.package [[
  fuse man-pages-devel clang cmake zip unzip socklog-void chrony fzf
  zsh git curl wget neovim tree-sitter-cli ripgrep eza github-cli htop tree jq
]]
mng.service_on("socklog-unix", "nanoklogd", "chronyd")

mng.file("/etc/sysctl.d/20-quiet-console.conf", "kernel.printk = 3 4 1 3\n")  -- stop TTY spam
mng.as_user("girvel", function()
  mng.shell("/usr/bin/zsh")
  if not mng.dir_exists("~/.oh-my-zsh") then
    mng.cmd [[
      sh -c \
        "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    ]]
  end
  mng.dir("~/workshop")
  mng.git_repo("https://github.com/girvel/dotfiles", "~/dotfiles", true)
  mng.symlink("~/workshop/dotfiles", "~/dotfiles")
  mng.manual_stow("~/dotfiles", "~", {
    ".config/alacritty",
    ".config/nvim",
    ".config/zsh",
    ".local/bin/cb",
    ".mozilla/firefox/girvel/chrome",
    ".mozilla/firefox/girvel/user.js",
    ".gitconfig",
  })
  mng.symlink("~/.zshrc", "./console/.zshrc")
end)
