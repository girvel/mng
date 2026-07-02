local stringx = require("mng.lib.stringx")


local docreader = {}

--- @class record.function.arg
--- @field name string
--- @field type? string
--- @field desc? string

--- @class record.function.return
--- @field type string
--- @field name? string
--- @field desc? string

--- @class record.function
--- @field type "function"
--- @field name string
--- @field desc? string
--- @field args record.function.arg[]
--- @field returns record.function.return[]
--- @field nodiscard true?

--- @param doc_lines string[]
--- @param function_name string
--- @param args string
--- @return record.function
local parse_function = function(doc_lines, function_name, args)
  local args_info = {}
  local args_by_name = {}
  for _, arg in ipairs(stringx.split(args, ",%s*")) do
    table.insert(args_info, {name = arg})
    args_by_name[arg] = args_info[#args_info]
  end

  local nodiscard
  local returns = {}
  --- @type string?
  local function_desc = ""
  for _, line in ipairs(doc_lines) do
    local param, qmark, type, desc = line:match("^@param ([^%s?]+)(%??) (%S+)(.*)$")
    if param then
      type = type..qmark
      args_by_name[param].type = type
      if #desc > 0 then
        args_by_name[param].desc = desc:sub(2)
      end
      goto continue
    end

    local _, j, rettype = line:find("^@return (%S+)")
    if rettype then
      local this_return = {type = rettype}
      local _, j1, name = line:find("^%s+(%S+)", j + 1)
      if name then
        this_return.name = name
        desc = stringx.strip(line:sub(j1 + 1))
        if #desc > 0 then
          this_return.desc = desc
        end
      end
      table.insert(returns, this_return)
      goto continue
    end

    if stringx.strip(line) == "@nodiscard" then
      nodiscard = true
      goto continue
    end

    if stringx.char(line, 1) ~= "@" then
      if stringx.strip(line) == "" then
        function_desc = function_desc.."\n\n"
      else
        function_desc = function_desc..line
      end
      goto continue
    end

    print(line)

    ::continue::
  end

  if #function_desc == 0 then function_desc = nil end

  return {
    type = "function",
    name = function_name,
    desc = function_desc,
    args = args_info,
    returns = returns,
    nodiscard = nodiscard,
  }
end

--- @class record.section
--- @field type "section"
--- @field name string

--- @alias record record.function|record.section

--- @class module
--- @field name string
--- @field records record[]

--- @param path string
--- @return module
docreader.read_file = function(path)
  --- @type string
  local content do
    local f = assert(io.open(path, "r"))
    content = f:read("*a")
    f:close()
  end

  assert(stringx.ends_with(path, ".lua"))
  local modname = assert(path:match("([^/]+)%.lua"))

  local records = {}
  local doc_lines = {}
  for _, line in ipairs(stringx.split(content, "\n")) do
    local function_name, args

    if stringx.starts_with(line, "--- ") then
      table.insert(doc_lines, line:sub(5))
      goto continue
    end

    -- TODO parse section descriptions
    if stringx.starts_with(line, "--- [SECTION] ") then
      local record = {type = "section", name = line:sub(15)}
      if #records > 0 and records[#records].type == "section" then
        records[#records] = record  -- to avoid empty sections
      else
        table.insert(records, record)
      end
      goto reset
    end

    function_name, args = line:match("^"..modname.."%.(%S+) = function%(([^)]*)%)")
    if function_name then
      table.insert(records, parse_function(doc_lines, function_name, args))
      goto reset
    end

    ::reset::
    doc_lines = {}

    ::continue::
  end

  return {
    name = modname,
    records = records,
  }
end

return docreader
