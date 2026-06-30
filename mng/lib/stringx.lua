local stringx = {}

--- @param str string
--- @param pat string
--- @param plain boolean?
--- @return string[]
--- @nodiscard
stringx.split = function(str, pat, plain)
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
--- @nodiscard
stringx.join = function(arr, sep)
  if #arr == 0 then return "" end
  local result = arr[1]
  for i = 2, #arr do
    result = result.." "..arr[i]
  end
  return result
end

--- @param str string
--- @return string
--- @nodiscard
stringx.strip = function(str)
  return select(1, str:gsub("^%s+", ""):gsub("%s+$", ""))
end

--- @param str string
--- @param prefix string
--- @return boolean
--- @nodiscard
stringx.starts_with = function(str, prefix)
  return str:sub(1, #prefix) == prefix
end

--- @param str string
--- @param postfix string
--- @return boolean
--- @nodiscard
stringx.ends_with = function(str, postfix)
  return str:sub(-#postfix) == postfix
end

--- @param str string
--- @param i integer
--- @return string
--- @nodiscard
stringx.char = function(str, i)
  return str:sub(i, i)
end

return stringx
