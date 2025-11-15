-- ~/.config/nvim/lua/plugins/git-conflict.lua
return {
  "akinsho/git-conflict.nvim",
  version = "*",
  lazy = false,  -- Load immediately on startup
  priority = 1000,  -- Load early
  config = function()
    require("git-conflict").setup({
      default_mappings = false,  -- Disable default mappings to avoid operator-pending conflict
      default_commands = true,  -- Enable commands
      disable_diagnostics = false,
      list_opener = 'copen',
      highlights = {
        incoming = 'DiffAdd',
        current = 'DiffText',
      }
    })
    
    -- Custom mappings that don't conflict with Vim's change operator
    -- Using <leader>h prefix (h for "handle conflict" or "HEAD")
    vim.keymap.set('n', '<leader>ho', '<Plug>(git-conflict-ours)', { desc = 'Git: Choose Ours (HEAD)' })
    vim.keymap.set('n', '<leader>ht', '<Plug>(git-conflict-theirs)', { desc = 'Git: Choose Theirs (incoming)' })
    vim.keymap.set('n', '<leader>hb', '<Plug>(git-conflict-both)', { desc = 'Git: Choose Both' })
    vim.keymap.set('n', '<leader>h0', '<Plug>(git-conflict-none)', { desc = 'Git: Choose None' })
    vim.keymap.set('n', '<leader>hn', '<Plug>(git-conflict-next-conflict)', { desc = 'Git: Next Conflict' })
    vim.keymap.set('n', '<leader>hp', '<Plug>(git-conflict-prev-conflict)', { desc = 'Git: Prev Conflict' })
    
    -- Alternative: Use ']' prefix for conflict navigation (similar to ]x, [x)
    vim.keymap.set('n', ']c', '<Plug>(git-conflict-next-conflict)', { desc = 'Next Conflict' })
    vim.keymap.set('n', '[c', '<Plug>(git-conflict-prev-conflict)', { desc = 'Prev Conflict' })
    
    -- Global commands available anywhere:
    -- :GitConflictChooseOurs
    -- :GitConflictChooseTheirs
    -- :GitConflictChooseBoth
    -- :GitConflictChooseNone
    -- :GitConflictListQf - list all conflicts in quickfix
    -- :GitConflictRefresh - manually trigger conflict detection
  end,
}
