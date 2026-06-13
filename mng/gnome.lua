local mng = require("mng")


local gnome = {}

gnome.on = function()
  mng.package("gnome pipewire")
  mng.service_off("dhcpcd", "wpa_supplicant")
  mng.service_on("dbus", "NetworkManager", "gdm")
end

gnome.gsettings = function(schema, key, value)
  if gnome.gsettings_get(schema, key) ~= value then
    gnome.gsettings_set(schema, key, value)
  end
end

gnome.gsettings_get = function(schema, key)
  return mng.cmd_read("dbus-launch gsettings get %s %s", schema, key)
end

gnome.gsettings_set = function(schema, key, value)
  mng.cmd("dbus-launch gsettings set %s %s %s", schema, key, mng.cmd_quote(value))
end

gnome.shortcut = function(id, name, command, binding)
  local main_list = "org.gnome.settings-daemon.plugins.media-keys"
  local path_str = "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/"..id.."/"

  -- Ensure the shortcut is registered in the main list
  local list_str = gnome.gsettings_get(main_list, "custom-keybindings")
  if not list_str:find(path_str, 1, true) then
    local new_list
    if list_str == "@as []" then
      new_list = "['" .. path_str .. "']"
    else
      new_list = list_str:sub(1, -2) .. ", '" .. path_str .. "']"
    end
    gnome.gsettings_set(main_list, "custom-keybindings", new_list)
  end

  -- Set the parameters
  local item_schema = main_list..".custom-keybinding:"..path_str
  gnome.gsettings(item_schema, "name", "'" .. name .. "'")
  gnome.gsettings(item_schema, "command", "'" .. command .. "'")
  gnome.gsettings(item_schema, "binding", "'" .. binding .. "'")
end

local extension_sugar = function(id)
  local schemas_dir = mng.cmd_read("echo ~/.local/share/gnome-shell/extensions/%s/schemas", id)
  local schema = "org.gnome.shell.extensions."..id:match("^([^@]+)@")
  return {
    gsettings = function(self, key, value)
      if self:gsettings_get(key) ~= value then
        self:gsettings_set(key, value)
      end
      return self
    end,

    gsettings_get = function(self, key)
      return mng.cmd_read(
        "dbus-launch gsettings --schemadir %s get %s %s", schemas_dir, schema, key
      )
    end,

    gsettings_set = function(self, key, value)
      mng.cmd(
        "dbus-launch gsettings --schemadir %s set %s %s %s",
        schemas_dir, schema, key, mng.cmd_quote(value)
      )
    end,
  }
end

gnome.extension = function(id)
  local target_dir = "~/.local/share/gnome-shell/extensions/"..id
  if not mng.dir_exists(target_dir) then
    local gnome_version_major = assert(
      mng.cmd_read("gnome-shell --version"):match("GNOME Shell (%d+)%.%d+")
    )
    local url = ("https://extensions.gnome.org/extension-info/?uuid=%s&shell_version=%s"):format(
      id, gnome_version_major
    )
    local download_path = mng.cmd_read("curl -s %s | jq -r '.download_url'", mng.cmd_quote(url))
    if download_path == "" or download_path == "null" then
      error("Extension "..id.." not found for GNOME version "..gnome_version_major)
    end
    download_path = "https://extensions.gnome.org"..download_path

    mng.dir(target_dir)
    mng.cmd("curl -sL %s -o /tmp/gnome-extension.zip", mng.cmd_quote(download_path))
    mng.cmd("unzip -oq /tmp/gnome-extension.zip -d %s", target_dir)
    mng.cmd("rm /tmp/gnome-extension.zip")
    if mng.dir_exists(target_dir.."/schemas") then
      mng.cmd("glib-compile-schemas %s/schemas", target_dir)
    end
  end

  local schema = "org.gnome.shell"
  local key = "enabled-extensions"
  local list = gnome.gsettings_get(schema, key)

  if not list:find(id, 1, true) then
    local new_list
    if list == "@as []" or list == "[]" or list == "" then
      new_list = "['"..id.."']"
    else
      new_list = list:sub(1, -2)..", '"..id.."']"
    end
    gnome.gsettings_set(schema, key, new_list)
  end

  return extension_sugar(id)
end

return gnome
