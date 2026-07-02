local inspect = require("mng.lib.inspect")
local docreader = require("mng.lib.docreader")

local mod = docreader.read_file(...)

io.write("# "..mod.name)
for _, record in ipairs(mod.records) do
  if record.type == "function" then
    --- @cast record record.function
    io.write("\n\n### `"..mod.name.."."..record.name.."`")
    io.write("\n\n```lua\n"..mod.name.."."..record.name.."(")
    for i, arg in ipairs(record.args) do
      if i > 1 then io.write(", ") end
      io.write(arg.name)
      if arg.type then
        io.write(": "..arg.type)
      end
    end
    io.write(")")
    if #record.returns > 0 then
      io.write(" -> ")
      for i, ret in ipairs(record.returns) do
        if i > 1 then io.write(", ") end
        if ret.name then
          io.write(ret.name..": ")
        end
        io.write(ret.type)
      end
    end
    io.write("\n```")

    if record.desc then
      io.write("\n\n"..record.desc)
    end

    local first_time = true
    for _, arg in ipairs(record.args) do
      if arg.desc then
        if first_time then
          io.write("\n\n#### Args\n")
          first_time = false
        end
        io.write("- `"..arg.name.."`: `"..arg.type.."` — "..arg.desc)
      end
    end

    first_time = true
    for _, ret in ipairs(record.returns) do
      if ret.desc then
        if first_time then
          io.write("\n\n#### Returns\n")
          first_time = false
        end
        io.write("- `")
        if ret.name then
          io.write(ret.name.."`: `")
        end
        io.write(ret.type.."` — "..ret.desc)
      end
    end
  elseif record.type == "section" then
    --- @cast record record.section
    io.write("\n\n## "..record.name)
  end
end
