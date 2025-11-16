-- Custom highlight groups for better syntax highlighting
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    -- Variables
    vim.api.nvim_set_hl(0, "@variable", { link = "Identifier" })
    vim.api.nvim_set_hl(0, "@variable.builtin", { link = "Special" })
    vim.api.nvim_set_hl(0, "@variable.parameter", { link = "Identifier" })
    vim.api.nvim_set_hl(0, "@variable.member", { link = "Identifier" })
    
    -- Cursor and line number colors
    local bg = vim.o.background
    local yellow = bg == "light" and "#8B7500" or "#FFFF00"
    
    -- Yellow cursor (GUI)
    vim.api.nvim_set_hl(0, "Cursor", { fg = "#000000", bg = yellow })
    vim.api.nvim_set_hl(0, "lCursor", { fg = "#000000", bg = yellow })
    vim.api.nvim_set_hl(0, "CursorIM", { fg = "#000000", bg = yellow })
    vim.api.nvim_set_hl(0, "TermCursor", { bg = yellow })
    vim.api.nvim_set_hl(0, "TermCursorNC", { bg = yellow })
    
    -- Set terminal cursor color using escape sequences
    if vim.fn.has("termguicolors") == 1 and os.getenv("TERM") ~= "linux" then
      vim.cmd(string.format([[silent! call chansend(v:stderr, "\033]12;%s\007")]], yellow))
    end
    
    -- Yellow current line number
    vim.api.nvim_set_hl(0, "CursorLineNr", { fg = yellow, bold = true })
  end,
})

-- Apply immediately on startup
vim.defer_fn(function()
  vim.api.nvim_set_hl(0, "@variable", { link = "Identifier" })
  vim.api.nvim_set_hl(0, "@variable.builtin", { link = "Special" })
  vim.api.nvim_set_hl(0, "@variable.parameter", { link = "Identifier" })
  vim.api.nvim_set_hl(0, "@variable.member", { link = "Identifier" })
  
  -- Apply cursor and line number colors
  local bg = vim.o.background
  local yellow = bg == "light" and "#8B7500" or "#FFFF00"
  
  vim.api.nvim_set_hl(0, "Cursor", { fg = "#000000", bg = yellow })
  vim.api.nvim_set_hl(0, "lCursor", { fg = "#000000", bg = yellow })
  vim.api.nvim_set_hl(0, "CursorIM", { fg = "#000000", bg = yellow })
  vim.api.nvim_set_hl(0, "TermCursor", { bg = yellow })
  vim.api.nvim_set_hl(0, "TermCursorNC", { bg = yellow })
  vim.api.nvim_set_hl(0, "CursorLineNr", { fg = yellow, bold = true })
  
  -- Set terminal cursor color
  if vim.fn.has("termguicolors") == 1 and os.getenv("TERM") ~= "linux" then
    vim.cmd(string.format([[silent! call chansend(v:stderr, "\033]12;%s\007")]], yellow))
  end
end, 200)

-- Also set cursor color on VimEnter and when entering insert mode
vim.api.nvim_create_autocmd({"VimEnter", "InsertEnter", "InsertLeave"}, {
  callback = function()
    local bg = vim.o.background
    local yellow = bg == "light" and "#8B7500" or "#FFFF00"
    if vim.fn.has("termguicolors") == 1 and os.getenv("TERM") ~= "linux" then
      vim.cmd(string.format([[silent! call chansend(v:stderr, "\033]12;%s\007")]], yellow))
    end
  end,
})
