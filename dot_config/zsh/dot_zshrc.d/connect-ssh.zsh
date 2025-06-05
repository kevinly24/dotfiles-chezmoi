#!/bin/bash

# Function to connect to a host using autossh with dynamic port selection
connect_ssh() {
    local host="$1"
    # Approach 1: Use zsh -l to start a login shell before tmux
    local remote_cmd="zsh -l -c 'tmux attach-session || tmux new-session'"
    local base_port=20000
    local max_port=30000
    local port=$base_port
    
    # Find first available port using a Python one-liner
    port=$(python3 -c "
import socket
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
for p in range($base_port, $max_port):
    try:
        s.bind(('127.0.0.1', p))
        s.close()
        print(p)
        break
    except:
        continue
")
    
    if [ -z "$port" ]; then
        echo "Error: No available ports found between $base_port and $max_port"
        return 1
    fi
    
    echo "Connecting to $host using monitor port $port"
    autossh -M $port -t "$host" "$remote_cmd"
}

# If script is executed directly (not sourced), run the function with arguments
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ $# -eq 0 ]; then
        echo "Usage: $(basename "$0") <ssh-host>"
        exit 1
    fi
    
    connect_ssh "$1"
fi
