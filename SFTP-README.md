# SFTP Listener Configuration

## Overview
The SFTP listener automatically uploads files to remote SFTP servers when you save them in Neovim. Everything is now contained within your nvim config folder.

## File Locations
- **Binary**: `~/.config/nvim/sftp-listener/sftp-listener`
- **Source code**: `~/.config/nvim/sftp-listener/main.go`
- **Config file**: `~/.config/nvim/sftp-listener.json`
- **PID file**: `~/.config/nvim/.sftp-listener.pid`
- **Log file**: `~/.config/nvim/sftp-listener.log`

## Configuration

### Auto-start Setting
Edit `lua/config/sftp.lua` and change the `auto_start` setting:

```lua
M.config = {
  auto_start = true,  -- Set to false to disable auto-start
  ...
}
```

- `true`: Listener starts automatically when you open Neovim
- `false`: You need to manually start the listener

### Multiple Neovim Instances
The PID file (`~/.config/nvim/.sftp-listener.pid`) ensures only one listener runs at a time:
- First nvim instance starts the listener
- Additional nvim instances detect it's already running
- No conflicts occur

## Keymaps

### File Upload/Download
- `<leader>fU` - Upload folder (with prompt)
- `<leader>fd` - Download current file
- `<leader>fD` - Download folder (with prompt)

### Listener Control
- `<leader>fs` - Start listener
- `<leader>fS` - Stop listener  
- `<leader>ft` - Toggle listener (start/stop)

## Project Configuration

Edit `~/.config/nvim/sftp-listener.json` to add/modify projects:

```json
{
  "server_port": "8765",
  "registered_projects": {
    "project_name": {
      "local_base_path": "/path/to/local/project",
      "sftp_host": "example.com",
      "sftp_port": "22",
      "sftp_user": "username",
      "sftp_password": "password",
      "sftp_base_path": "/remote/path"
    }
  }
}
```

## Troubleshooting

### Rebuild the binary (if needed)
```bash
cd ~/.config/nvim/sftp-listener
go build -o sftp-listener main.go
```

### Check if listener is running
```bash
cat ~/.config/nvim/.sftp-listener.pid
ps -p <PID>
```

### View logs
```bash
tail -f ~/.config/nvim/sftp-listener.log
```

### Manually stop listener
```bash
kill $(cat ~/.config/nvim/.sftp-listener.pid)
rm ~/.config/nvim/.sftp-listener.pid
```

### Reset everything
```bash
pkill sftp-listener
rm ~/.config/nvim/.sftp-listener.pid
```

## How It Works

1. When you save a file in Neovim, the autocmd triggers
2. SFTP module sends HTTP request to listener (localhost:8765)
3. Listener validates project and uploads file to SFTP server
4. File maintains directory structure on remote server
