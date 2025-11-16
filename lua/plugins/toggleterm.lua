return {
  "akinsho/toggleterm.nvim",
  version = "*",
  opts = {
    size = function(term)
      if term.direction == "horizontal" then
        return 15
      elseif term.direction == "vertical" then
        return vim.o.columns * 0.4
      end
    end,
    open_mapping = [[<c-\>]],
    hide_numbers = true,
    shade_terminals = true,
    shading_factor = 2,
    start_in_insert = true,
    insert_mappings = true,
    terminal_mappings = true,
    persist_size = true,
    persist_mode = true,
    direction = "float",
    close_on_exit = false, -- Keep terminal state when switching projects
    shell = vim.o.shell,
    auto_scroll = true,
    float_opts = {
      border = "curved",
      width = function()
        return math.floor(vim.o.columns * 0.9)
      end,
      height = function()
        return math.floor(vim.o.lines * 0.8)
      end,
      winblend = 3,
    },
    winbar = {
      enabled = true,
      name_formatter = function(term)
        return string.format("Terminal #%d - %s", term.id, term.dir or vim.fn.getcwd())
      end,
    },
    on_open = function(term)
      vim.wo[term.window].number = false
      vim.wo[term.window].relativenumber = false
      vim.cmd("startinsert!")
      
      -- Set up buffer-local keymaps for terminal normal mode
      local bufnr = term.bufnr
      vim.schedule(function()
        if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
          -- q to close terminal when in normal mode (not terminal mode)
          vim.keymap.set("n", "q", "<cmd>lua toggle_all_workspace_terminals()<cr>", 
            { buffer = bufnr, desc = "Close terminal" })
          
          -- Enable modifiers in terminal mode (pass through to shell)
          -- Option+Delete (backward delete word)
          vim.keymap.set("t", "<M-BS>", "<M-BS>", { buffer = bufnr })
          -- Control+L (clear screen)
          vim.keymap.set("t", "<C-l>", "<C-l>", { buffer = bufnr })
          -- Control+U (clear line)
          vim.keymap.set("t", "<C-u>", "<C-u>", { buffer = bufnr })
          -- Control+W (backward delete word)
          vim.keymap.set("t", "<C-w>", "<C-w>", { buffer = bufnr })
          -- Control+A (beginning of line)
          vim.keymap.set("t", "<C-a>", "<C-a>", { buffer = bufnr })
          -- Control+E (end of line)
          vim.keymap.set("t", "<C-e>", "<C-e>", { buffer = bufnr })
          -- Control+R (history search)
          vim.keymap.set("t", "<C-r>", "<C-r>", { buffer = bufnr })
          -- Option+Left (word back)
          vim.keymap.set("t", "<M-Left>", "<M-Left>", { buffer = bufnr })
          -- Option+Right (word forward)
          vim.keymap.set("t", "<M-Right>", "<M-Right>", { buffer = bufnr })
          -- Option+B (word back)
          vim.keymap.set("t", "<M-b>", "<M-b>", { buffer = bufnr })
          -- Option+F (word forward)
          vim.keymap.set("t", "<M-f>", "<M-f>", { buffer = bufnr })
        end
      end)
    end,
  },
  config = function(_, opts)
    require("toggleterm").setup(opts)
    
    local Terminal = require("toggleterm.terminal").Terminal
    local terminals = {}
    local current_terminal_id = 1
    local workspace_terminal_state = {} -- Track which terminals belong to which workspace
    local next_unique_id = 1000 -- Start from 1000 to avoid conflicts with default terminals
    
    -- Map workspace_key to unique numeric ID
    local workspace_terminal_ids = {}
    
    -- Function to hide all terminals from other workspaces
    local function hide_other_workspace_terminals()
      local current_workspace = vim.fn.getcwd()
      
      for key, term in pairs(terminals) do
        local term_workspace = key:match("^(.+)_%d+$")
        if term_workspace ~= current_workspace then
          if term:is_open() then
            -- Force close the window, not just toggle
            if term.window and vim.api.nvim_win_is_valid(term.window) then
              pcall(vim.api.nvim_win_close, term.window, true)
            end
            -- Mark as closed in toggleterm's state
            term.window = nil
          end
        end
      end
    end
    
    -- Function to close all terminals
    local function close_all_terminals()
      for _, term in pairs(terminals) do
        if term:is_open() then
          -- Force close the window
          if term.window and vim.api.nvim_win_is_valid(term.window) then
            pcall(vim.api.nvim_win_close, term.window, true)
          end
          -- Mark as closed in toggleterm's state
          term.window = nil
        end
      end
    end
    
    -- Function to get or create terminal for current workspace
    local function get_workspace_terminal(id)
      local workspace_root = vim.fn.getcwd()
      local key = workspace_root .. "_" .. id
      
      if not terminals[key] then
        -- Get or create a unique numeric ID for this workspace+id combination
        if not workspace_terminal_ids[key] then
          workspace_terminal_ids[key] = next_unique_id
          next_unique_id = next_unique_id + 1
        end
        
        local unique_numeric_id = workspace_terminal_ids[key]
        
        terminals[key] = Terminal:new({
          -- Use unique numeric ID so toggleterm doesn't reuse buffers
          id = unique_numeric_id,
          direction = "float",
          dir = workspace_root,
          on_create = function(term)
            workspace_terminal_state[key] = { workspace = workspace_root, last_active = os.time() }
            
            -- Tag immediately on create
            vim.schedule(function()
              if term.bufnr and vim.api.nvim_buf_is_valid(term.bufnr) then
                vim.b[term.bufnr].terminal_workspace = workspace_root
              end
            end)
          end,
          on_open = function(term)
            vim.cmd("startinsert!")
            
            -- Tag terminal buffer with its workspace
            vim.schedule(function()
              if term.bufnr and vim.api.nvim_buf_is_valid(term.bufnr) then
                vim.b[term.bufnr].terminal_workspace = workspace_root
              end
            end)
          end,
          on_close = function()
            -- Terminal persists, doesn't get destroyed
          end,
        })
      end
      
      return terminals[key]
    end
    
    -- Toggle floating terminal
    function _G.toggle_terminal(id)
      -- Don't open terminals during workspace switching
      if vim.g.switching_workspace then
        return
      end
      
      id = id or current_terminal_id
      local current_workspace = vim.fn.getcwd()
      
      -- Set flag to prevent autocmds from closing the terminal we're opening
      vim.g.opening_terminal = true
      
      -- Get or create terminal for current workspace (this creates workspace-specific terminal)
      local term = get_workspace_terminal(id)
      
      -- If terminal is already open, just toggle it
      if term:is_open() then
        term:toggle()
        vim.g.opening_terminal = false
        return
      end
      
      -- Before opening, hide all other workspace terminals
      hide_other_workspace_terminals()
      term:toggle()
      
      -- Clear flag after terminal is opened
      vim.defer_fn(function()
        vim.g.opening_terminal = false
      end, 100)
    end
    
    -- Create new terminal tab
    function _G.new_terminal_tab()
      -- Find next available terminal ID
      local workspace_root = vim.fn.getcwd()
      local next_id = 1
      while terminals[workspace_root .. "_" .. next_id] do
        next_id = next_id + 1
      end
      current_terminal_id = next_id
      toggle_terminal(next_id)
    end
    
    -- Cycle through terminal tabs
    function _G.cycle_terminal_tabs()
      local workspace_root = vim.fn.getcwd()
      local workspace_terms = {}
      
      print("=== Debug Cycle ===")
      print("Workspace root:", workspace_root)
      print("Current terminal ID:", current_terminal_id)
      print("\nAll terminals:")
      for key, term in pairs(terminals) do
        print("  Key:", key)
      end
      
      -- Find all terminals for current workspace
      for key, term in pairs(terminals) do
        local escaped_workspace = vim.pesc(workspace_root)
        local pattern = "^" .. escaped_workspace
        print("\nChecking:", key)
        print("  Pattern:", pattern)
        print("  Matches:", key:match(pattern) ~= nil)
        
        if key:match(pattern) then
          local id = tonumber(key:match("_(%d+)$"))
          print("  Extracted ID:", id)
          if id then
            table.insert(workspace_terms, { id = id, term = term })
          end
        end
      end
      
      print("\nFound workspace terminals:", #workspace_terms)
      for i, t in ipairs(workspace_terms) do
        print("  Terminal", i, "ID:", t.id)
      end
      
      -- Sort by id
      table.sort(workspace_terms, function(a, b) return a.id < b.id end)
      
      if #workspace_terms == 0 then
        vim.notify("No terminals found for this workspace", vim.log.levels.WARN)
        return
      end
      
      if #workspace_terms == 1 then
        vim.notify("Only one terminal exists", vim.log.levels.INFO)
        return
      end
      
      -- Find current terminal index
      local current_idx = 1
      for i, t in ipairs(workspace_terms) do
        if t.id == current_terminal_id then
          current_idx = i
          break
        end
      end
      
      print("\nCurrent index:", current_idx)
      
      -- Get next terminal
      local next_idx = (current_idx % #workspace_terms) + 1
      local next_term = workspace_terms[next_idx]
      
      print("Next index:", next_idx)
      print("Next terminal ID:", next_term.id)
      
      current_terminal_id = next_term.id
      toggle_terminal(next_term.id)
    end
    
    -- Close current terminal tab
    function _G.close_terminal_tab(id)
      id = id or current_terminal_id
      local workspace_root = vim.fn.getcwd()
      local key = workspace_root .. "_" .. id
      
      if terminals[key] then
        terminals[key]:shutdown()
        terminals[key] = nil
        vim.notify("Terminal #" .. id .. " closed", vim.log.levels.INFO)
        
        -- Switch to terminal 1 if available
        if id ~= 1 and terminals[workspace_root .. "_1"] then
          current_terminal_id = 1
        end
      end
    end
    
    -- Clean up terminals on VimLeavePre (before quit)
    vim.api.nvim_create_autocmd("VimLeavePre", {
      callback = function()
        for _, term in pairs(terminals) do
          if term:is_open() then
            term:shutdown()
          end
        end
        terminals = {}
      end,
    })
    
    -- Handle workspace switching - hide terminals from other workspaces
    vim.api.nvim_create_autocmd("DirChanged", {
      callback = function()
        local new_workspace = vim.fn.getcwd()
        
        -- Hide terminals from other workspaces (but keep them alive)
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "terminal" then
            local buf_workspace = vim.b[buf].terminal_workspace
            
            -- If terminal belongs to different workspace, hide it
            if buf_workspace and buf_workspace ~= new_workspace then
              for _, win in ipairs(vim.api.nvim_list_wins()) do
                if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
                  pcall(vim.api.nvim_win_close, win, true)
                end
              end
            end
          end
        end
        
        -- Reset current terminal id to 1 for new workspace
        current_terminal_id = 1
      end,
    })
    
    -- Also check when entering any buffer (catches terminals that might appear)
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
      callback = function(ev)
        -- Don't interfere if we're opening a terminal
        if vim.g.opening_terminal then
          return
        end
        
        local buf = ev.buf
        if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "terminal" then
          local buf_workspace = vim.b[buf].terminal_workspace
          local current_workspace = vim.fn.getcwd()
          
          -- If this terminal belongs to a different workspace, close its window
          if buf_workspace and buf_workspace ~= current_workspace then
            for _, win in ipairs(vim.api.nvim_list_wins()) do
              if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
                pcall(vim.api.nvim_win_close, win, true)
              end
            end
          end
        end
      end,
    })
    
    -- Toggle all workspace terminals (show if any hidden, hide if any visible)
    function _G.toggle_all_workspace_terminals()
      local current_workspace = vim.fn.getcwd()
      local workspace_terms = {}
      local any_open = false
      
      -- Find all terminals for current workspace
      for key, term in pairs(terminals) do
        if key:match("^" .. vim.pesc(current_workspace)) then
          table.insert(workspace_terms, term)
          if term:is_open() then
            any_open = true
          end
        end
      end
      
      -- If any terminal is open, close all
      if any_open then
        for _, term in ipairs(workspace_terms) do
          if term:is_open() then
            term:close()
          end
        end
      else
        -- No terminals open, open terminal 1
        toggle_terminal(1)
      end
    end
    
    -- Store global functions for workspace integration
    _G.toggleterm_close_all = close_all_terminals
    _G.toggleterm_get_workspace_terminals = function()
      local workspace_root = vim.fn.getcwd()
      local workspace_terms = {}
      for key, term in pairs(terminals) do
        if key:match("^" .. vim.pesc(workspace_root)) then
          table.insert(workspace_terms, { key = key, term = term })
        end
      end
      return workspace_terms
    end
  end,
  keys = {
    { "<C-\\>", "<cmd>lua toggle_terminal(1)<cr>", desc = "Toggle terminal", mode = { "n", "t" } },
    { "<D-t>", "<cmd>lua toggle_all_workspace_terminals()<cr>", desc = "Toggle all terminals", mode = { "n", "t" } },
    { "<leader>tt", "<cmd>lua toggle_all_workspace_terminals()<cr>", desc = "Toggle all terminals" },
    { "<leader>tn", "<cmd>lua new_terminal_tab()<cr>", desc = "New terminal tab" },
    { "<C-n>", [[<C-\><C-n><cmd>lua cycle_terminal_tabs()<cr>]], desc = "Cycle terminal tabs", mode = "t" },
    { "<leader>tc", "<cmd>lua cycle_terminal_tabs()<cr>", desc = "Cycle terminal tabs" },
    { "<leader>tq", "<cmd>lua close_terminal_tab()<cr>", desc = "Close terminal tab" },
    { "<leader>t1", "<cmd>lua toggle_terminal(1)<cr>", desc = "Terminal 1" },
    { "<leader>t2", "<cmd>lua toggle_terminal(2)<cr>", desc = "Terminal 2" },
    { "<leader>t3", "<cmd>lua toggle_terminal(3)<cr>", desc = "Terminal 3" },
    { "<leader>t4", "<cmd>lua toggle_terminal(4)<cr>", desc = "Terminal 4" },
    { "<leader>th", "<cmd>ToggleTerm direction=horizontal<cr>", desc = "Horizontal terminal" },
    { "<leader>tv", "<cmd>ToggleTerm direction=vertical<cr>", desc = "Vertical terminal" },
    -- Window navigation from terminal (Ctrl+hjkl to navigate out)
    { "<C-h>", [[<C-\><C-n><C-w>h]], desc = "Navigate left", mode = "t" },
    { "<C-j>", [[<C-\><C-n><C-w>j]], desc = "Navigate down", mode = "t" },
    { "<C-k>", [[<C-\><C-n><C-w>k]], desc = "Navigate up", mode = "t" },
    -- Terminal mode keybindings
    { "jk", [[<C-\><C-n>]], desc = "Exit terminal mode", mode = "t" },
    { "<Esc>", [[<C-\><C-n>]], desc = "Exit terminal mode", mode = "t" },
    { "<C-x>", "<cmd>lua close_terminal_tab()<cr>", desc = "Close terminal tab", mode = "t" },
  },
}
