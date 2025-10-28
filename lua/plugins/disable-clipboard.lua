return {
  {
    "LazyVim/LazyVim",
    opts = function(_, opts)
      -- forcefully clear clipboard options
      vim.opt.clipboard = ""
      -- if something re-sets it later, reapply after 1 second
      vim.defer_fn(function()
        vim.opt.clipboard = ""
      end, 1000)
    end,
  },
  -- disable yanky.nvim if it’s loaded (this often re-enables unnamedplus)
  { "gbprod/yanky.nvim", enabled = false },
  -- disable OSC52 clipboard sync
  { "ojroques/nvim-osc52", enabled = false },
}
