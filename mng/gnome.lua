local mng = require("mng")


local gnome = {}

gnome.gsettings = function(schema, key, value)
  if gnome.gsettings_get(schema, key) ~= value then
    gnome.gsettings_set(schema, key, value)
  end
end

gnome.gsettings_get = function(schema, key)
  return mng.cmd_read("dbus-launch gsettings get %s %s", schema, key)
end

gnome.gsettings_set = function(schema, key, value)
  return mng.cmd_read("dbus-launch gsettings set %s %s %s", schema, key, value)
end

return gnome
