#!/bin/bash
# Build script for SFTP listener

cd "$(dirname "$0")"
echo "Building SFTP listener..."
go build -o sftp-listener main.go

if [ $? -eq 0 ]; then
    echo "✓ Build successful: $(pwd)/sftp-listener"
    chmod +x sftp-listener
else
    echo "✗ Build failed"
    exit 1
fi
