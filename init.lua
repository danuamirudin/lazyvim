-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Load saved theme
vim.defer_fn(function()
  require("config.themes").load_theme()
end, 100)

-- Load custom highlights
require("config.highlights")

-- SFTP Upload on Save
local sftp = require("config.sftp")

-- Create an autocommand group
local group = vim.api.nvim_create_augroup("SFTPUpload", { clear = true })

-- Trigger on BufWritePost (after file is saved) for ALL files
vim.api.nvim_create_autocmd("BufWritePost", {
  group = group,
  pattern = "*",
  callback = function()
    local filepath = vim.fn.expand("%:p")
    sftp.upload(filepath)
  end,
})

print("✓ SFTP upload on save enabled (auto-detect projects)")
