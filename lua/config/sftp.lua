-- SFTP Upload Module
-- Shared function for uploading files to SFTP server

local M = {}

-- Main SFTP upload function
function M.upload(filepath)
  -- Extract project name from path
  local patterns = {
    "(/Users/[^/]+/project/[^/]+/([^/]+))/", -- /Users/*/project/*/PROJECT_NAME/
    "(/Users/[^/]+/project/([^/]+))/", -- /Users/*/project/PROJECT_NAME/
  }

  local project_root = nil
  local base_root = nil

  for _, pattern in ipairs(patterns) do
    local root, name = filepath:match(pattern)
    if root and name then
      project_root = root
      base_root = name
      break
    end
  end

  if not base_root then
    -- Not in a recognized project structure, skip
    return
  end

  -- Debug: print when upload is triggered
  print(string.format("[SFTP] Project: %s, File: %s", base_root, vim.fn.fnamemodify(filepath, ":t")))

  -- Create temp file with JSON payload
  local tmpfile = vim.fn.tempname()
  local payload = vim.fn.json_encode({
    base_root = base_root,
    file_path = filepath,
  })

  vim.fn.writefile({ payload }, tmpfile)

  -- Use curl to upload
  local curl_cmd = string.format(
    "curl -X POST http://localhost:8765/upload -H 'Content-Type: application/json' -d @%s 2>&1 | tail -1 && rm %s &",
    tmpfile,
    tmpfile
  )

  vim.fn.jobstart(curl_cmd, {
    on_exit = function(_, exit_code)
      if exit_code ~= 0 then
        print(string.format("[SFTP] Upload failed for: %s", filepath))
      end
    end,
  })
end

return M
