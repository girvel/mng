local stringx = require("mng.lib.stringx")
local tablex = require("mng.lib.tablex")


local cli = {}

local cli_name
local cli_description
local cli_seen = {}

--- @param name string
--- @param description string
cli.define = function(name, description)
  cli_name = name
  cli_description = description
end

--- @param hide_description boolean?
cli.help = function(hide_description)
  if cli_name then
    if not hide_description then print(cli_description) end
    io.write("USAGE: "..cli_name)
  else
    io.write("USAGE: <FILENAME>")
  end

  local prev_type
  for _, param in ipairs(cli_seen) do
    if param.type == "command" then
      io.write(" <command>")
    elseif param.type ~= prev_type then
      io.write(" <"..param.type.."s>")
    end

    prev_type = param.type
  end
  print()

  prev_type = nil
  for _, param in ipairs(cli_seen) do
    if param.type == "command" then
      print()
      print("COMMAND:")
      for v, desc in pairs(param.possible_values) do
        print("  "..v..": "..desc);
      end
    else
      if param.type ~= prev_type then
        print()
        print(param.type:upper().."S:")
      end

      if param.description then
        print("  "..param.notation..": "..param.description)
      else
        print("  "..param.notation)
      end
    end
    prev_type = param.type
  end
end

-- TODO move internals to mng.utils
--- @param args string[]
--- @param possible_values table<string, string>
--- @param default string?
--- @return string?
cli.command = function(args, possible_values, default)
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

--- @param args string[]
--- @param notation string
--- @param description? string
--- @return boolean
cli.flag = function(args, notation, description)
  notation = stringx.strip(notation)
  local notations = stringx.split(notation, "%s+")
  table.insert(cli_seen, {type = "flag", notation = notation, description = description})

  for i, arg in ipairs(args) do
    if stringx.starts_with(arg, "--") then
      if tablex.first_index(notations, arg) then
        table.remove(args, i)
        return true
      end
    elseif stringx.starts_with(arg, "-") then
      for j = 1, #arg do
        local char = arg:sub(j, j)
        if tablex.first_index(notations, "-"..char) then
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

--- @param args string[]
--- @param notation string
--- @param description? string
--- @return string? value
cli.option = function(args, notation, description)
  notation = stringx.strip(notation)
  local notations = stringx.split(notation, "%s+")
  table.insert(cli_seen, {type = "option", notation = notation, description = description})

  for _, this_notation in ipairs(notations) do
    local is_short = not not this_notation:match("^-[^-]")
    for i, arg in ipairs(args) do
      if not stringx.starts_with(arg, this_notation) then goto continue end
      if stringx.char(arg, #this_notation + 1) == "=" then
        table.remove(args, i)
        return arg:sub(#this_notation + 2)
      end

      if #arg == #this_notation then
        table.remove(args, i)
        local result = table.remove(args, i)
        if not result then
          print("Missing value for the option "..arg)
          os.exit(1)
        end
        return result
      end

      if is_short then
        table.remove(args, i)
        return arg:sub(#this_notation + 1)
      end

      ::continue::
    end
  end
  return nil
end

--- @param args string[]
cli.check_remainder = function(args)
  if #args == 0 then return end
  io.write("Unexpected args:")
  for _, arg in ipairs(args) do
    io.write(" "..arg)
  end
  io.write("\n\n")
  cli.help(true)
  os.exit(1)
end

return cli
