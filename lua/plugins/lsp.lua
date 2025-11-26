return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        intelephense = {
          on_attach = function(client, bufnr)
            local settings = vim.g.SETTINGS or { auto_format_on_save = false }
            -- Control formatting based on settings
            if settings.auto_format_on_save then
              -- Ensure formatting is enabled
              client.server_capabilities.documentFormattingProvider = true
              client.server_capabilities.documentRangeFormattingProvider = true
            else
              -- Disable formatting on save only
              client.server_capabilities.documentFormattingProvider = false
              client.server_capabilities.documentRangeFormattingProvider = false
            end
          end,
          settings = {
            intelephense = {
              format = {
                enable = true,
              },
              stubs = {
                "bcmath",
                "bz2",
                "calendar",
                "Core",
                "curl",
                "date",
                "dba",
                "dom",
                "enchant",
                "fileinfo",
                "filter",
                "ftp",
                "gd",
                "gettext",
                "hash",
                "iconv",
                "imap",
                "intl",
                "json",
                "ldap",
                "libxml",
                "mbstring",
                "mcrypt",
                "mysql",
                "mysqli",
                "password",
                "pcntl",
                "pcre",
                "PDO",
                "pdo_mysql",
                "Phar",
                "readline",
                "recode",
                "Reflection",
                "regex",
                "session",
                "SimpleXML",
                "soap",
                "sockets",
                "sodium",
                "SPL",
                "standard",
                "superglobals",
                "sysvsem",
                "sysvshm",
                "tokenizer",
                "xml",
                "xdebug",
                "xmlreader",
                "xmlwriter",
                "yaml",
                "zip",
                "zlib",
                "wordpress",
                "woocommerce",
                "acf-pro",
                "wordpress-globals",
                "wp-cli",
                "genesis",
                "polylang",
              },
              diagnostics = {
                enable = true,
              },
              telemetry = {
                enabled = false,
              },
              files = {
                maxSize = 5000000,
              },
            },
          },
        },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "intelephense",
      },
    },
  },
}
