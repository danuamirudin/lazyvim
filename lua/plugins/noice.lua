return {
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = function(_, opts)
      -- Use noice for vim.notify
      vim.notify = require("noice").notify

      return {
        presets = {
          bottom_search = true,
          command_palette = false,
          long_message_to_split = true,
          lsp_doc_border = true,
        },
        notify = {
          enabled = true,
          view = "mini",
        },
        lsp = {
          override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
            ["cmp.entry.get_documentation"] = true,
          },
          progress = {
            enabled = false, -- Disable LSP progress (less distracting)
          },
        },
        routes = {
          {
            filter = {
              event = "notify",
              min_height = 1,
            },
            view = "mini",
            opts = { skip = false }, -- Keep in history
          },
          {
            filter = {
              event = "msg_show",
              any = {
                { find = "written" },
                { find = "SFTP" },
                { find = "session" },
                { find = "Session" },
                { find = "workspace" },
                { find = "Workspace" },
                { find = "Loaded" },
                { find = "Switched" },
              },
            },
            view = "mini",
            opts = { skip = false }, -- Keep in history
          },
        },
        views = {
          mini = {
            backend = "mini",
            relative = "editor",
            align = "message-right",
            timeout = 2000,
            reverse = true,
            position = {
              row = -2,
              col = "100%",
            },
            size = {
              width = "auto",
              height = "auto",
              max_height = 1,
            },
            border = {
              style = "none",
            },
            zindex = 60,
            win_options = {
              winblend = 0,
              winhighlight = {
                Normal = "NoicePopupmenu",
                FloatBorder = "NoicePopupmenuBorder",
              },
            },
          },
        },
      }
    end,
    keys = {
      { "<leader>sn", "", desc = "+noice" },
      {
        "<leader>snl",
        function()
          require("noice").cmd("last")
        end,
        desc = "Noice Last Message",
      },
      {
        "<leader>snh",
        function()
          require("noice").cmd("history")
        end,
        desc = "Noice History",
      },
      {
        "<leader>n",
        function()
          require("noice").cmd("telescope")
        end,
        desc = "Noice Picker (Telescope)",
      },
      {
        "<leader>sna",
        function()
          require("noice").cmd("all")
        end,
        desc = "Noice All",
      },
      {
        "<leader>snd",
        function()
          require("noice").cmd("dismiss")
        end,
        desc = "Dismiss All",
      },
    },
  },
  -- Disable nvim-notify, use noice for all notifications
  {
    "rcarriga/nvim-notify",
    enabled = false,
  },
}
