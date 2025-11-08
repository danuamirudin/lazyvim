return {
  {
    "mg979/vim-visual-multi",
    branch = "master",
    init = function()
      -- VS Code-style keymaps
      vim.g.VM_maps = {
        ["Find Under"] = "<D-d>", -- Cmd + D (Mac) - Add next occurrence
        ["Find Subword Under"] = "<D-d>", -- same for sub-words
        ["Skip Region"] = "<D-k>", -- Cmd + K - Skip current and find next
        ["Add Cursor Down"] = "<D-Down>",
        ["Add Cursor Up"] = "<D-Up>",
      }

      -- Optional tweaks
      vim.g.VM_mouse_mappings = 1
      vim.g.VM_show_warnings = 0
      vim.g.VM_silent_exit = 1
      
      -- Start VM immediately when using Cmd+D
      vim.g.VM_default_mappings = 1

      vim.api.nvim_create_autocmd("User", {
        pattern = "visual_multi_exit",
        callback = function()
          -- move cursor to the last visual-multi position instead of restoring old one
          vim.cmd("normal! gv") -- reselect last visual area
          vim.cmd("normal! `<") -- move to start of selection
        end,
      })
    end,
    keys = {
      {
        "<D-d>",
        function()
          vim.cmd([[call vm#commands#find_under(0, 1)]])
        end,
        mode = { "n", "v" },
        desc = "Add cursor to next match (Cmd+D)",
      },
      {
        "<D-L>",
        function()
          local mode = vim.fn.mode()
          if mode == "v" or mode == "V" or mode == "\22" then
            -- Visual mode: select all matches of visual selection
            vim.cmd("normal! y") -- yank the selection
            local search_pattern = vim.fn.getreg('"')
            vim.fn.setreg('/', vim.fn.escape(search_pattern, '\\/.*$^~[]'))
            vim.cmd([[execute "normal! \<Plug>(VM-Find-Under)"]])
            vim.cmd([[execute "normal! \<Plug>(VM-Select-All)"]])
          else
            -- Normal mode: select all matches of word under cursor
            vim.cmd([[execute "normal! \<Plug>(VM-Select-All)\<Tab>"]])
          end
        end,
        mode = { "n", "v" },
        desc = "Select all occurrences (Cmd+Shift+L)",
      },
    },
  },
}

