local cli = require("mng.lib.cli")
local tablex = require("mng.lib.tablex")
local stringx = require("mng.lib.stringx")


local mng = {}

----------------------------------------------------------------------------------------------------
-- [SECTION] Internal tools
----------------------------------------------------------------------------------------------------

local cmd_fmt = function(fmt, ...)
  if select("#", ...) > 0 then fmt = fmt:format(...) end
  if mng.user ~= nil then
    fmt = string.format("su %s -c %s", mng.user, mng.cmd_quote(fmt))
  end
  return fmt
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
  cli.define("sudo luajit init.lua", "mng is a tool for centralized imperative Void Linux configuration")

  mng.cli_args = {
    module = cli.option(
      args, "-m --module",
      "Run only the given module"
    ),
    clean = cli.flag(
      args, "-c --clean",
      "Clean the garbage, s.a. redundant packages & services (asks permission)"
    ),
    light = cli.flag(
      args, "-l --light",
      "Allows not to run performance-heavy code marked with `if not mng.cli_args.light`"
    ),
    no_sync = cli.flag(args, "-S --no-sync", "Do not sync with remote repository"),
    verbose = cli.flag(args, "-v --verbose", nil),
  }

  if mng.cli_args.module and mng.cli_args.clean then
    print("[ERR] --module and --clean are incompatible")
    os.exit(1)
  end

  if cli.flag(args, "-h --help", "Display help") then
    cli.help()
    os.exit(0)
  end
  cli.check_remainder(args)
end

mng.finish = function()
  for sub in pairs(run_at_finish) do
    sub()
  end
  os.exit(mng.exit_code)
end

mng.cmd = function(command, ...)
  command = cmd_fmt(command, ...)
  if mng.cli_args.verbose then
    print("[CMD] "..command)
  end
  local _, _, code = os.execute(command)
  if mng.cli_args.verbose then
    print("[RET] "..code)
  end
end

--- @param command string
--- @return string
--- @return integer?
mng.cmd_read = function(command, ...)
  command = cmd_fmt(command, ...)
  if mng.cli_args.verbose then
    print("[CMD] "..command)
  end
  local f = assert(io.popen(command, "r"))
  local result = f:read("*a")
  local _, _, code = f:close()
  if result:sub(-1, -1) == "\n" then
    result = result:sub(1, -2)
  end
  if mng.cli_args.verbose then
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
  print("[CLN] Packages")

  local manual_packages_raw = stringx.split(stringx.strip(mng.cmd_read("xbps-query -m")), "\n")
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

    mng.cmd("xbps-pkgdb -m manual "..stringx.join(unmarked_packages, " "))
  end

  if #redundant_packages > 0 then
    print("Found redundant packages:")
    for _, pkg in ipairs(redundant_packages) do
      print("- "..pkg)
    end

    mng.cmd("xbps-pkgdb -m auto "..stringx.join(redundant_packages, " "))
  end

  mng.cmd("xbps-remove -o")
end

--- @return boolean was_updated
mng.package = function(packages)
  if mng.cli_args.clean then
    run_at_finish[clean_packages] = true
  end

  local was_updated = false
  for _, pkg in ipairs(mng.tokenize(packages)) do
    if mng.cli_args.clean then
      all_packages[pkg] = true
    end

    if not mng.package_is_installed(pkg) then
      was_updated = true
      mng.package_install(pkg)  -- TODO install in bulk?
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
  if not xbps_synced and not mng.cli_args.no_sync then
    xbps_synced = true
    mng.cmd("xbps-install -S")
  end
  mng.cmd("xbps-install -y "..pkg)
end

mng.xbps_mirror = function(mirror)
  mng.file("/etc/xbps.d/00-repository-main.conf", "repository="..mirror)
  if mng.cli_args.no_sync then
    xbps_synced = false
  else
    xbps_synced = true
    mng.cmd("xbps-install -S")
  end
end

mng.repo = function(package_list)
  local was_updated = mng.package(package_list)
  if was_updated then
    mng.cmd("xbps-install -u")
  end
  return was_updated
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
  return stringx.split(mng.cmd_read("getent passwd %s", this_user), ":")[7]
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
  path = mng.cmd_read("echo %s", path)
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

mng.recursive_remove = function(...)
  for i = 1, select("#", ...) do
    local path = select(i, ...)
    mng.cmd("rm -rf %s", mng.cmd_quote(path))
  end
end

mng.file_remove = function(path)
  mng.cmd("rm -f %s", mng.cmd_quote(path))
end

