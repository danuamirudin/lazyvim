-- SFTP Upload Module
-- Shared function for uploading files to SFTP server

local M = {}

-- Configuration
M.config = {
  auto_start = false, -- Set to false to disable auto-start
  listener_path = vim.fn.stdpath("config") .. "/sftp-listener",
  config_path = vim.fn.stdpath("config") .. "/sftp-listener.json",
  pid_file = vim.fn.stdpath("config") .. "/.sftp-listener.pid",
  log_file = vim.fn.stdpath("config") .. "/sftp-listener.log",
}

-- Progress notification helper using fidget.nvim
local progress_handles = {}

local function show_progress(key, message)
  local ok, fidget = pcall(require, "fidget")
  if ok then
    progress_handles[key] = fidget.progress.handle.create({
      title = "SFTP",
      message = message,
      lsp_client = { name = "sftp-listener" },
    })
  else
    vim.notify(message, vim.log.levels.INFO)
  end
end

local function hide_progress(key)
  if progress_handles[key] then
    progress_handles[key]:finish()
    progress_handles[key] = nil
  end
end

-- Helper function to extract project info from path
local function get_project_info(filepath)
  -- First, use current working directory as the base
  local cwd = vim.fn.getcwd()

  -- Try to get workspace name
  local ok, workspaces = pcall(require, "workspaces")
  if ok then
    local workspace_name = workspaces.name()
    if workspace_name and workspace_name ~= "" then
      local workspace_path = workspaces.path()
      if workspace_path then
        return workspace_path, workspace_name
      end
    end
  end

  -- Fallback: Use cwd if file is within it
  if filepath:sub(1, #cwd) == cwd then
    local name = vim.fn.fnamemodify(cwd, ":t")
    return cwd, name
  end

  -- Fallback to pattern matching on filepath
  local patterns = {
    "(/Users/[^/]+/project/[^/]+/([^/]+))/", -- /Users/*/project/*/PROJECT_NAME/
    "(/Users/[^/]+/project/([^/]+))/", -- /Users/*/project/PROJECT_NAME/
    "(/Users/[^/]+/%.config/([^/]+))/", -- /Users/*/.config/PROJECT_NAME/
  }

  for _, pattern in ipairs(patterns) do
    local root, name = filepath:match(pattern)
    if root and name then
      return root, name
    end
  end

  return nil, nil
end

-- Helper function to call Go server
local function call_server(endpoint, payload, callback)
  local tmpfile = vim.fn.tempname()
  local json_data = vim.fn.json_encode(payload)
  vim.fn.writefile({ json_data }, tmpfile)

  local curl_cmd = string.format(
    "curl -s -X POST http://localhost:8765%s -H 'Content-Type: application/json' -d @%s 2>&1 && rm %s",
    endpoint,
    tmpfile,
    tmpfile
  )

  vim.fn.jobstart(curl_cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data and #data > 0 then
        local response = table.concat(data, "\n"):gsub("^%s*(.-)%s*$", "%1")
        if response ~= "" then
          -- Try to parse JSON response
          local ok, json_response = pcall(vim.fn.json_decode, response)
          if ok and json_response then
            if callback then
              callback(json_response, nil)
            end
          else
            -- Not JSON, pass raw response
            if callback then
              callback(response, nil)
            end
          end
        end
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code ~= 0 and callback then
        callback(nil, "Request failed with exit code: " .. exit_code)
      end
    end,
  })
end

