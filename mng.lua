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

local string_starts_with = function(str, prefix)
  return str:sub(1, #prefix) == prefix
end

local string_ends_with = function(str, substr)
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
      if param.description then
        print("  "..param.flag..": "..param.description)
      else
        print("  "..param.flag)
      end
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
  flag = string_strip(flag)
  local flags = string_split(flag, "%s+")
  table.insert(cli_seen, {type = "flag", flag = flag, description = description})

  for i, arg in ipairs(args) do
    if string_starts_with(arg, "--") then
      if table_first_index(flags, arg) then
        table.remove(args, i)
        return true
      end
    elseif string_starts_with(arg, "-") then
      for j = 1, #arg do
        local char = arg:sub(j, j)
        if table_first_index(flags, "-"..char) then
          if #arg == 2 then
            table.remove(args, i)
          else
            args[i] = arg:sub(1, j - 1) .. arg:sub(j + 1)
          end
          return true
        end
      end
    end
  end
  return false
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

local request_yes = function(phrase, yes_is_default)
  io.write("\n"..phrase)
  if yes_is_default then
    io.write(" [Y/n] ")
  else
    io.write(" [y/N] ")
  end
  local response = io.read("*l"):lower()
  if yes_is_default then
    return response == "n" or response == "no"
  else
    return response == "y" or response == "yes"
  end
end

--- @param path string
--- @return string?
local dir_base = function(path)
  return path:match("^(.*)/[^/]+$")
end

--- @param path string
--- @return string
local dir_head = function(path)
  return path:match("([^/]+)/*$")
end

--- @class cli_args
--- @field clean boolean
--- @field verbose boolean
--- @field no_update boolean
--- @type cli_args
local cli_args
local run_at_finish = {}  -- TODO rename, expose as advanced

----------------------------------------------------------------------------------------------------
-- [SECTION] API
----------------------------------------------------------------------------------------------------

--- @param ... string CLI args
mng.start = function(...)
  if os.getenv("USER") ~= "root" then
    error("Expected $USER to be root; please run with sudo.")
  end

  local args = {...}
  cli("sudo luajit init.lua", "mng is a tool for procedural OS configuration")
  cli_args = {
    clean = cli_flag(args, "-c --clean", "Clean the garbage, s.a. redundant packages & services"),
    no_update = cli_flag(args, "-U --no-update", "Don't trigger updates, s.a. xbps-install -S"),
    verbose = cli_flag(args, "-v --verbose", nil),
  }
  if cli_flag(args, "-h --help", "Display help") then
    cli_help()
    os.exit(0)
  end
  cli_finish(args)
end

mng.finish = function()
  for sub in pairs(run_at_finish) do
    sub()
  end
end

--- @type string?
mng.user = nil

mng.cmd = function(command, ...)
  command = cmd_fmt(command, ...)
  if cli_args.verbose then
    print("[CMD] "..command)
  end
  local _, _, code = os.execute(command)
  if cli_args.verbose then
    print("[RET] "..code)
  end
end

--- @param command string
--- @return string
--- @return integer?
mng.cmd_read = function(command, ...)
  command = cmd_fmt(command, ...)
  if cli_args.verbose then
    print("[CMD] "..command)
  end
  local f = assert(io.popen(command, "r"))
  local result = f:read("*a")
  local _, _, code = f:close()
  if result:sub(-1, -1) == "\n" then
    result = result:sub(1, -2)
  end
  if cli_args.verbose then
    print(("[RES] %q"):format(result))
    print("[RET] "..code)
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

local builtin_packages = {
  ["base-system"] = true,
  ["grub-x86_64-efi"] = true,
  ["linux-headers"] = true,
}

local clean_packages = function()
  print("PACKAGES")

  local manual_packages_raw = string_split(string_strip(mng.cmd_read("xbps-query -m")), "\n")
  local redundant_packages = {}
  local manual_packages = {}
  for _, pkg in ipairs(manual_packages_raw) do
    local name = pkg:match("^(.*)-[^-]+")
    manual_packages[name] = true
    if not all_packages[name] then
      table.insert(redundant_packages, name)
    end
  end

  local unmarked_packages = {}
  for pkg in pairs(all_packages) do
    if not manual_packages[pkg] and not builtin_packages[pkg] then
      table.insert(unmarked_packages, pkg)
    end
  end

  if #unmarked_packages > 0 then
    print("Found packages not marked as manual:")
    for _, pkg in ipairs(unmarked_packages) do
      print("- "..pkg)
    end

    mng.cmd("xbps-pkgdb -m manual "..string_join(unmarked_packages, " "))
  end

  if #redundant_packages > 0 then
    print("Found redundant packages:")
    for _, pkg in ipairs(redundant_packages) do
      print("- "..pkg)
    end

    mng.cmd("xbps-pkgdb -m auto "..string_join(redundant_packages, " "))
  end

  mng.cmd("xbps-remove -o")
end

--- @return boolean was_updated
mng.package = function(packages)
  if cli_args.clean then
    run_at_finish[clean_packages] = true
  end

  local was_updated = false
  for _, pkg in ipairs(tokenize(packages)) do
    if cli_args.clean then
      all_packages[pkg] = true
    end

    if not mng.package_is_installed(pkg) then
      was_updated = true
      mng.package_install(pkg)
    end
  end

  return was_updated
end

mng.package_is_installed = function(pkg)
  -- automatic-install isn't switched off by xbps-install by default
  return mng.cmd_read("xbps-query %s -p state", pkg) == "installed"
end

local xbps_synced = false
mng.package_install = function(pkg)
  if not xbps_synced and not cli_args.no_update then
    xbps_synced = true
    mng.cmd("xbps-install -S")
  end
  mng.cmd("xbps-install -y "..pkg)
end

mng.xbps_mirror = function(mirror)
  mng.file("/etc/xbps.d/00-repository-main.conf", "repository="..mirror)
  if cli_args.no_update then
    xbps_synced = false
  else
    xbps_synced = true
    mng.cmd("xbps-install -S")
  end
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

--- @param path string
--- @return boolean was_updated
mng.dir = function(path)
  local will_be_updated = not mng.dir_exists(path)
  if will_be_updated then
    mng.cmd("mkdir -p "..path)
  end
  return will_be_updated
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

--- Ensure exact file content
--- @return boolean was_updated
mng.file = function(path, content)
  local base_dir = dir_base(path)
  local will_be_updated = base_dir and mng.dir(base_dir) or mng.file_get(path) ~= content
  if will_be_updated then
    mng.file_set(path, content)
  end
  return will_be_updated
end

--- Ensure target's content matches source's
--- @return boolean was_updated
mng.file_sync = function(target, source)
  local expected = mng.file_get(source)
  if not expected then
    error(("source file %q is missing"):format(source))
  end

  local will_be_updated = mng.file_get(target) ~= expected
  if will_be_updated then
    mng.file_set(target, expected)
  end
  return will_be_updated
end

mng.file_set = function(path, content)
  path = mng.cmd_read("echo %s", path)
  mng.cmd("touch %s", path)
  local f = assert(io.open(path, "w"))
  f:write(content)
  f:close()
end

--- @return string?
mng.file_get = function(path)
  local f = io.open(path, "r")
  if not f then return end
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

mng.manual_stow = function(source, target, symlinks)
  for _, file in ipairs(symlinks) do
    mng.symlink(target.."/"..file, source.."/"..file)
  end
end

mng.stow = function(source, target)
  mng.cmd("stow -d "..source.." -t "..target.." .")
end

mng.hostname_get = function()
  return string_strip(mng.file_get("/etc/hostname"))
end

--- @return boolean was_updated
mng.symlink = function(path, value)
  value = mng.cmd_read("realpath -s %s", value)
  local base_dir = dir_base(path)
  if base_dir then mng.dir(base_dir) end
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
  mng.cmd("ln -sfnT %s %s", value, path)
end

local service_state = {
  ["agetty-tty1"] = true,
  ["agetty-tty2"] = true,
  ["agetty-tty3"] = true,
  ["agetty-tty4"] = true,
  ["agetty-tty5"] = true,
  ["agetty-tty6"] = true,
  ["dhcpcd"] = true,
  ["wpa_supplicant"] = true,
}

local clean_services = function()
  print("SERVICES")

  local services_real = string_split(string_strip(mng.cmd_read("ls /var/service")), "%s+")
  local services_to_off = {}
  for _, service in ipairs(services_real) do
    if not service_state[service] then
      table.insert(services_to_off, service)
    end
  end

  local services_to_on = {}
  for service, v in pairs(service_state) do
    if v and not table_first_index(services_real, service) then
      table.insert(services_to_on, service)
    end
  end

  if #services_to_off > 0 then
    print("Found redundant services:")
    for _, service in ipairs(services_to_off) do
      print("- "..service)
    end

    if request_yes("Disable?") then
      mng.service_off(unpack(services_to_off))
    end
  end

  if #services_to_on > 0 then
    print("Found missing services:")
    for _, service in ipairs(services_to_on) do
      print("- "..service)
    end

    if request_yes("Enable?") then
      mng.service_on(unpack(services_to_on))
    end
  end
end

mng.service_on = function(...)
  if cli_args.clean then
    run_at_finish[clean_services] = true
  end

  for i = 1, select("#", ...) do
    local name = select(i, ...)
    if cli_args.clean then
      service_state[name] = true
    end
    mng.symlink("/var/service/"..name, "/etc/sv/"..name)
  end
end

mng.service_off = function(...)
  if cli_args.clean then
    run_at_finish[clean_services] = true
  end

  for i = 1, select("#", ...) do
    local name = select(i, ...)
    if cli_args.clean then
      service_state[name] = false
    end
    mng.file_remove("/var/service/"..name)
  end
end

local update_desktop_db_dirs = {}
local update_desktop_db = function()
  for dir in pairs(update_desktop_db_dirs) do
    mng.cmd("update-desktop-database "..dir)
  end
end

mng.desktop_file = function(path)
  local target_dir
  if mng.user then
    target_dir = "/home/"..mng.user.."/.local/share/applications/"
  else
    target_dir = "/usr/share/applications/"
  end

  local shortname = dir_head(path)
  if mng.symlink(target_dir..shortname, path) then
    run_at_finish[update_desktop_db] = true
    update_desktop_db_dirs[target_dir] = true
  end
end

local update_icon_cache = function()
  if mng.cmd_read("command -v gtk-update-icon-cache") ~= "" then
    mng.cmd("gtk-update-icon-cache -f -t /usr/share/icons/hicolor")
  end
end

mng.icon = function(path)
  local shortname = dir_head(path)
  local resolution
  if string_ends_with(path, ".svg") then
    resolution = "scalable"
  else
    local info = mng.cmd_read("file -b %s", mng.cmd_quote(path))
    local w, h = info:match("(%d+)%s*x%s*(%d+)")
    if not w or not h then
      error("Could not determine resolution for icon "..path)
    end
    resolution = w.."x"..h
  end
  local target_dir = "/usr/share/icons/hicolor/"..resolution.."/apps"
  mng.dir(target_dir)
  if mng.symlink(target_dir.."/"..shortname, path) then
    run_at_finish[update_icon_cache] = true
  end
end

return mng
