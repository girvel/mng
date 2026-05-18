----------------------------------------------------------------------------------------------------
-- [SECTION] Internal tools
----------------------------------------------------------------------------------------------------

local is_installed = function(pkg)
  local f = assert(io.popen("xbps-query "..pkg.." -p state,automatic-install", "r"))
  local output = f:read("*a")
  f:close()
  return output == "installed\n"
end

local install = function(pkg)
  os.execute("xbps-install -yS "..pkg)
end

----------------------------------------------------------------------------------------------------
-- [SECTION] API
----------------------------------------------------------------------------------------------------

local mng = {}

mng.ensure_installed = function(pkg)
  if not is_installed(pkg) then
    install(pkg)
  end
end

mng.chsh = function(pkg)
  
end

return mng
