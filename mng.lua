local mng = {}

----------------------------------------------------------------------------------------------------
-- [SECTION] Internal tools
----------------------------------------------------------------------------------------------------

--- @param str string
--- @param pat string
--- @param plain boolean?
--- @return string[]
local string_split = function(str, pat, plain)
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

--- @param arr string[]
--- @param sep string
--- @return string
local string_join = function(arr, sep)
  if #arr == 0 then return "" end
  local result = arr[1]
  for i = 2, #arr do
    result = result.." "..arr[i]
  end
  return result
end

local string_strip = function(str)
  return str:gsub("^%s+", ""):gsub("%s+$", "")
end

local string_endswith = function(str, substr)
  return str:sub(-#substr) == substr
end

local cmd_fmt = function(fmt, ...)
  if select("#", ...) > 0 then fmt = fmt:format(...) end
  if mng.user ~= nil then
    fmt = string.format("su %s -c %s", mng.user, mng.cmd_quote(fmt))
  end
  return fmt
end

--- @param str string
--- @return string[]
local tokenize = function(str)
  return string_split(string_strip(str), "%s+")
end

--- @param t table
--- @param item any
--- @return integer?
local table_first_index = function(t, item)
  for i, e in ipairs(t) do
    if e == item then return i end
  end
end

local cli_seen = {}

local cli = function(name, description)
  if #cli_seen > 0 then
    error("cli() call should come first")
  end
  table.insert(cli_seen, {type = "cli", name = name, description = description})
end

local cli_help = function(hide_description)
  if cli_seen[1].type == "cli" then
    local data = table.remove(cli_seen, 1)
    if not hide_description then print(data.description) end
    io.write("USAGE: "..data.name)
  else
    io.write("USAGE: <FILENAME>")
  end

  local was_prev_flag = false
  for _, param in ipairs(cli_seen) do
    if param.type == "command" then
      io.write(" <command>")
    elseif param.type == "flag" then
      if not was_prev_flag then
        io.write(" <flags>")
      end
    end

    was_prev_flag = param.type == "flag"
  end
  print()

  was_prev_flag = false
  for _, param in ipairs(cli_seen) do
    if param.type == "command" then
      print()
      print("COMMAND:")
      for v, desc in pairs(param.possible_values) do
        print("  "..v..": "..desc);
      end
    elseif param.type == "flag" then
      if not was_prev_flag then
        print()
        print("FLAGS:")
      end
      print("  "..param.flag..": "..param.description)
    end
    was_prev_flag = param.type == "flag"
  end
end

-- TODO move internals to mng.utils
--- @param args string[]
--- @param possible_values table<string, string>
--- @param default string?
--- @return string?
local cli_command = function(args, possible_values, default)
  table.insert(cli_seen, {
    type = "command",
    possible_values = possible_values,
    default = default
  })

  if possible_values[args[1]] then
    return table.remove(args, 1)
  end
  return default
end

local cli_flag = function(args, flag, description)
  table.insert(cli_seen, {type = "flag", flag = flag, description = description})
  local i = table_first_index(args, flag)
  if i then
    table.remove(args, i)
  end
  return not not i
end

local cli_finish = function(args)
  if #args == 0 then return end
  io.write("Unexpected args:")
  for _, arg in ipairs(args) do
    io.write(" "..arg)
  end
  io.write("\n\n")
  cli_help(true)
  os.exit(1)
end

local cli_args
local finish_subs = {}

----------------------------------------------------------------------------------------------------
-- [SECTION] API
----------------------------------------------------------------------------------------------------

--- @param ... string CLI args
mng.start = function(...)
  local args = {...}
  cli("<MNG FILE>", "mng is a tool for procedural OS configuration")
  cli_args = {
    clean = cli_flag(args, "--clean", "Also clean the garbage"),
  }
  if cli_flag(args, "--help", "Display help") then
    cli_help()
    os.exit(0)
  end
  cli_finish(args)
end

mng.finish = function()
  for sub in pairs(finish_subs) do
    sub()
  end
end

--- @type string?
mng.user = nil

mng.cmd = function(command, ...)
  command = cmd_fmt(command, ...)
  os.execute(command)
end

--- @param command string
--- @return string
--- @return integer?
mng.cmd_read = function(command, ...)
  command = cmd_fmt(command, ...)
  local f = assert(io.popen(command, "r"))
  local result = f:read("*a")
  local _, _, code = f:close()
  if result:sub(-1, -1) == "\n" then
    result = result:sub(1, -2)
  end
  return result, code
end

mng.cmd_quote = function(expr)
  return ("'%s'"):format(expr:gsub("'", "'\\''"))
end

local all_packages = {
  ["LuaJIT"] = true,
  ["base-system"] = true,
  ["grub-x86_64-efi"] = true,
  ["linux-headers"] = true,
}

local package_cleaning = function()
  io.write("PACKAGES ")
  io.flush()

  local installed_packages = string_split(string_strip(mng.cmd_read("xbps-query -m")), "\n")
  local redundant_packages = {}
  for _, pkg in ipairs(installed_packages) do
    local name = pkg:match("^(.*)-[^-]+")
    if not all_packages[name] then
      table.insert(redundant_packages, name)
    end
  end

  if #redundant_packages == 0 then
    print("+")
    return
  else
    print(":")
  end

  print("Found redundant packages:")
  for _, pkg in ipairs(redundant_packages) do
    print("- "..pkg)
  end
  io.write("\nRemove? [y/n] ")
  local response = io.read("*l"):lower()
  if response == "y" or response == "yes" then
    mng.cmd("xbps-remove -y %s", string_join(redundant_packages, " "))
  end
end

mng.package = function(packages)
  if cli_args.clean then
    finish_subs[package_cleaning] = true
  end

  for _, pkg in ipairs(tokenize(packages)) do
    if cli_args.clean then
      all_packages[pkg] = true
    end

    if not mng.package_is_installed(pkg) then
      mng.package_install(pkg)
    end
  end
end

mng.package_is_installed = function(pkg)
  -- automatic-install isn't switched off by xbps-install by default
  return mng.cmd_read("xbps-query %s -p state", pkg) == "installed"
end

mng.package_install = function(pkg)
  mng.cmd("xbps-install -yS "..pkg)
end

mng.as_user = function(new_user, f)
  local prev = mng.user
  mng.user = new_user
  f()
  mng.user = prev
end

mng.shell = function(path)
  local current_user = mng.user or os.getenv("USER")
  if mng.shell_get(current_user) ~= path then
    mng.shell_set(path)
  end
end

mng.shell_get = function(this_user)
  this_user = this_user or mng.user
  return string_split(mng.cmd_read("getent passwd %s", this_user), ":")[7]
end

mng.shell_set = function(path)
  mng.cmd("chsh -s %s", path)
end

mng.dir = function(path)
  mng.cmd("mkdir -p "..path)
end

mng.dir_exists = function(path)
  path = mng.cmd_read("echo %s", path)
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
  path = mng.cmd_read("echo %s", path)
  mng.cmd("touch %s", path)
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
  mng.cmd("rm -f %s", path)
end

mng.git_repo = function(repo_path, destination, update)
  if mng.dir_exists(destination) then
    if mng.cmd_read("cd %s; git remote get-url origin", destination) == repo_path then
      goto update
    end
    mng.dir_remove(destination)
  end
  mng.cmd("git clone "..repo_path.." "..destination.." --recurse-submodules")

  ::update::
  if update then
    mng.cmd("cd "..destination.."; git pull -q")
    mng.cmd("cd "..destination.."; git submodule update --init --recursive")
  end
end

mng.stow = function(source, target)
  mng.cmd("stow -d "..source.." -t "..target.." .")
end

mng.hostname_get = function()
  return string_strip(mng.file_get("/etc/hostname"))
end

mng.symlink = function(path, value)
  value = mng.cmd_read("realpath -s %s", value)
  if mng.symlink_exists(path) then
    if mng.symlink_get(path) == value then
      return false
    end
    mng.file_remove(path)
  end
  mng.symlink_set(path, value)
  return true
end

mng.symlink_exists = function(path)
  return mng.cmd_read("if [ -L %s ]; then echo 1; else echo 0; fi", path) == "1"
end

mng.symlink_get = function(path)
  return mng.cmd_read("readlink -f %s", path)
end

mng.symlink_set = function(path, value)
  mng.cmd("ln -sfn %s %s", value, path)
end

mng.service_on = function(...)
  for i = 1, select("#", ...) do
    local name = select(i, ...)
    mng.symlink("/var/service/"..name, "/etc/sv/"..name)
  end
end

mng.service_off = function(...)
  for i = 1, select("#", ...) do
    local name = select(i, ...)
    mng.file_remove("/var/service/"..name)
  end
end

mng.desktop_file = function(path)
  local target_dir
  if mng.user then
    target_dir = "/home/"..mng.user.."/.local/share/applications/"
  else
    target_dir = "/usr/share/applications/"
  end

  local shortname = path:match("[^/]+$")
  if mng.symlink(target_dir..shortname, path) then
    mng.cmd("update-desktop-database "..target_dir)
  end
end

mng.icon = function(path)
  local shortname = path:match("[^/]+$")
  local resolution
  if string_endswith(path, ".svg") then
    resolution = "scalable"
  else
    local info = mng.cmd_read("file -b %s", mng.cmd_quote(path))
    local w, h = info:match("(%d+)%s*x%s*(%d+)")
    if not w or not h then
      error("Could not determine resolution for icon "..path)
    end
    resolution = w.."x"..h
  end
  local target_dir = "/usr/share/icons/hicolor"..resolution.."/apps"
  mng.dir(target_dir)
  if mng.symlink(target_dir.."/"..shortname, path)
    and mng.cmd_read("command -v gtk-update-icon-cache") ~= ""
  then
    mng.cmd("gtk-update-icon-cache -f -t /usr/share/icons/hicolor")
  end
end

return mng
