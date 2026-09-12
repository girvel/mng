#!/usr/bin/env luajit
local stringx = require("mng.lib.stringx")

local ACTIONS = {
  {"󰍹  Power Off Monitors", "niri msg action power-off-monitors"},
  {"⏻  Power Off", "loginctl poweroff"},
  {"  Reboot", "loginctl reboot"},
  {"󰈆  Log Out", "loginctl terminate-session ''"},
}

local response do
  local actions_repr = ""
  for i, tuple in ipairs(ACTIONS) do
    if i > 1 then actions_repr = actions_repr.."\n" end
    actions_repr = actions_repr..tuple[1]
  end
  local cmd = string.format(
    "printf '%s' | fuzzel --dmenu --lines %s",
    actions_repr, #ACTIONS
  )
  local f = assert(io.popen(cmd, "r"))
  response = stringx.strip(f:read("*a"))
  f:close()
end

for _, tuple in ipairs(ACTIONS) do
  if response == tuple[1] then
    os.execute(tuple[2])
    return
  end
end
