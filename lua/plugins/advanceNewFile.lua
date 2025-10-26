return {
  {
    "adibhanna/nvim-newfile.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    config = function()
      require("nvim-newfile").setup({
        -- optional settings
        template = nil,
        extension = nil,
      })
    end,
    keys = {
      { "<leader>fn", ":NewFile<space>", desc = "New File" },
      { "<leader>fN", ":NewFileHere<space>", desc = "New File Here" },
    },
  },
}
