-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Import shared SFTP module
local sftp = require("config.sftp")

-- Auto-start SFTP listener if configured
sftp.auto_start()

-- Auto-stop SFTP listener when last nvim exits
vim.api.nvim_create_autocmd("VimLeavePre", {
  group = vim.api.nvim_create_augroup("sftp_auto_stop", { clear = true }),
  callback = function()
    sftp.auto_stop()
  end,
})

vim.api.nvim_create_autocmd({ "FocusLost", "BufLeave", "WinLeave" }, {
  group = vim.api.nvim_create_augroup("autosave_on_focus_change", { clear = true }),
  callback = function()
    if vim.bo.modified and vim.bo.buflisted and vim.fn.expand("%") ~= "" then
      local filepath = vim.fn.expand("%:p")
      local cwd = vim.fn.getcwd()
      
      -- Only save if file is within current workspace
      if filepath:sub(1, #cwd) == cwd then
        local save_msg = vim.o.shortmess
        vim.o.shortmess = save_msg .. "F"
        vim.cmd("silent! write")
        vim.o.shortmess = save_msg
        -- Trigger SFTP upload after autosave (notification handled by sftp module)
        sftp.upload(filepath)
      end
    end
  end,
})

-- Auto-save session on exit
vim.api.nvim_create_autocmd("VimLeavePre", {
  group = vim.api.nvim_create_augroup("persistence_save", { clear = true }),
  callback = function()
    local ok, persistence = pcall(require, "persistence")
    if ok then
      persistence.save()
    end
  end,
})

-- Add a command to check current session
vim.api.nvim_create_user_command("SessionInfo", function()
  local ok, persistence = pcall(require, "persistence")
  if ok then
    local session_file = persistence.current()
    local cwd = vim.fn.getcwd()
    local exists = session_file and vim.fn.filereadable(session_file) == 1
    
    print("Current directory: " .. cwd)
    print("Session file: " .. (session_file or "none"))
    print("Session exists: " .. (exists and "yes" or "no"))
    
    if exists then
      local size = vim.fn.getfsize(session_file)
      print("Session size: " .. size .. " bytes")
    end
  else
    print("Persistence plugin not loaded")
  end
end, { desc = "Show session information" })

-- Add command to check workspace info
vim.api.nvim_create_user_command("WorkspaceInfo", function()
  local cwd = vim.fn.getcwd()
  print("Current directory: " .. cwd)
  
  local ok, workspaces = pcall(require, "workspaces")
  if ok then
    local name = workspaces.name()
    local path = workspaces.path()
    print("Workspace name: " .. (name or "none"))
    print("Workspace path: " .. (path or "none"))
  else
    print("Workspaces plugin not loaded")
  end
  
  -- Show current buffers
  print("\nOpen buffers:")
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local bufname = vim.api.nvim_buf_get_name(buf)
      if bufname ~= "" then
        local in_workspace = bufname:sub(1, #cwd) == cwd
        print("  " .. (in_workspace and "✓" or "✗") .. " " .. bufname)
      end
    end
  end
end, { desc = "Show workspace information" })

