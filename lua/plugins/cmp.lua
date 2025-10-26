return {
  "hrsh7th/nvim-cmp",
  opts = function(_, opts)
    local cmp = require("cmp")
    opts.mapping = vim.tbl_extend("force", opts.mapping, {
      ["<Tab>"] = cmp.mapping.confirm({ select = true }),
      ["<Esc>"] = cmp.mapping(function(fallback) -- Custom <Esc> behavior
        if cmp.visible() then
          cmp.abort()
        else
          fallback()
        end
      end, { "i", "s" }),
    })
  end,
}