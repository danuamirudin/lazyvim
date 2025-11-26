return {
  {
    "natecraddock/workspaces.nvim",
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      require("workspaces").setup({
        path = vim.fn.stdpath("data") .. "/workspaces",
        hooks = {
          open_pre = function()
            -- Set global flag to prevent toggleterm from opening
            vim.g.switching_workspace = true
            
            -- Close floaterm properly if it's open to avoid state issues
            local floaterm_state_ok, floaterm_state = pcall(require, "floaterm.state")
            if floaterm_state_ok and floaterm_state.volt_set then
              -- Close floaterm windows and reset state
              pcall(function()
                if floaterm_state.win and vim.api.nvim_win_is_valid(floaterm_state.win) then
                  vim.api.nvim_win_close(floaterm_state.win, true)
                end
                if floaterm_state.barwin and vim.api.nvim_win_is_valid(floaterm_state.barwin) then
                  vim.api.nvim_win_close(floaterm_state.barwin, true)
                end
                if floaterm_state.sidewin and vim.api.nvim_win_is_valid(floaterm_state.sidewin) then
                  vim.api.nvim_win_close(floaterm_state.sidewin, true)
                end
              end)
              -- Reset floaterm state completely
              floaterm_state.volt_set = false
              floaterm_state.terminals = nil
              floaterm_state.buf = nil
              floaterm_state.sidebuf = nil
              floaterm_state.barbuf = nil
              floaterm_state.win = nil
              floaterm_state.barwin = nil
              floaterm_state.sidewin = nil
              if floaterm_state.bar_redraw_timer then
                pcall(function()
                  floaterm_state.bar_redraw_timer:stop()
                  floaterm_state.bar_redraw_timer:close()
                end)
                floaterm_state.bar_redraw_timer = nil
              end
            end
            
            -- Save current session before switching
            local ok, persistence = pcall(require, "persistence")
            if ok then
              persistence.save()
            end
          end,
          open = function(name, path)
            
            -- Change directory (this will trigger DirChanged autocmd)
            vim.cmd("cd " .. path)
            
            -- Load session after switching workspace
            vim.schedule(function()
              local ok, persistence = pcall(require, "persistence")
              if ok then
                local session_file = persistence.current()
                if session_file and vim.fn.filereadable(session_file) == 1 then
                  -- Close all buffers before loading session (except terminals - they persist globally)
                  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype ~= "terminal" then
                      vim.api.nvim_buf_delete(buf, { force = true })
                    end
                  end
                  
                  -- Small delay to ensure buffers are closed
                  vim.defer_fn(function()
                    persistence.load()
                    
                    -- Restart LSP clients after session load
                    vim.defer_fn(function()
                      -- Stop all LSP clients
                      for _, client in pairs(vim.lsp.get_active_clients()) do
                        client.stop()
                      end
                      
                      -- Restart LSP for current buffer
                      vim.defer_fn(function()
                        local buf = vim.api.nvim_get_current_buf()
                        local bufname = vim.api.nvim_buf_get_name(buf)
                        if bufname ~= "" and vim.fn.filereadable(bufname) == 1 then
                          vim.cmd("edit")
                        end
                      end, 100)
                    end, 250)
                    
                    vim.notify("✓ Loaded session: " .. name, vim.log.levels.INFO)
                    
                    -- Clear workspace switching flag
                    vim.defer_fn(function()
                      vim.g.switching_workspace = false
                    end, 100)
                  end, 50)
                else
                  -- No session file, close current buffers and open explorer (except terminals - they persist globally)
                  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype ~= "terminal" then
                      vim.api.nvim_buf_delete(buf, { force = true })
                    end
                  end
                  vim.defer_fn(function()
                    vim.notify("⚠ " .. name .. " (no session found)", vim.log.levels.WARN)
                    vim.cmd("Neotree")
                    
                    -- Clear workspace switching flag
                    vim.defer_fn(function()
                      vim.g.switching_workspace = false
                    end, 100)
                  end, 50)
                end
              end
              
              -- Reload SFTP config for new workspace
              local sftp = require("config.sftp")
              sftp.reload_config()
            end)
          end,
        },
      })

      -- Integrate with Telescope (for workspace picker)
      require("telescope").load_extension("workspaces")
    end,
    keys = {
      {
        "<leader>pw",
        function()
          require("telescope").extensions.workspaces.workspaces()
        end,
        desc = "Open Workspace",
      },
      {
        "<leader>pa",
        function()
          vim.ui.input({ prompt = "Workspace name: " }, function(name)
            if name then
              require("workspaces").add(vim.fn.getcwd(), name)
            end
          end)
        end,
        desc = "Add Workspace",
      },
    },
  },
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {
      options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp" },
      dir = vim.fn.stdpath("state") .. "/sessions/",
    },
    keys = {
      {
        "<leader>qs",
        function()
          require("persistence").load()
        end,
        desc = "Restore Session",
      },
      {
        "<leader>qS",
        function()
          require("persistence").save()
          vim.notify("✓ Session saved", vim.log.levels.INFO)
        end,
        desc = "Save Session",
      },
      {
        "<leader>ql",
        function()
          require("persistence").load({ last = true })
        end,
        desc = "Restore Last Session",
      },
      {
        "<leader>qd",
        function()
          require("persistence").stop()
        end,
        desc = "Don't Save Current Session",
      },
    },
  },
}
