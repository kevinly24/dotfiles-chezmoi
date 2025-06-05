#!/bin/bash

# Script to process chezmoi templates with different environments
# and output results to tmpl_results directory

# Create output directory if it doesn't exist
mkdir -p tmpl_results

# Get the absolute path to the environments directory
ENVIRONMENTS_DIR="$(pwd)/environments"

# Find all template files in the chezmoi source directory
SOURCE_DIR=$(chezmoi source-path)
TEMPLATE_FILES=$(find "$SOURCE_DIR" -name "*.tmpl" | sort)

echo "Found $(echo "$TEMPLATE_FILES" | wc -l | tr -d ' ') template files"

# Process each environment file
for ENV_FILE in "$ENVIRONMENTS_DIR"/*.toml; do
  # Extract environment name from filename (without extension)
  ENV_NAME=$(basename "$ENV_FILE" .toml)
  echo "Processing environment: $ENV_NAME"
  
  # Create directory for this environment's results
  mkdir -p "tmpl_results/$ENV_NAME"
  
  # Process each template file with this environment
  for TMPL_FILE in $TEMPLATE_FILES; do
    # Get the relative path within the chezmoi source directory
    REL_PATH=${TMPL_FILE#"$SOURCE_DIR/"}
    
    # Get the target path (remove dot_ prefix and .tmpl suffix)
    TARGET_PATH=$(echo "$REL_PATH" | sed -e 's/^dot_//' -e 's/\.tmpl$//')
    
    # Create output directory structure
    OUTPUT_DIR="tmpl_results/$ENV_NAME/$(dirname "$TARGET_PATH")"
    mkdir -p "$OUTPUT_DIR"
    
    # Process template and save to output directory
    echo "  Processing template: $REL_PATH -> $TARGET_PATH"
    chezmoi execute-template --config="$ENV_FILE" < "$TMPL_FILE" > "tmpl_results/$ENV_NAME/$TARGET_PATH"
  done
done

echo "All templates processed. Results saved in tmpl_results directory."
