local M = {}

-- List of available themes
M.themes = {
  "tokyonight",
  "tokyonight-night",
  "tokyonight-storm",
  "tokyonight-day",
  "tokyonight-moon",
  "catppuccin",
  "catppuccin-frappe",
  "catppuccin-macchiato",
  "catppuccin-mocha",
  "gruvbox",
  "nord",
  "onedark",
  "dracula",
  "kanagawa",
  "rose-pine",
  "nightfox",
  "carbonfox",
  "duskfox",
  "nordfox",
  "terafox",
  "dayfox",
}

-- Apply theme
M.apply_theme = function(theme)
  local ok = pcall(vim.cmd.colorscheme, theme)
  if ok then
    -- Save theme to file
    local config_path = vim.fn.stdpath("config") .. "/lua/config/current_theme.lua"
    local file = io.open(config_path, "w")
    if file then
      file:write('return "' .. theme .. '"\n')
      file:close()
    end
    vim.notify("Theme changed to: " .. theme, vim.log.levels.INFO)
  else
    vim.notify("Theme not found: " .. theme, vim.log.levels.ERROR)
  end
end

-- Theme selector using vim.ui.select
M.theme_selector = function()
  local current_theme = vim.g.colors_name or "tokyonight"

  vim.ui.select(M.themes, {
    prompt = "  Select Theme:",
    format_item = function(item)
      if item == current_theme then
        return item .. " (current)"
      end
      return item
    end,
  }, function(choice)
    if choice then
      M.apply_theme(choice)
    end
  end)
end

-- Alternative: Simple picker with live preview
M.theme_selector_simple = function()
  local original_theme = vim.g.colors_name or "tokyonight"
  local current_idx = 1

  -- Find current theme index
  for i, theme in ipairs(M.themes) do
    if theme == original_theme then
      current_idx = i
      break
    end
  end

  local function show_menu()
    local lines = { "  Theme Selector (↑/↓ to navigate, Enter to select, Esc to cancel)", "" }
    for i, theme in ipairs(M.themes) do
      if i == current_idx then
        lines[#lines + 1] = "  ▶ " .. theme
      else
        lines[#lines + 1] = "    " .. theme
      end
    end

    local buf = vim.api.nvim_create_buf(false, true)
    local width = 60
    local height = #lines
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    local win = vim.api.nvim_open_win(buf, true, {
      relative = "editor",
      width = width,
      height = height,
      row = row,
      col = col,
      style = "minimal",
      border = "rounded",
    })

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    vim.api.nvim_win_set_option(win, "cursorline", false)

    -- Set keymaps
    local function close_and_restore()
      vim.api.nvim_win_close(win, true)
      pcall(vim.cmd.colorscheme, original_theme)
    end

    local function close_and_apply()
      vim.api.nvim_win_close(win, true)
      M.apply_theme(M.themes[current_idx])
    end

    local function navigate(direction)
      current_idx = current_idx + direction
      if current_idx < 1 then
        current_idx = #M.themes
      elseif current_idx > #M.themes then
        current_idx = 1
      end
      pcall(vim.cmd.colorscheme, M.themes[current_idx])
      vim.api.nvim_win_close(win, true)
      vim.defer_fn(show_menu, 10)
    end

    vim.keymap.set("n", "<CR>", close_and_apply, { buffer = buf, nowait = true })
    vim.keymap.set("n", "<Esc>", close_and_restore, { buffer = buf, nowait = true })
    vim.keymap.set("n", "q", close_and_restore, { buffer = buf, nowait = true })
    vim.keymap.set("n", "j", function()
      navigate(1)
    end, { buffer = buf, nowait = true })
    vim.keymap.set("n", "k", function()
      navigate(-1)
    end, { buffer = buf, nowait = true })
    vim.keymap.set("n", "<Down>", function()
      navigate(1)
    end, { buffer = buf, nowait = true })
    vim.keymap.set("n", "<Up>", function()
      navigate(-1)
    end, { buffer = buf, nowait = true })
  end

  show_menu()
end

-- Load saved theme or default
M.load_theme = function()
  local config_path = vim.fn.stdpath("config") .. "/lua/config/current_theme.lua"
  local ok, theme = pcall(dofile, config_path)
  if ok and theme then
    pcall(vim.cmd.colorscheme, theme)
  else
    -- Default theme
    pcall(vim.cmd.colorscheme, "catppuccin-macchiato")
  end
end

return M
