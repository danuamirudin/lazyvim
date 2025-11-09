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
      vim.cmd("silent! write")
      -- Trigger SFTP upload after autosave (notification handled by sftp module)
      sftp.upload(filepath)
    end
  end,
})
