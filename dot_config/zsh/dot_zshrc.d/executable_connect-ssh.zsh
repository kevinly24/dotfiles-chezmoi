#!/bin/zsh

# Tracking file for autossh connections
AUTOSSH_TRACKING_FILE="$HOME/.autossh_connections"

# Function to connect to a host using autossh with dynamic port selection
connect_ssh() {
    local host="$1"
    # Approach 1: Use zsh -l to start a login shell before tmux
    local remote_cmd="zsh -l -c 'tmux attach-session || tmux new-session'"
    local base_port=30000
    local max_port=40000
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
    
    # Record the connection in the tracking file
    echo "$(date +%s) $port $host $$" >> "$AUTOSSH_TRACKING_FILE"
    
    # Set up a trap to clean up when the shell exits
    trap "cleanup_autossh_connection $port $$; cleanup_ssh_controlmaster $host" EXIT INT TERM
    
    echo "Connecting to $host using monitor port $port"
    echo "Connection will be automatically cleaned up when you exit tmux/ssh"
    
    # Run autossh with the process group ID as an identifier
    autossh -M $port -t "$host" "$remote_cmd"
    
    # Clean up after the connection ends
    cleanup_autossh_connection $port $$
    cleanup_ssh_controlmaster "$host"
    trap - EXIT INT TERM
}

# If script is executed directly (not sourced), run the function with arguments
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ $# -eq 0 ]; then
        echo "Usage: $(basename "$0") <ssh-host>"
        exit 1
    fi
    
    connect_ssh "$1"
fi
# Function to clean up a specific autossh connection
cleanup_autossh_connection() {
    local port="$1"
    local parent_pid="$2"
    
    echo "Cleaning up autossh connection on port $port"
    
    # Find and kill the autossh process using this port
    local pid=$(ps aux | grep "autossh -M $port" | grep -v grep | awk '{print $2}')
    if [[ -n "$pid" ]]; then
        echo "Killing autossh process (PID: $pid)"
        kill "$pid" 2>/dev/null
    fi
    
    # Remove the connection from the tracking file
    if [[ -f "$AUTOSSH_TRACKING_FILE" ]]; then
        # Use awk instead of grep for more reliable pattern matching
        awk -v port="$port" '$2 != port' "$AUTOSSH_TRACKING_FILE" > "${AUTOSSH_TRACKING_FILE}.tmp"
        mv "${AUTOSSH_TRACKING_FILE}.tmp" "$AUTOSSH_TRACKING_FILE"
    fi
}

# Function to clean up all tracked autossh connections
cleanup_all_autossh() {
    if [[ ! -f "$AUTOSSH_TRACKING_FILE" ]]; then
        echo "No autossh connections tracked."
        return 0
    fi
    
    echo "Cleaning up all tracked autossh connections..."
    
    # Use a safer read method that handles empty files and malformed lines
    while IFS=' ' read -r timestamp port host parent_pid || [[ -n "$timestamp" ]]; do
        # Skip empty lines
        if [[ -z "$timestamp" || -z "$port" || -z "$host" ]]; then
            continue
        fi
        
        echo "Checking connection to $host on port $port..."
        
        # Find and kill the autossh process using this port
        local pid=$(ps aux | grep "autossh -M $port" | grep -v grep | awk '{print $2}')
        if [[ -n "$pid" ]]; then
            echo "Killing autossh process (PID: $pid)"
            kill "$pid" 2>/dev/null
        else
            echo "No active autossh process found for port $port"
        fi
    done < "$AUTOSSH_TRACKING_FILE"
    
    # Clear the tracking file
    > "$AUTOSSH_TRACKING_FILE"
    echo "All connections cleaned up."
}
# If script is executed directly (not sourced), run the function with arguments
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ $# -eq 0 ]; then
        echo "Usage: $(basename "$0") <ssh-host>"
        exit 1
    fi
    
    connect_ssh "$1"
fi
# Function to clean up SSH ControlMaster connections
cleanup_ssh_controlmaster() {
    local host="$1"
    
    echo "Cleaning up SSH ControlMaster connections for $host..."
    
    # Find socket files for this host
    local socket_files=$(find ~/.ssh/sockets -name "*@${host}*" 2>/dev/null)
    
    if [[ -n "$socket_files" ]]; then
        echo "Found socket files for $host"
        for socket in $socket_files; do
            echo "Closing connection for socket: $socket"
            ssh -O exit -S "$socket" "$host" 2>/dev/null
            if [[ $? -eq 0 ]]; then
                echo "Successfully closed connection"
            else
                echo "Failed to close connection, trying to remove socket file"
                # If SSH command fails, check if the socket is stale and remove it
                if [[ -S "$socket" ]]; then
                    local pid=$(lsof -t "$socket" 2>/dev/null)
                    if [[ -z "$pid" ]]; then
                        echo "Socket appears to be stale, removing it"
                        rm -f "$socket"
                    else
                        echo "Socket is still in use by PID $pid, killing process"
                        kill $pid 2>/dev/null
                        sleep 1
                        rm -f "$socket" 2>/dev/null
                    fi
                fi
            fi
        done
    else
        echo "No socket files found for $host"
    fi
    
    # Also check for any SSH processes that might be related to this host
    local ssh_pids=$(ps aux | grep "ssh.*$host" | grep -v grep | awk '{print $2}')
    if [[ -n "$ssh_pids" ]]; then
        echo "Found SSH processes for $host, checking if they're multiplexers"
        for pid in $ssh_pids; do
            local cmd=$(ps -p $pid -o command=)
            if [[ "$cmd" == *"[mux]"* ]]; then
                echo "Killing SSH multiplexer process (PID: $pid)"
                kill $pid 2>/dev/null
            fi
        done
    fi
}
# Function to clean up all SSH ControlMaster connections
cleanup_all_ssh_controlmaster() {
    echo "Cleaning up all SSH ControlMaster connections..."
    
    # Find all socket files
    local socket_files=$(find ~/.ssh/sockets -type s 2>/dev/null)
    
    if [[ -n "$socket_files" ]]; then
        echo "Found socket files:"
        for socket in $socket_files; do
            local host=$(basename "$socket" | cut -d '@' -f 2 | cut -d '-' -f 1)
            echo "Closing connection for socket: $socket (host: $host)"
            ssh -O exit -S "$socket" "$host" 2>/dev/null
            if [[ $? -ne 0 ]]; then
                echo "Failed to close connection, removing socket file"
                rm -f "$socket" 2>/dev/null
            fi
        done
    else
        echo "No socket files found"
    fi
    
    # Also check for any SSH multiplexer processes
    local ssh_pids=$(ps aux | grep "ssh.*\[mux\]" | grep -v grep | awk '{print $2}')
    if [[ -n "$ssh_pids" ]]; then
        echo "Found SSH multiplexer processes, killing them"
        for pid in $ssh_pids; do
            echo "Killing SSH multiplexer process (PID: $pid)"
            kill $pid 2>/dev/null
        done
    fi
}
# Function to clean up all connections (both autossh and SSH ControlMaster)
cleanup_all_connections() {
    cleanup_all_autossh
    cleanup_all_ssh_controlmaster
}

# If script is executed directly (not sourced), run the function with arguments
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ $# -eq 0 ]; then
        echo "Usage: $(basename "$0") <ssh-host>"
        exit 1
    fi
    
    connect_ssh "$1"
fi
