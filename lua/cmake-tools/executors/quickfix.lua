local log = require("cmake-tools.log")
local terminal = require("cmake-tools.executors.terminal")
local Job = require("plenary.job")

---@type executor.Adapter
local quickfix = {
  opts={},
  name="quickfix",
  job = nil
}

function quickfix:new(quickfix_opts)
  local new_obj = {opts=quickfix_opts}
  self.__index = self
  return setmetatable(new_obj, self)
end

function quickfix:show()
  vim.api.nvim_command(self.opts.position .. " copen " .. self.opts.size)
  vim.api.nvim_command("wincmd p")
end

function quickfix:close()
  vim.api.nvim_command("cclose")
end

function quickfix.scroll_to_bottom()
  vim.api.nvim_command("cbottom")
end

local function append_to_quickfix(error, data)
  local line = error and error or data
  vim.fn.setqflist({}, "a", { lines = { line } })
  -- scroll the quickfix buffer to bottom
  if quickfix.check_scroll() then
    quickfix.scroll_to_bottom()
  end
end

function quickfix:run(cmd, env, args, on_success)
  vim.fn.setqflist({}, " ", { title = cmd .. " " .. table.concat(args, " ") })
  if self.opts.show == "always" then
	self:show()
  end

  self.job = Job:new({
    command = cmd,
    args = next(env) and { "-E", "env", table.concat(env, " "), "cmake", unpack(args) } or args,
    cwd = vim.loop.cwd(),
    on_stdout = vim.schedule_wrap(append_to_quickfix),
    on_stderr = vim.schedule_wrap(append_to_quickfix),
    on_exit = vim.schedule_wrap(function(_, code, signal)
      append_to_quickfix("Exited with code " .. (signal == 0 and code or 128 + signal))
      if code == 0 and signal == 0 then
        if on_success then
          on_success()
        end
      elseif self.opts.show == "only_on_error" then
        self:show()
        quickfix.scroll_to_bottom()
      end
    end),
  })

  self.job:start()
  return quickfix.job
end


function quickfix:stop()
  quickfix.job:shutdown(1, 9)

  for _, pid in ipairs(vim.api.nvim_get_proc_children(self.job.pid)) do
    vim.loop.kill(pid, 9)
  end
end

function quickfix.check_scroll()
  local function is_cursor_at_last_line()
    local current_buf = vim.api.nvim_win_get_buf(0)
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local line_count = vim.api.nvim_buf_line_count(current_buf)

    return cursor_pos[1] == line_count - 1
  end

  local buffer_type = vim.api.nvim_buf_get_option(0, "buftype")

  if buffer_type == "quickfix" then
    return is_cursor_at_last_line()
  end

  return true
end

function quickfix:has_active_job()
  if terminal.has_active_job() then
	  return true
  end
  if not self.job or self.job.is_shutdown then
    return false
  end
  log.error(
    "A CMake task is already running: "
    .. self.job.command
    .. " Stop it before trying to run a new CMake task."
  )
  return true
end
return quickfix
