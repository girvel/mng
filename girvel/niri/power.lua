#!/usr/bin/env luajit
local stringx = require("mng.lib.stringx")

local response do
  local f = assert(io.popen(
    "printf '󰈆  Log Out\n⏻  Power Off\n  Reboot' | fuzzel --dmenu --lines 3", "r"
  ))
  response = stringx.strip(f:read("*a")):lower()
  response = response:match("^%S+%s+(.*)$")
  f:close()
end

if response == "power off" then
  os.execute("loginctl poweroff")
elseif response == "reboot" then
  os.execute("loginctl reboot")
elseif response == "log out" then
  os.execute("loginctl terminate-session ''")
end
