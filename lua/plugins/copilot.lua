return {
  -- GitHub Copilot
  {
    "github/copilot.vim",
    config = function()
      -- Optional: map commands for easier use
      vim.g.copilot_no_tab_map = true -- disable default <Tab> mapping
      -- vim.api.nvim_set_keymap("i", "<C-J>", 'copilot#Accept("<CR>")', { expr = true, silent = true })
    end,
  },
}
