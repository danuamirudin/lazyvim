return {
  {
    "mg979/vim-visual-multi",
    branch = "master",
    init = function()
      -- VS Code-style keymaps
      vim.g.VM_maps = {
        ["Find Under"] = "<D-d>", -- Cmd + D (Mac)
        ["Find Subword Under"] = "<D-d>", -- same for sub-words
        ["Select All"] = "<leader>sa", -- Select All
      }

      -- Optional tweaks
      vim.g.VM_mouse_mappings = 1
      vim.g.VM_show_warnings = 0
      vim.g.VM_silent_exit = 1

      vim.api.nvim_create_autocmd("User", {
        pattern = "visual_multi_exit",
        callback = function()
          -- move cursor to the last visual-multi position instead of restoring old one
          vim.cmd("normal! gv") -- reselect last visual area
          vim.cmd("normal! `<") -- move to start of selection
        end,
      })
    end,
  },
}

