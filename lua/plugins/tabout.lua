-- ~/.config/nvim/lua/plugins/tabout.lua
return {
  {
    "abecodes/tabout.nvim",
    event = "InsertCharPre",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-cmp" },
    config = function()
      require("tabout").setup({
        tabkey = "<Tab>", -- key to trigger tabout
        backwards_tabkey = "<S-Tab>",
        act_as_tab = true, -- if tab does not trigger completion
        completion = true, -- if using nvim-cmp
        ignore_beginning = true,
        tabouts = {
          { open = "'", close = "'" },
          { open = '"', close = '"' },
          { open = "`", close = "`" },
          { open = "(", close = ")" },
          { open = "[", close = "]" },
          { open = "{", close = "}" },
        },
      })
    end,
  },
}
