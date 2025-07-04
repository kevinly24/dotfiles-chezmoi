#!/bin/bash

# chezmoi-status-check.sh
# Script to check:
# 1. Number of files with differences in chezmoi
# 2. Number of uncommitted changes in the chezmoi repository
# 3. Number of unpulled commits in the chezmoi repository
# 4. Number of unpushed commits in the chezmoi repository

# ANSI color codes
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Function to get the count of files with differences
get_diff_count() {
  local diff_count=$(chezmoi status | grep -v "^= " | wc -l | tr -d ' ')
  echo "$diff_count"
}

# Function to get the count of uncommitted changes
get_uncommitted_count() {
  # Save current directory
  local current_dir=$(pwd)
  
  # Change to chezmoi source directory
  cd "$(chezmoi source-path)" || exit 1
  
  # Count uncommitted changes (modified, added, deleted files)
  local uncommitted_count=$(git status --porcelain | wc -l | tr -d ' ')
  
  # Return to original directory
  cd "$current_dir" || exit 1
  
  echo "$uncommitted_count"
}

# Function to get the count of unpulled commits
get_unpulled_count() {
  # Save current directory
  local current_dir=$(pwd)
  
  # Change to chezmoi source directory
  cd "$(chezmoi source-path)" || exit 1
  
  # Fetch from remote without making changes
  git fetch --quiet
  
  # Count unpulled commits
  local unpulled_count=$(git rev-list --count HEAD..@{upstream} 2>/dev/null)
  
  # If the command failed (e.g., no upstream), set count to 0
  if [ $? -ne 0 ]; then
    unpulled_count=0
  fi
  
  # Return to original directory
  cd "$current_dir" || exit 1
  
  echo "$unpulled_count"
}

# Function to get the count of commits to push
get_unpushed_count() {
  # Save current directory
  local current_dir=$(pwd)
  
  # Change to chezmoi source directory
  cd "$(chezmoi source-path)" || exit 1
  
  # Count unpushed commits
  local unpushed_count=$(git rev-list --count @{upstream}..HEAD 2>/dev/null)
  
  # If the command failed (e.g., no upstream), set count to 0
  if [ $? -ne 0 ]; then
    unpushed_count=0
  fi
  
  # Return to original directory
  cd "$current_dir" || exit 1
  
  echo "$unpushed_count"
}

# Get counts
diff_count=$(get_diff_count)
uncommitted_count=$(get_uncommitted_count)
unpulled_count=$(get_unpulled_count)
unpushed_count=$(get_unpushed_count)

# Create a simple output format for use in tmux status bar
output=""
if [ "$diff_count" -ne 0 ]; then
  output+=" ${diff_count} "
fi

if [ "$uncommitted_count" -ne 0 ]; then
  output+=" ${uncommitted_count} "
fi

if [ "$unpulled_count" -ne 0 ]; then
  output+="󰅀${unpulled_count} "
fi

if [ "$unpushed_count" -ne 0 ]; then
  output+="󰅃${unpushed_count} "
fi

# Only echo if there's something to show
if [ -n "$output" ]; then
  echo -e " $output#[fg=#{@thm_overlay_0}]·"
fi
