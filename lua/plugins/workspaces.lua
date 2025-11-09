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
          open = function(name, path)
            -- Change directory first
            vim.cmd("cd " .. path)
            
            -- Load session after switching workspace
            vim.schedule(function()
              local ok, persistence = pcall(require, "persistence")
              if ok then
                -- Close all buffers before loading session
                vim.cmd("silent! %bdelete")
                
                local session_file = persistence.current()
                if session_file and vim.fn.filereadable(session_file) == 1 then
                  -- Load the session
                  persistence.load()
                  vim.notify("✓ " .. name, vim.log.levels.INFO)
                else
                  -- No session file, open file explorer
                  vim.notify("⚠ " .. name .. " (no session)", vim.log.levels.WARN)
                  vim.cmd("e .")
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
