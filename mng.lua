----------------------------------------------------------------------------------------------------
-- [SECTION] Internal tools
----------------------------------------------------------------------------------------------------

--- @param str string
--- @param pat string
--- @param plain boolean?
--- @return string[]
string.split = function(str, pat, plain)
  local t = {}

  while true do
    local pos1, pos2 = str:find(pat, 1, plain or false)

    if not pos1 or pos1 > pos2 then
      t[#t + 1] = str
      return t
    end

    t[#t + 1] = str:sub(1, pos1 - 1)
    str = str:sub(pos2 + 1)
  end
end

--- @param cmd string
--- @return string
local cmd_read = function(cmd, ...)
  if select("#", ...) > 0 then cmd = cmd:format(...) end
  local f = assert(io.popen(cmd, "r"))
  local result = f:read("*a")
  f:close()
  if result:sub(-1, -1) == "\n" then
    return result:sub(1, -2)
  end
  return result
end

local is_installed = function(pkg)
  return cmd_read("xbps-query %s -p state,automatic-install", pkg) == "installed"
end

local install = function(pkg)
  os.execute("xbps-install -yS "..pkg)
end

local get_shell = function(user)
  return cmd_read("getent passwd %s", user):split(":")[7]
end

local change_shell = function(user, path)
  os.execute("sudo -u "..user.." chsh -s "..path)
end

----------------------------------------------------------------------------------------------------
-- [SECTION] API
----------------------------------------------------------------------------------------------------

local mng = {}

mng.ensure_installed = function(...)
  for i = 1, select("#", ...) do
    local pkg = select(i, ...)
    if not is_installed(pkg) then
      install(pkg)
    end
  end
end

mng.chsh = function(user, path)
  if get_shell(user) ~= path then
    change_shell(user, path)
  end
end

return mng
