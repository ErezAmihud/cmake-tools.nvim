local executor = {}

---@class executor.Adapter
---@field name string
executor.Adapter = {}

---Set up an executor
---@param opts table options for this adapter
function executor.Adapter:new(opts) end

---Show the current executing command
---@return nil @Absolute root dir of test suite
function executor.Adapter:show() end

---Close the current executing command
---@return nil @Absolute root dir of test suite
function executor.Adapter:close() end

---Run a commond
---@param cmd string the executable to execute
---@param env table environment variables
---@param args table arguments to the executable
---@param on_success nil|function extra arguments, f.e on_success is a callback to be called when the process finishes
---@return nil
function executor.Adapter:run(cmd, env, args, on_success) end

---Checks if there is an active job
---@return boolean
function executor.Adapter:has_active_job() end

---Stop the active job
---@return nil
function executor.Adapter:stop() end
