#!bin/bash

# Function to copy text to clipboard, using pbcopy on macOS or xsel on Linux
clipboard_copy() {
  # Check if any input is provided
  if [ -z "$1" ] && [ -t 0 ]; then
    echo "Usage: clipboard_copy <text> or echo <text> | clipboard_copy"
    return 1
  fi

  # Detect the operating system
  case "$(uname -s)" in
    Darwin*)
      # macOS - use pbcopy
      if [ -n "$1" ]; then
        echo -n "$1" | pbcopy
      else
        pbcopy
      fi
      ;;
    Linux*)
      # Linux - use xsel if available
      if command -v xsel >/dev/null 2>&1; then
        if [ -n "$1" ]; then
          echo -n "$1" | xsel --clipboard --input
        else
          xsel --clipboard --input
        fi
      elif command -v xclip >/dev/null 2>&1; then
        # Fallback to xclip if xsel is not available
        if [ -n "$1" ]; then
          echo -n "$1" | xclip -selection clipboard
        else
          xclip -selection clipboard
        fi
      else
        echo "Error: Neither xsel nor xclip is installed. Please install one of them."
        return 1
      fi
      ;;
    *)
      echo "Unsupported operating system"
      return 1
      ;;
  esac
}

# Function to paste text from clipboard, using pbpaste on macOS or xsel on Linux
clipboard_paste() {
  # Detect the operating system
  case "$(uname -s)" in
    Darwin*)
      # macOS - use pbpaste
      pbpaste
      ;;
    Linux*)
      # Linux - use xsel if available
      if command -v xsel >/dev/null 2>&1; then
        xsel --clipboard --output
      elif command -v xclip >/dev/null 2>&1; then
        # Fallback to xclip if xsel is not available
        xclip -selection clipboard -o
      else
        echo "Error: Neither xsel nor xclip is installed. Please install one of them." >&2
        return 1
      fi
      ;;
    *)
      echo "Unsupported operating system" >&2
      return 1
      ;;
  esac
}
