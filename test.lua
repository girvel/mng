local mng = require("mng")

if os.getenv("USER") ~= "root" then
  io.stderr:write("Expected $USER to be root; please run with sudo.\n")
  os.exit(1)
end

mng.ensure_installed("zsh", "git")
mng.chsh("girvel", "/usr/bin/zsh")
mng.mkdir("/home/girvel/workshop")
mng.file_set("/home/girvel/.zshrc", mng.file_get("./.zshrc"))
