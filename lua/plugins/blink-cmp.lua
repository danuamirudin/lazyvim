return {
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      opts.keymap = opts.keymap or {}
      opts.keymap.preset = "none"  -- Disable all default keymaps
      
      -- Only set the keymaps we want
      opts.keymap["<C-n>"] = { "select_next", "fallback" }
      opts.keymap["<C-p>"] = { "select_prev", "fallback" }
      opts.keymap["<CR>"] = { "accept", "fallback" }
      opts.keymap["<C-space>"] = { "show", "hide" }
      opts.keymap["<C-e>"] = { "hide" }
      
      -- Explicitly disable Tab, Shift-Tab, and Esc
      opts.keymap["<Tab>"] = {}
      opts.keymap["<S-Tab>"] = {}
      opts.keymap["<Esc>"] = {}
      
      return opts
    end,
  },
}