mng.git_repo = function(repo_path, destination, update)
  if mng.dir_exists(destination) then
    if mng.cmd_read("cd %s; git remote get-url origin", destination) == repo_path then
      goto update
    end
    mng.recursive_remove(destination)
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
  return stringx.strip(assert(mng.file_get("/etc/hostname")))
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
  elseif mng.file_exists(path) then
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
  print("[CLN] Services")

  local services_real = stringx.split(stringx.strip(mng.cmd_read("ls /var/service")), "%s+")
  local services_to_off = {}
  for _, service in ipairs(services_real) do
    if not service_state[service] then
      table.insert(services_to_off, service)
    end
  end

  local services_to_on = {}
  for service, v in pairs(service_state) do
    if v and not tablex.first_index(services_real, service) then
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
  if mng.cli_args.clean then
    run_at_finish[clean_services] = true
  end

  for i = 1, select("#", ...) do
    local name = select(i, ...)
    if mng.cli_args.clean then
      service_state[name] = true
    end
    mng.symlink("/var/service/"..name, "/etc/sv/"..name)
  end
end

mng.service_off = function(...)
  if mng.cli_args.clean then
    run_at_finish[clean_services] = true
  end

  for i = 1, select("#", ...) do
    local name = select(i, ...)
    if mng.cli_args.clean then
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
  if stringx.ends_with(path, ".svg") then
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

local last_module_to_run
local all_modules = {}
local check_some_module_ran = function()
  if last_module_to_run then return end

  mng.exit_code = 1
  print("[ERR] Unknown module "..mng.cli_args.module)
  if #all_modules == 0 then
    print("No modules defined.")
  else
    print("Available modules:")
    for _, mod in ipairs(all_modules) do
      print("- "..mod)
    end
  end
end

--- @param folder_path string
--- @param cannot_fail? boolean
mng.module = function(folder_path, cannot_fail)
  table.insert(all_modules, folder_path)
  if not mng.dir_exists(folder_path) then
    error("No module directory at "..folder_path)
  end

  local filepath = folder_path.."/init.lua"
  if not mng.file_exists(filepath) then
    error("Module is expected to have its logic defined in init.lua file")
  end

  if mng.cli_args.module and mng.cli_args.module ~= folder_path then
    run_at_finish[check_some_module_ran] = true
    if mng.cli_args.verbose then
      print("[INF] Skipping module "..folder_path)
    end
    return
  end
  last_module_to_run = folder_path

  if mng.cli_args.verbose then
    print("[MOD] "..folder_path)
  end

  local ok, err = xpcall(dofile, debug.traceback, filepath)
  if not ok then
    print(("[ERR] Error while executing module %s: \n%s"):format(
      folder_path,
      err or "(no message provided)"
    ))
    if cannot_fail then
      os.exit(1)
    end
  end
end

mng.curl_proxy = nil
mng.curl_file = function(filepath, url)
  local cmd = ("curl %s -o %s"):format(
    mng.cmd_quote(url),
    mng.cmd_quote(filepath)
  )
  if mng.curl_proxy then
    cmd = cmd.." --preproxy="..mng.cmd_quote(mng.curl_proxy)
  end
  mng.cmd(cmd)
end

--- @return boolean was_updated
mng.theme_installed = function(name, url)
  -- TODO use tar or unzip
  -- TODO fix additional folder conflict

  local themes_dir = mng.user
    and ("/home/"..mng.user.."/.local/share/themes")
    or "/usr/share/themes"

  if mng.dir_exists(themes_dir.."/"..name) then return false end
  mng.dir(themes_dir)

  local tmp_archive = "/tmp/theme.tar.gz"
  local tmp_folder = "/tmp/theme"
  mng.recursive_remove(tmp_archive, tmp_folder)
  mng.dir(tmp_folder)

  mng.curl_file(tmp_archive, url)
  mng.cmd("tar -xf %s -C %s", tmp_archive, tmp_folder)
  mng.cmd("mv %s/**/Dark-Olympic %s/", tmp_folder, themes_dir)
  mng.recursive_remove(tmp_archive, tmp_folder)
  return true
end

--- @param str string
--- @return string[]
mng.tokenize = function(str)
  return stringx.split(stringx.strip(str), "%s+")
end

--- @class cli_args
--- @field clean boolean
--- @field light boolean
--- @field module string?
--- @field verbose boolean
--- @field no_sync boolean
--- @type cli_args
mng.cli_args = nil

--- @type string?
mng.user = nil

mng.exit_code = 0

return mng