-- Main SFTP upload function
function M.upload(filepath)
  -- Get current working directory
  local cwd = vim.fn.getcwd()

  -- Check if file is within current workspace
  if filepath:sub(1, #cwd) ~= cwd or M.is_running() == false then
    -- File is from a different workspace, skip silently
    return
  end

  local project_root, base_root = get_project_info(filepath)

  if not base_root then
    return
  end

  local filename = vim.fn.fnamemodify(filepath, ":t")
  show_progress("upload_file", "Uploading " .. filename .. "...")

  call_server("/upload", {
    base_root = base_root,
    file_path = filepath,
  }, function(response, err)
    hide_progress("upload_file")
    if err then
      vim.notify("SFTP ❌ " .. err, vim.log.levels.ERROR)
    elseif response then
      if type(response) == "table" then
        if response.success then
          vim.notify("SFTP ✓ " .. filename, vim.log.levels.INFO)
        else
          vim.notify("SFTP ❌ " .. (response.message or "failed"), vim.log.levels.ERROR)
        end
      end
    end
  end)
end

-- Upload folder
function M.upload_folder(folderpath)
  if not folderpath or folderpath == "" then
    return
  end

  local project_root, base_root = get_project_info(folderpath)

  if not base_root then
    return
  end

  show_progress("upload_folder", "Uploading folder...")

  call_server("/upload-folder", {
    base_root = base_root,
    folder_path = folderpath,
  }, function(response, err)
    hide_progress("upload_folder")
    if err then
      vim.notify("SFTP ❌ " .. err, vim.log.levels.ERROR)
    elseif response then
      if type(response) == "table" then
        if response.success then
          vim.notify("✓ Folder uploaded", vim.log.levels.INFO)
        else
          vim.notify("SFTP ❌ " .. (response.message or "failed"), vim.log.levels.ERROR)
        end
      end
    end
  end)
end

-- Download file
function M.download_file(filepath)
  if not filepath or filepath == "" then
    return
  end

  local project_root, base_root = get_project_info(filepath)

  if not base_root then
    return
  end

  show_progress("download_file", "Downloading...")

  call_server("/download", {
    base_root = base_root,
    file_path = filepath,
  }, function(response, err)
    hide_progress("download_file")
    if err then
      vim.notify("SFTP ❌ " .. err, vim.log.levels.ERROR)
    elseif response then
      if type(response) == "table" then
        if response.success then
          vim.notify("✓ Downloaded", vim.log.levels.INFO)
          vim.cmd("checktime")
        else
          vim.notify("SFTP ❌ " .. (response.message or "failed"), vim.log.levels.ERROR)
        end
      else
        vim.cmd("checktime")
      end
    end
  end)
end

-- Download folder
function M.download_folder(folderpath)
  if not folderpath or folderpath == "" then
    vim.notify("[SFTP] No folder path provided", vim.log.levels.WARN)
    return
  end

  local project_root, base_root = get_project_info(folderpath)

  if not base_root then
    vim.notify("[SFTP] Not in a registered project", vim.log.levels.WARN)
    return
  end

  show_progress("download_folder", "Downloading folder...")

  call_server("/download-folder", {
    base_root = base_root,
    folder_path = folderpath,
  }, function(response, err)
    hide_progress("download_folder")
    if err then
      vim.notify("[SFTP] ❌ " .. err, vim.log.levels.ERROR)
    elseif response then
      if type(response) == "table" then
        if response.success then
          vim.notify("[SFTP] ✓ " .. (response.message or "Folder downloaded"), vim.log.levels.INFO)
        else
          vim.notify("[SFTP] ❌ " .. (response.message or "Folder download failed"), vim.log.levels.ERROR)
        end
      else
        vim.notify("[SFTP] " .. tostring(response), vim.log.levels.INFO)
      end
    end
  end)
end

-- Command to upload current buffer's folder
function M.upload_folder_prompt()
  local current_file = vim.fn.expand("%:p")
  local current_dir = vim.fn.expand("%:p:h")

  vim.ui.input({
    prompt = "Upload folder path: ",
    default = current_dir,
    completion = "dir",
  }, function(input)
    if input then
      M.upload_folder(input)
    end
  end)
end

-- Command to download current buffer
function M.download_current_buffer()
  local filepath = vim.fn.expand("%:p")
  if filepath == "" then
    vim.notify("[SFTP] No file in current buffer")
    return
  end
  M.download_file(filepath)
end

-- Command to download folder with prompt
function M.download_folder_prompt()
  local current_dir = vim.fn.expand("%:p:h")

  vim.ui.input({
    prompt = "Download folder path: ",
    default = current_dir,
    completion = "dir",
  }, function(input)
    if input then
      M.download_folder(input)
    end
  end)
end

-- Check if listener is running
function M.is_running()
  -- First check by port (most reliable)
  local port_check = vim.fn.system("lsof -i :8765 -sTCP:LISTEN | grep -v COMMAND")
  if port_check and port_check ~= "" then
    return true
  end

  -- Fallback to PID file check
  local pid_file = M.config.pid_file
  if vim.fn.filereadable(pid_file) == 1 then
    local lines = vim.fn.readfile(pid_file)
    if lines and #lines > 0 then
      local pid = lines[1]
      if pid and pid ~= "" then
        local result = vim.fn.system("ps -p " .. pid .. " > /dev/null 2>&1; echo $?")
        local exit_code = result:match("%d+")
        if exit_code then
          return tonumber(exit_code) == 0
        end
      end
    end
  end
  return false
end

-- Start the SFTP listener
function M.start()
  if M.is_running() then
    return
  end

  local listener_bin = M.config.listener_path .. "/sftp-listener"
  if vim.fn.executable(listener_bin) ~= 1 then
    vim.notify("SFTP ❌ Binary not found", vim.log.levels.ERROR)
    return
  end

  -- Check if config exists in nvim folder, if not copy from listener folder
  if vim.fn.filereadable(M.config.config_path) ~= 1 then
    local source_config = M.config.listener_path .. "/sftp-listener.json"
    if vim.fn.filereadable(source_config) == 1 then
      vim.fn.system(string.format("cp '%s' '%s'", source_config, M.config.config_path))
    else
      vim.notify("SFTP ❌ No config found", vim.log.levels.ERROR)
      return
    end
  end

  -- Start listener with config from nvim folder
  local cmd = string.format(
    "cd '%s' && CONFIG_PATH='%s' nohup '%s' > '%s' 2>&1 & echo $!",
    M.config.listener_path,
    M.config.config_path,
    listener_bin,
    M.config.log_file
  )

  local pid = vim.fn.system(cmd):gsub("%s+", "")
  if pid and pid ~= "" then
    vim.fn.writefile({ pid }, M.config.pid_file)
    -- Silent start - only show error if it fails
    vim.defer_fn(function()
      if not M.is_running() then
        vim.notify("SFTP ❌ Failed to start", vim.log.levels.ERROR)
      else
        vim.notify("✓ SFTP upload on save enabled (auto-detect projects)", vim.log.levels.INFO)
      end
    end, 500)
  else
    vim.notify("SFTP ❌ Failed to start", vim.log.levels.ERROR)
  end
end

-- Restart the SFTP listener
function M.restart()
  if M.is_running() then
    M.stop()
    -- Wait longer for process to fully stop and port to be released
    vim.defer_fn(function()
      M.start()
    end, 1500)
  else
    M.start()
  end
end

-- Stop the SFTP listener
function M.stop()
  -- Kill by port if PID file is missing or stale
  local killed_by_port = false
  local pid_to_kill = vim.fn.system("lsof -ti :8765 2>/dev/null"):gsub("%s+", "")
  if pid_to_kill and pid_to_kill ~= "" then
    vim.fn.system("kill " .. pid_to_kill)
    killed_by_port = true
  end

  -- Also try PID file
  local pid_file = M.config.pid_file
  if vim.fn.filereadable(pid_file) == 1 then
    local lines = vim.fn.readfile(pid_file)
    if lines and #lines > 0 then
      local pid = lines[1]
      if pid and pid ~= "" and pid ~= pid_to_kill then
        vim.fn.system("kill " .. pid)
      end
    end
  end

  if killed_by_port then
    -- Wait for process to actually stop
    vim.fn.system("sleep 0.5")
    vim.fn.delete(pid_file)
    vim.notify("✓ SFTP listener stopped", vim.log.levels.INFO)
  end
end

-- Toggle listener on/off
function M.toggle()
  if M.is_running() then
    M.stop()
  else
    M.start()
  end
end

-- Auto-start listener if configured
function M.auto_start()
  if M.config.auto_start then
    M.restart()
  else
    M.stop()
  end
end

-- Check if this is the last nvim instance
local function is_last_nvim_instance()
  local count = vim.fn.system("pgrep -f 'nvim' | wc -l"):gsub("%s+", "")
  return tonumber(count) <= 1
end

-- Stop listener when last nvim exits
function M.auto_stop()
  if M.is_running() and is_last_nvim_instance() then
    M.stop()
  end
end

-- Reload SFTP config (useful when switching workspaces)
function M.reload_config()
  -- The config is read dynamically each time, so just notify
  vim.schedule(function()
    local cwd = vim.fn.getcwd()
    -- Silent reload - no notification needed
  end)
end

return M
