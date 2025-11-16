-- Or add blank lines in the buffer
vim.o.scrolloff = 8 -- vertical padding when moving cursor
vim.opt.cmdheight = 2 -- more space at the bottom
vim.g.autoformat = false

vim.opt.wrap = true
-- vim.opt.clipboard = "" -- don't use system clipboard by default

-- Enable true color support
vim.opt.termguicolors = true

-- Cursor settings
vim.opt.guicursor = "n-v-c:block-blinkwait700-blinkoff400-blinkon250,i-ci-ve:ver25-blinkwait700-blinkoff400-blinkon250,r-cr:hor20-blinkwait700-blinkoff400-blinkon250"
vim.opt.cursorline = true

-- Disable all animations
-- vim.g.snacks_animate = false

-- Additional animation disable for noice
-- vim.g.noice_animate = false


-- coloer highlights for git conflicts
vim.api.nvim_set_hl(0, "GitConflictCurrent", { bg = "#283848" })
vim.api.nvim_set_hl(0, "GitConflictIncoming", { bg = "#3a2a3a" })
vim.api.nvim_set_hl(0, "GitConflictAncestor", { bg = "#303030" })
vim.api.nvim_set_hl(0, "GitConflictSeparator", { fg = "#666666" })
