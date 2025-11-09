# SFTP Listener Service

This is the Go HTTP service that handles SFTP file uploads/downloads for Neovim.

## Building

```bash
./build.sh
# or
go build -o sftp-listener main.go
```

## Running Manually

```bash
# With config in parent directory (default)
./sftp-listener

# With custom config path
CONFIG_PATH=/path/to/config.json ./sftp-listener
```

## How It Works

1. Starts HTTP server on port 8765 (configurable)
2. Listens for POST requests from Neovim
3. Validates projects against whitelist in config
4. Uploads/downloads files to/from SFTP servers

## Endpoints

- `POST /upload` - Upload a file
- `POST /upload-folder` - Upload entire folder
- `POST /download` - Download a file
- `POST /download-folder` - Download entire folder
- `GET /health` - Health check
- `GET /projects` - List registered projects

## Dependencies

```bash
go get github.com/pkg/sftp
go get golang.org/x/crypto/ssh
```

## Note

This service is automatically managed by Neovim through `lua/config/sftp.lua`. You typically don't need to run it manually.
