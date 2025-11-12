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
            -- Save current session before switching
            local ok, persistence = pcall(require, "persistence")
            if ok then
              persistence.save()
            end
          end,
          open = function(name, path)
            -- Change directory first
            vim.cmd("cd " .. path)
            
            -- Load session after switching workspace
            vim.schedule(function()
              local ok, persistence = pcall(require, "persistence")
              if ok then
                local session_file = persistence.current()
                if session_file and vim.fn.filereadable(session_file) == 1 then
                  -- Close all buffers before loading session
                  vim.cmd("silent! %bdelete!")
                  
                  -- Small delay to ensure buffers are closed
                  vim.defer_fn(function()
                    persistence.load()
                    
                    -- Restart LSP clients after session load
                    vim.defer_fn(function()
                      vim.cmd("LspRestart")
                    end, 200)
                    
                    vim.notify("✓ Loaded session: " .. name, vim.log.levels.INFO)
                  end, 50)
                else
                  -- No session file, just close current buffers and open explorer
                  vim.cmd("silent! %bdelete!")
                  vim.defer_fn(function()
                    vim.notify("⚠ " .. name .. " (no session found)", vim.log.levels.WARN)
                    vim.cmd("Neotree")
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
