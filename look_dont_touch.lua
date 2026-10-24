local inifile = require("inifile")

-- lookup table for configurable properties
local lookup = {
  display = {
    "width",
    "height",
    "samples",
    "update_frequency",
    "swap_interval",
    "vsync", },
  sound = {
    "gain",
    "use_linear_gain",
    "max_sound_data",
    "max_sound_buffers",
    "max_sound_sources",
    "max_sound_instances",
    "max_component_count",
    "sample_frame_count",
    "use_thread",
    "stream_enabled",
    "stream_chunk_size",
    "stream_preload_size",
    "stream_cache_size", },
}

local function get_subtable(ini_table, t_string, category)
  -- category must have at least one key left after game.properties `private = 1` filter
  if next(ini_table) then
    t_string = t_string .. "\n  " .. category .. " = {"
    for key, value in pairs(ini_table) do
      -- list keys
      local equals, comma = " = ", ","
      if type(value) == "string" then
        equals = " = \""
        comma = "\","
        value = value:sub(2)
      end
      t_string = t_string .. "\n    " .. key .. equals .. value .. comma
    end
    -- move to next table
    t_string = t_string .. "\n  },"
  end
  return t_string
end

local function projectc2lua(ini_table, path)
  -- write table to string
  local projectc_string = "return {"
  if next(ini_table) then
    for category, subtable in pairs(ini_table) do
      projectc_string = get_subtable(subtable, projectc_string, category)
    end
    -- add one more line break at end
    projectc_string = projectc_string .. "\n"
  end
  projectc_string = projectc_string .. "}"
  local consts_handle = io.open(path, "w")
  if consts_handle then
    consts_handle:write(projectc_string)
    consts_handle:close()
  else
    error("Could not write constants table at " .. path)
  end
end

local function debug(consts_path)
  local projectc_path = "build/default_bundle/game.projectc"
  -- check for file
  local projectc_handle, err = io.open(projectc_path, "r")
  local been_bundled = (projectc_handle ~= nil)
  if been_bundled then
    -- close io handle and open with inifile instead
    projectc_handle: close()
    -- write project constants to table module
    local projectc_table = inifile.parse(projectc_path, "io")
    projectc2lua(projectc_table, consts_path)
  else
    -- no /build/default_bundle/game.projectc file
    print(err .. ". Has the game been bundled at least once yet?")
  end
  return true
end

local function merge_setting(cfg, proj, c, k)
  -- make sure the user category/key exists
  if cfg[c] then
    if cfg[c][k] then
      proj[c][k] = cfg[c][k]
    end
  end
end

local function reboot(consts_table, passkey)
  local key = passkey:match("[^=]*")
  local pass = passkey:match("=(.*)")
  -- do not reboot more than once
  if sys.get_config_string(key, "INVALID") == pass then
    -- rebooted; expected project constants should be applied
    return true
  else
    -- copy module to table
    local project_table = sys.deserialize(sys.serialize(consts_table))
    local config_table = inifile.parse("game.projectc", "io")
    
    -- use lookup table to merge config
    for c, t in pairs(lookup) do
      for _, k in pairs(t) do
        merge_setting(config_table, project_table, c, k)
      end
    end
    
    -- write merged project file
    local session_handle = io.open(".projectc", "w")
    if session_handle then
      session_handle:close()
      -- use inifile to write it
      inifile.save(".projectc", project_table, "io")
      if sys.get_sys_info().system_name == "Windows" then os.execute("attrib +H \".projectc\"") end
      -- reboot engine with passkey & the new merged project file
      local arg1 = "--config=" .. passkey
      local argN = ".projectc"
      sys.reboot(arg1, argN)
    end
  end
  return false
end

return
--- DEBUG: Writes project settings to a Lua table at "consts_path".
--- RELEASE: Constructs a new .projectc-formatted file from "consts_table" and
--- the configuration in game.projectc, then reboots the game using the merged
--- configuration, passing the argument in "passkey".
--- @param consts_path string
--- @param consts_table table
--- @param passkey string
--- @return boolean rebooted
function(consts_path, consts_table, passkey)
  local rebooted = false
  if not sys.get_engine_info().is_debug then
    rebooted = reboot(consts_table, passkey)
  else
    rebooted = debug(consts_path)
  end
  return rebooted
end
