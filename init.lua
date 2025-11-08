-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Load saved theme
vim.defer_fn(function()
  require("config.themes").load_theme()
end, 100)
