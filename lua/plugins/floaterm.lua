return {
  "nvzone/floaterm",
  dependencies = "nvzone/volt",
  cmd = "FloatermToggle",
  opts = {
    border = true,
    size = { h = 80, w = 90 },
    mappings = {
      term = function(buf)
        -- Exit terminal mode
        vim.keymap.set("t", "jk", [[<C-\><C-n>]], { buffer = buf, desc = "Exit terminal mode" })
        vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { buffer = buf, desc = "Exit terminal mode" })
        
        -- Window navigation from terminal
        vim.keymap.set("t", "<C-h>", [[<C-\><C-n><C-w>h]], { buffer = buf, desc = "Navigate left" })
        
        -- Cycle through terminals
        vim.keymap.set({ "t", "n" }, "<C-n>", function()
          require("floaterm.api").cycle_term_bufs("next")
        end, { buffer = buf, desc = "Next terminal" })
        
        vim.keymap.set({ "t", "n" }, "<C-p>", function()
          require("floaterm.api").cycle_term_bufs("prev")
        end, { buffer = buf, desc = "Previous terminal" })
        
        -- Create new terminal
        vim.keymap.set({ "t", "n" }, "<C-t>", function()
          require("floaterm.api").new_term()
        end, { buffer = buf, desc = "New terminal" })
        
        -- Edit current terminal name
        vim.keymap.set({ "t", "n" }, "<C-e>", function()
          local state = require("floaterm.state")
          local utils = require("floaterm.utils")
          local current_idx = utils.get_term_by_key(state.buf)
          if current_idx then
            vim.ui.input({ 
              prompt = "Terminal name: ",
              default = state.terminals[current_idx[1]].name
            }, function(input)
              if input and input ~= "" then
                state.terminals[current_idx[1]].name = input
                require("volt").redraw(state.sidebuf, "bufs")
                vim.notify("✓ Renamed to: " .. input, vim.log.levels.INFO)
              end
            end)
          end
        end, { buffer = buf, desc = "Rename terminal" })
        
        -- Terminal control mappings (pass through to shell)
        vim.keymap.set("t", "<M-BS>", "<M-BS>", { buffer = buf })
        vim.keymap.set("t", "<C-l>", "<C-l>", { buffer = buf })
        vim.keymap.set("t", "<C-u>", "<C-u>", { buffer = buf })
        vim.keymap.set("t", "<C-w>", "<C-w>", { buffer = buf })
        vim.keymap.set("t", "<C-a>", "<C-a>", { buffer = buf })
        vim.keymap.set("t", "<C-e>", "<C-e>", { buffer = buf })
        vim.keymap.set("t", "<C-r>", "<C-r>", { buffer = buf })
        vim.keymap.set("t", "<M-Left>", "<M-Left>", { buffer = buf })
        vim.keymap.set("t", "<M-Right>", "<M-Right>", { buffer = buf })
        vim.keymap.set("t", "<M-b>", "<M-b>", { buffer = buf })
        vim.keymap.set("t", "<M-f>", "<M-f>", { buffer = buf })
        
        -- Close terminal
        vim.keymap.set("n", "q", "<cmd>FloatermToggle<cr>", { buffer = buf, desc = "Close terminal" })
      end,
    },
    terminals = {
      { name = "Terminal" },
    },
  },
  config = function(_, opts)
    require("floaterm").setup(opts)
    
    -- Override toggle to handle invalid window IDs safely
    local floaterm = require("floaterm")
    local original_toggle = floaterm.toggle
    
    floaterm.toggle = function()
      local state = require("floaterm.state")
      
      -- Check if buffers or windows are invalid and reset state if needed
      local buffers_valid = (not state.sidebuf or vim.api.nvim_buf_is_valid(state.sidebuf))
        and (not state.barbuf or vim.api.nvim_buf_is_valid(state.barbuf))
        and (not state.buf or vim.api.nvim_buf_is_valid(state.buf))
      
      local windows_valid = (not state.win or vim.api.nvim_win_is_valid(state.win))
        and (not state.barwin or vim.api.nvim_win_is_valid(state.barwin))
        and (not state.sidewin or vim.api.nvim_win_is_valid(state.sidewin))
      
      -- If volt_set but buffers/windows are invalid, reset everything
      if state.volt_set and (not buffers_valid or not windows_valid) then
        state.volt_set = false
        state.terminals = nil
        state.buf = nil
        state.sidebuf = nil
        state.barbuf = nil
        state.win = nil
        state.barwin = nil
        state.sidewin = nil
        if state.bar_redraw_timer then
          pcall(function()
            state.bar_redraw_timer:stop()
            state.bar_redraw_timer:close()
          end)
          state.bar_redraw_timer = nil
        end
      end
      
      -- Even if volt_set is false, check if stale buffers exist
      if not state.volt_set then
        if state.sidebuf and not vim.api.nvim_buf_is_valid(state.sidebuf) then
          state.sidebuf = nil
        end
        if state.barbuf and not vim.api.nvim_buf_is_valid(state.barbuf) then
          state.barbuf = nil
        end
        if state.buf and not vim.api.nvim_buf_is_valid(state.buf) then
          state.buf = nil
        end
      end
      
      -- Call original toggle
      original_toggle()
    end
  end,
  keys = {
    { "<C-\\>", "<cmd>FloatermToggle<cr>", desc = "Toggle terminal", mode = { "n", "t" } },
    { "<D-t>", "<cmd>FloatermToggle<cr>", desc = "Toggle terminal", mode = { "n", "t" } },
    { "<leader>tt", "<cmd>FloatermToggle<cr>", desc = "Toggle terminal" },
  },
}
