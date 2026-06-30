local tablex = {}

--- @param t table
--- @param item any
--- @return integer?
--- @nodiscard
tablex.first_index = function(t, item)
  for i, e in ipairs(t) do
    if e == item then return i end
  end
end

return tablex
