local log = require("cmake-tools.log")
local config = require("cmake-tools.config")
local overseer = require("overseer")

---@type executor.Adapter
local seer = {
  name = "overseer",
  opts = {},
  job = nil,
}

function seer:new(overseer_opts)
  local new_obj = { name = "overseer", opts = overseer_opts, job = nil }
  self.__index = self
  return setmetatable(new_obj, self)
end

function seer:show()
  overseer.open()
end

function seer:close()
  overseer.close()
end

function seer:run(cmd, env, args, cwd, on_success)
  local opts = vim.tbl_extend("keep", self.opts, {
    cmd = cmd,
    args = args,
    env = env,
    cwd = cwd,
  })
  seer.job = overseer.new_task(opts)
  self.job:subscribe("on_complete", on_success)
  self.job:start()

  return seer.job
end

function seer:stop()
  self.job:stop()
end

function seer:has_active_job()
  if config.terminal:has_active_job() then
    return true
  end
  if self.job ~= nil and self.job:is_running() then
    log.error(
      "A CMake task is already running: "
        .. self.job.command
        .. " Stop it before trying to run a new CMake task."
    )
    return true
  end
  return false
end
return seer
