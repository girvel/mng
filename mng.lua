----------------------------------------------------------------------------------------------------
-- [SECTION] Internal tools
----------------------------------------------------------------------------------------------------

--- @param str string
--- @param pat string
--- @param plain boolean?
--- @return string[]
string.split = function(str, pat, plain)
  -- TODO don't use string built-in
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

local string_strip = function(str)
  return select(3, str:find("^%s*(.*)%s$"))
end

--- @type string?
local user = nil

local cmd_fmt = function(fmt, ...)
  if select("#", ...) > 0 then fmt = fmt:format(...) end
  if user ~= nil then
    fmt = string.format("su %s -c '%s'", user, fmt:gsub("'", "\\'"))
  end
  return fmt
end

--- @param command string
--- @return string
--- @return integer?
local cmd_read = function(command, ...)
  command = cmd_fmt(command, ...)
  local f = assert(io.popen(command, "r"))
  local result = f:read("*a")
  local _, _, code = f:close()
  if result:sub(-1, -1) == "\n" then
    result = result:sub(1, -2)
  end
  return result, code
end

local cmd = function(command, ...)
  command = cmd_fmt(command, ...)
  os.execute(command)
end

local is_installed = function(pkg)
  -- automatic-install isn't switched off by xbps-install by default
  return cmd_read("xbps-query %s -p state", pkg) == "installed"
end

local install = function(pkg)
  cmd("xbps-install -yS "..pkg)
end

local get_shell = function(this_user)
  return cmd_read("getent passwd %s", this_user):split(":")[7]
end

local change_shell = function(this_user, path)
  cmd("sudo -u "..this_user.." chsh -s "..path)
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

mng.cmd = function(command, ...)
  return cmd(command, ...)
end

mng.cmd_read = function(command, ...)
  return cmd_read(command, ...)
end

mng.as_user = function(new_user, f)
  local prev = user
  user = new_user
  f()
  user = prev
end

mng.chsh = function(path)
  local current_user = os.getenv("USER")
  if get_shell(current_user) ~= path then
    change_shell(current_user, path)
  end
end

mng.mkdir = function(path)
  cmd("mkdir -p "..path)
end

mng.directory_exists = function(path)
  path = cmd_read("echo %s", path)
  if path:sub(-1) ~= "/" then
    path = path.."/"
  end
  return mng.file_exists(path)
end

mng.file_exists = function(path)
  local f = io.open(path, "r")
  if not f then return false end
  f:close()
  return true
end

mng.file_set = function(path, content)
  cmd("touch %s", path)
  local f = assert(io.open(path, "w"))
  f:write(content)
  f:close()
end

--- @return string
mng.file_get = function(path, content)
  local f = assert(io.open(path, "r"))
  local result = f:read("*a")
  f:close()
  return result
end

mng.file_remove = function(path)
  cmd("rm -f %s", path)
end

mng.git_clone = function(repo_path, destination)
  if not mng.directory_exists(destination)
    or not mng.directory_exists(destination.."/.git")
  then
    cmd("git clone "..repo_path.." "..destination.." --recurse-submodules")
  else
    cmd("cd "..destination.."; git pull -q")
    cmd("cd "..destination.."; git submodule update --init --recursive")
  end
end

mng.stow = function(source, target)
  cmd("stow -d "..source.." -t "..target.." .")
end

mng.hostname_get = function()
  return string_strip(mng.file_get("/etc/hostname"))
end

mng.symlink_exists = function(path)
  return cmd_read("if [ -L %s ]; then echo 1; else echo 0; fi", path) == "1"
end

mng.symlink_get = function(path)
  return cmd_read("readlink -f %s", path)
end

mng.symlink_set = function(path, value)
  cmd("ln -sfn %s %s", value, path)
end

mng.service_ensure_enabled = function(...)
  for i = 1, select("#", ...) do
    local name = select(i, ...)
    local target_path = "/var/service/"..name
    local source_path = "/etc/sv/"..name
    if mng.symlink_exists(target_path) then
      if mng.symlink_get(target_path) == source_path then
        goto continue
      end
      mng.file_remove(target_path)
    end
    mng.symlink_set(target_path, source_path)

    ::continue::
  end
end

mng.service_ensure_disabled = function(...)
  for i = 1, select("#", ...) do
    local name = select(i, ...)
    local target_path = "/var/service/"..name
    mng.file_remove(target_path)
  end
end

return mng
