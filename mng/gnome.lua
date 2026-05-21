local mng = require("mng")


local gnome = {}

gnome.on = function()
  mng.package("gnome pipewire")
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
  return mng.cmd_read("dbus-launch gsettings set %s %s %s", schema, key, mng.cmd_quote(value))
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

return gnome
