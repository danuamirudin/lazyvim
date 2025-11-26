return {
  "nvim-treesitter/nvim-treesitter-context",
  event = "VeryLazy",
  opts = {
    enable = true,
    max_lines = 3,
    min_window_height = 0,
    line_numbers = true,
    multiline_threshold = 1,
    trim_scope = "outer",
    mode = "cursor",
    separator = nil,
    zindex = 20,
  },
  keys = {
    {
      "<leader>ut",
      function()
        local tsc = require("treesitter-context")
        tsc.toggle()
      end,
      desc = "Toggle Treesitter Context",
    },
  },
}
