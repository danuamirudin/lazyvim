-- SFTP Upload Module
-- Shared function for uploading files to SFTP server

local M = {}

-- Helper function to extract project info from path
local function get_project_info(filepath)
  local patterns = {
    "(/Users/[^/]+/project/[^/]+/([^/]+))/", -- /Users/*/project/*/PROJECT_NAME/
    "(/Users/[^/]+/project/([^/]+))/", -- /Users/*/project/PROJECT_NAME/
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
    "curl -X POST http://localhost:8765%s -H 'Content-Type: application/json' -d @%s 2>&1 && rm %s",
    endpoint,
    tmpfile,
    tmpfile
  )

  vim.fn.jobstart(curl_cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data and #data > 0 then
        local response = table.concat(data, "\n")
        if callback then
          callback(response)
        end
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code ~= 0 and callback then
        callback(nil, "Request failed")
      end
    end,
  })
end

-- Main SFTP upload function
function M.upload(filepath)
  local project_root, base_root = get_project_info(filepath)

  if not base_root then
    return
  end

  print(string.format("[SFTP] Project: %s, File: %s", base_root, vim.fn.fnamemodify(filepath, ":t")))

  call_server("/upload", {
    base_root = base_root,
    file_path = filepath,
  }, function(response, err)
    if err then
      print(string.format("[SFTP] Upload failed: %s", err))
    end
  end)
end

-- Upload folder
function M.upload_folder(folderpath)
  if not folderpath or folderpath == "" then
    print("[SFTP] No folder path provided")
    return
  end

  local project_root, base_root = get_project_info(folderpath)

  if not base_root then
    print("[SFTP] Not in a registered project")
    return
  end

  print(string.format("[SFTP] Uploading folder: %s", folderpath))

  call_server("/upload-folder", {
    base_root = base_root,
    folder_path = folderpath,
  }, function(response, err)
    if err then
      print(string.format("[SFTP] Folder upload failed: %s", err))
    else
      print(string.format("[SFTP] Folder uploaded successfully: %s", folderpath))
    end
  end)
end

-- Download file
function M.download_file(filepath)
  if not filepath or filepath == "" then
    print("[SFTP] No file path provided")
    return
  end

  local project_root, base_root = get_project_info(filepath)

  if not base_root then
    print("[SFTP] Not in a registered project")
    return
  end

  print(string.format("[SFTP] Downloading file: %s", vim.fn.fnamemodify(filepath, ":t")))

  call_server("/download", {
    base_root = base_root,
    file_path = filepath,
  }, function(response, err)
    if err then
      print(string.format("[SFTP] Download failed: %s", err))
    else
      print(string.format("[SFTP] Downloaded: %s", filepath))
      -- Reload the buffer if it's currently open
      vim.cmd("checktime")
    end
  end)
end

-- Download folder
function M.download_folder(folderpath)
  if not folderpath or folderpath == "" then
    print("[SFTP] No folder path provided")
    return
  end

  local project_root, base_root = get_project_info(folderpath)

  if not base_root then
    print("[SFTP] Not in a registered project")
    return
  end

  print(string.format("[SFTP] Downloading folder: %s", folderpath))

  call_server("/download-folder", {
    base_root = base_root,
    folder_path = folderpath,
  }, function(response, err)
    if err then
      print(string.format("[SFTP] Folder download failed: %s", err))
    else
      print(string.format("[SFTP] Folder downloaded successfully: %s", folderpath))
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
    print("[SFTP] No file in current buffer")
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

return M
