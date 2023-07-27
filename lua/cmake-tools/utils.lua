local Path = require("plenary.path")
local Result = require("cmake-tools.result")
local Types = require("cmake-tools.types")
local config = require("cmake-tools.config")

local utils = {}

-- Get string representation for object o
function utils.dump(o)
  if type(o) == "table" then
    local s = "{ "
    for k, v in pairs(o) do
      if type(k) ~= "number" then
        k = '"' .. k .. '"'
      end
      s = s .. "[" .. k .. "] = " .. utils.dump(v) .. ","
    end
    return s .. "} "
  else
    return tostring(o)
  end
end

function utils.get_cmake_configuration()
  local cmakelists = Path:new(config.global.working_dir, "CMakeLists.txt")
  if not cmakelists:is_file() then
    return Result:new(
      Types.CANNOT_FIND_CMAKE_CONFIGURATION_FILE,
      nil,
      "Cannot find CMakeLists.txt at " .. config.global.working_dir .. " ."
    )
  end
  return Result:new(Types.SUCCESS, cmakelists, "cmake-tools has found CMakeLists.txt.")
end

function utils.get_path(str, sep)
  sep = sep or "/"
  return str:match("(.*" .. sep .. ")")
end

--- Execute CMake launch target in terminal.
---@param  executor executor.Adapter
-- @param  terminal cmake-tools.terminal
---@param executable string executable file
---@param full_cmd string full command line
-- @param opts execute options
function utils.execute(executor, terminal, executable, full_cmd)
  -- Please save all
  vim.cmd("silent exec " .. '"wall"')
  -- First, if we use some adapter to generate, build, etc, we should close it
  if executor ~= nil then
    executor:close()
  end
  -- Then, execute it
  terminal:execute(executable, full_cmd)
end

function utils.softlink(src, target, config)
  if config.executor.name == "terminal" and not utils.file_exists(target) then
    local cmd = "cmake -E create_symlink " .. src .. " " .. target
    config.terminal:run(cmd)
    return
  end

  if utils.file_exists(src) and not utils.file_exists(target) then
    -- if we don't always use terminal
    local cmd = "silent exec " .. '"!cmake -E create_symlink ' .. src .. " " .. target .. '"'
    vim.cmd(cmd)
  end
end

function utils.deepcopy(orig, copies)
  copies = copies or {}
  local orig_type = type(orig)
  local copy
  if orig_type == "table" then
    if copies[orig] then
      copy = copies[orig]
    else
      copy = {}
      copies[orig] = copy
      for orig_key, orig_value in next, orig, nil do
        copy[utils.deepcopy(orig_key, copies)] = utils.deepcopy(orig_value, copies)
      end
      setmetatable(copy, utils.deepcopy(getmetatable(orig), copies))
    end
  else -- number, string, boolean, etc
    copy = orig
  end
  return copy
end

-- Execute CMake command using job api
---@param executor executor.Adapter
---@param cmd string
---@param env table
---@param args table
---@param working_dir string
---@param on_success function
function utils.run(executor, cmd, env, args, working_dir, on_success)
  -- save all
  vim.cmd("wall")
  executor:run(cmd, env, args, working_dir, on_success)
end

function utils.mkdir(dir)
  local _dir = Path:new(dir)
  _dir:mkdir({ parents = true, exists_ok = true })
end

function utils.rmdir(dir)
  local _dir = Path:new(config.working_dir, dir)
  if _dir:exists() then
    _dir:rm({ recursive = true })
  end
end

function utils.file_exists(path)
  local file = Path:new(path)
  if not file:exists() then
    return false
  end
  return true
end

return utils
