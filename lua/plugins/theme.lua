return {
  -- Tokyonight
  {
    "folke/tokyonight.nvim",
    lazy = true,
    opts = {
      --[[ transparent = true, ]]
    },
  },
  
  -- Gruvbox
  {
    "ellisonleao/gruvbox.nvim",
    lazy = true,
  },
  
  -- Nord
  {
    "shaunsingh/nord.nvim",
    lazy = true,
  },
  
  -- OneDark
  {
    "navarasu/onedark.nvim",
    lazy = false,
    priority = 1000,
  },
  
  -- Dracula
  {
    "Mofiqul/dracula.nvim",
    lazy = true,
  },
  
  -- Kanagawa
  {
    "rebelot/kanagawa.nvim",
    lazy = true,
  },
  
  -- Rose Pine
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = true,
  },
  
  -- Nightfox
  {
    "EdenEast/nightfox.nvim",
    lazy = true,
  },
}
