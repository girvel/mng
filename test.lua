local mng = require("mng")

mng.ensure_installed("fish-shell")
os.execute("su girvel -c 'chsh -s /usr/bin/fish'")
