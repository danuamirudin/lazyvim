return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        find_files = {
          grep = {
            args = {
              "--glob=!vendor/**",
              "--glob=!node_modules/**",
              "--glob=!**/vendor/**",
              "--glob=!**/node_modules/**",
            },
          },
        },
        grep = {
          args = {
            "rg",
            "--vimgrep",
            "--smart-case",
            "--hidden",
            "--glob=!**/vendor/**",
            "--glob=!vendor/**",
            "--glob=!**node_modules/**",
            "--glob=!/Users/ahmadhasanudin/projects/old_app/**",
          },
        },
      },
    },
  },
}
