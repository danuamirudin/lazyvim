-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Load default settings
require("config.default")

-- Load saved theme
require("config.themes").load_theme()

-- Load custom highlights
require("config.highlights")

-- SFTP Upload on Save
local sftp = require("config.sftp")

-- Auto-start SFTP listener (will restart if already running)
sftp.auto_start()

-- Suppress write messages
vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("suppress_write_msg", { clear = true }),
  pattern = "*",
  callback = function()
    vim.opt_local.shortmess:append("W")
  end,
})

-- Create an autocommand group
local group = vim.api.nvim_create_augroup("SFTPUpload", { clear = true })

-- Trigger on BufWritePost (after file is saved) for ALL files
vim.api.nvim_create_autocmd("BufWritePost", {
  group = group,
  pattern = "*",
  callback = function()
    local filepath = vim.fn.expand("%:p")
    local filename = vim.fn.expand("%:t")
    
    -- Clear command line and show custom save message
    vim.schedule(function()
      vim.api.nvim_command("redraw")
      if filename ~= "" then
        vim.notify("💾 " .. filename, vim.log.levels.INFO)
      end
    end)
    
    sftp.upload(filepath)
  end,
})

vim.notify("✓ SFTP upload on save enabled (auto-detect projects)")
