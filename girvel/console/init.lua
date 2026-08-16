local mng = require("mng")


mng.package [[
  fuse man-pages-devel clang cmake zip unzip socklog-void chrony fzf tar xz nodejs
  zsh git curl wget neovim tree-sitter-cli ripgrep eza github-cli htop tree jq
]]
mng.service_on("socklog-unix", "nanoklogd", "chronyd")

mng.file("/etc/sysctl.d/20-quiet-console.conf", "kernel.printk = 3 4 1 3\n")  -- stop TTY spam
mng.as_user("girvel", function()
  mng.shell("/usr/bin/zsh")
  if not mng.dir_exists("~/.oh-my-zsh") then
    mng.cmd [[
      RUNZSH=no CHSH=no sh -c \
        "$(curl --connect-timeout 5 -fL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    ]]
  end
  mng.dir("~/workshop")
  mng.git_repo("~/dotfiles", "github.com/girvel/dotfiles", true)
  mng.symlink("~/workshop/dotfiles", "~/dotfiles")
  mng.manual_stow("~", "~/dotfiles", {
    ".config/alacritty",
    ".config/nvim",
    ".config/zsh",
    ".mozilla/firefox/girvel/chrome",
    ".mozilla/firefox/girvel/user.js",
    ".gitconfig",
  })

  if mng.hostname_get() == "gjoll" then
    mng.symlink("~/.zshrc", "./console/.zshrc-typewriter")
  else
    mng.symlink("~/.zshrc", "./console/.zshrc")
  end

  mng.symlink("~/.config/htop/htoprc", "./console/htoprc")
  mng.symlink("~/.local/bin/Rebuild", "./console/Rebuild")
end)
