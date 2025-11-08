return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Global keys that apply to all servers
        ["*"] = {
          keys = {
            { "K", false }, -- Disable K hover for all servers
          },
        },
      },
    },
  },
}
