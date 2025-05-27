# Usage Guide for lib_msg.sh

This document provides detailed usage examples and patterns for the lib_msg.sh library.

## Table of Contents

- [Basic Usage](#basic-usage)
- [Script Name and Prefixes](#script-name-and-prefixes)
- [Message Types and Functions](#message-types-and-functions)
- [Terminal Detection](#terminal-detection)
- [Color Management](#color-management)
- [Text Styling](#text-styling)
- [Text Processing](#text-processing)
- [Interactive Prompts](#interactive-prompts)
- [Progress Indicators](#progress-indicators)
- [Advanced Usage Patterns](#advanced-usage-patterns)
- [Real-world Examples](#real-world-examples)

## Basic Usage

### Including the Library

Include lib_msg.sh at the beginning of your shell script:

```sh
#!/bin/sh
# Source the library
. /path/to/lib_msg.sh

# Set your script name (recommended)
SCRIPT_NAME="my-script"

# Now you can use the library functions
msg "Starting script"
```

### Basic Examples

```sh
#!/bin/sh
. ./lib_msg.sh
SCRIPT_NAME="demo"

# Standard message
msg "This is a standard message"
# Output: demo: This is a standard message

# Information message (blue prefix)
info "This is an information message"
# Output: demo: I: This is an information message

# Warning message (yellow prefix)
warn "This is a warning message"
# Output to stderr: demo: W: This is a warning message

# Error message (red prefix)
err "This is an error message"
# Output to stderr: demo: E: This is an error message

# Fatal error (exits with code 1)
die 1 "This is a fatal error"
# Output to stderr: demo: E: This is a fatal error
# Then exits with code 1 (or returns 1 if sourced)
```

## Script Name and Prefixes

Setting your script name is important for creating consistent, identifiable message prefixes:

```sh
#!/bin/sh
. ./lib_msg.sh

# Default behavior (no SCRIPT_NAME set)
msg "Hello world"
# Output: lib_msg.sh: Hello world

# Set custom script name
SCRIPT_NAME="my-app"
msg "Hello world"
# Output: my-app: Hello world

# Change script name for a different component
SCRIPT_NAME="my-app-setup"
msg "Starting setup"
# Output: my-app-setup: Starting setup
```

## Message Types and Functions

### Standard Output Functions

Functions that output to stdout:

```sh
# Basic message with newline
msg "Standard message"
# Output: my-script: Standard message

# Message without newline
msgn "Enter value: "
# Output: my-script: Enter value: [cursor stays on same line]

# Information message with newline
info "Information message"
# Output: my-script: I: Information message

# Information message without newline
infon "Processing... "
# Output: my-script: I: Processing... [cursor stays on same line]
```

### Error Output Functions

Functions that output to stderr:

```sh
# Warning message with newline
warn "Warning message"
# Output to stderr: my-script: W: Warning message

# Warning message without newline
warnn "Checking... "
# Output to stderr: my-script: W: Checking... [cursor stays on same line]

# Error message with newline
err "Error message"
# Output to stderr: my-script: E: Error message

# Error message without newline
errn "Retrying... "
# Output to stderr: my-script: E: Retrying... [cursor stays on same line]

# Fatal error (exit with specified code)
die 1 "Fatal error"
# Output to stderr: my-script: E: Fatal error
# Then exits with code 1 (or returns 1 if sourced)

# Fatal error with default exit code 1
die "Fatal error"
# Same as die 1 "Fatal error"
```

## Terminal Detection

The library provides functions to detect terminal capabilities:

```sh
#!/bin/sh
. ./lib_msg.sh
SCRIPT_NAME="terminal-demo"

# Check if stdout is a terminal
if [ "$(lib_msg_stdout_is_tty)" = "true" ]; then
    msg "Output is going to a terminal"
else
    msg "Output is being redirected or piped"
fi

# Check if stderr is a terminal
if [ "$(lib_msg_stderr_is_tty)" = "true" ]; then
    msg "Error output is going to a terminal"
else
    msg "Error output is being redirected or piped"
fi

# Get current terminal width
width=$(lib_msg_get_terminal_width)
msg "Terminal width is $width columns"

# Demo of output behavior
msg "This is normal terminal output"
msg "This is normal terminal output" > output.txt  # Redirected to file

# Demo with piping
msg "This text is going to a pipe" | cat
```

## Color Management

Control color output with environment variables:

```sh
#!/bin/sh
. ./lib_msg.sh
SCRIPT_NAME="color-demo"

# Default: auto-detect color support
info "Colors are auto-detected"

# Force colors on
export LIB_MSG_COLOR_MODE="on"
lib_msg_reinit_colors
info "Colors are forced on"

# Force colors on even when piped
export LIB_MSG_COLOR_MODE="force_on"
lib_msg_reinit_colors
info "Colors remain on even when piped" | cat

# Force colors off
export LIB_MSG_COLOR_MODE="off"
lib_msg_reinit_colors
info "Colors are disabled"

# Use standard NO_COLOR environment variable
export NO_COLOR=1
lib_msg_reinit_colors
info "Colors are disabled via NO_COLOR"

# Check current color status
if [ "$(lib_msg_colors_enabled)" = "true" ]; then
    msg "Colors are currently enabled"
else
    msg "Colors are currently disabled"
fi
```

## Text Styling

Apply ANSI styles to your text:

```sh
#!/bin/sh
. ./lib_msg.sh
SCRIPT_NAME="styling-demo"

# Get predefined styles
error_style=$(lib_msg_get_style "error")
warning_style=$(lib_msg_get_style "warning")
info_style=$(lib_msg_get_style "info")
success_style=$(lib_msg_get_style "success")
highlight_style=$(lib_msg_get_style "highlight")
dim_style=$(lib_msg_get_style "dim")

# Apply styles to text
echo "Plain text vs $(lib_msg_apply_style "Error styled" "$error_style") text"
echo "Plain text vs $(lib_msg_apply_style "Warning styled" "$warning_style") text"
echo "Plain text vs $(lib_msg_apply_style "Info styled" "$info_style") text"
echo "Plain text vs $(lib_msg_apply_style "Success styled" "$success_style") text"
echo "Plain text vs $(lib_msg_apply_style "Highlighted" "$highlight_style") text"
echo "Plain text vs $(lib_msg_apply_style "Dimmed" "$dim_style") text"

# Create custom styles using SGR codes
bold_blue=$(lib_msg_build_style_sequence "$_LIB_MSG_SGR_BOLD" "$_LIB_MSG_SGR_FG_BLUE")
italic_yellow=$(lib_msg_build_style_sequence "$_LIB_MSG_SGR_ITALIC" "$_LIB_MSG_SGR_FG_YELLOW")
bg_red=$(lib_msg_build_style_sequence "$_LIB_MSG_SGR_BG_RED")

echo "$(lib_msg_apply_style "Bold blue text" "$bold_blue")"
echo "$(lib_msg_apply_style "Italic yellow text" "$italic_yellow")"
echo "$(lib_msg_apply_style "Red background" "$bg_red")"

# Apply style only if output is to a terminal
styled_if_tty=$(lib_msg_apply_style_if_tty "This is styled only if to TTY" "$highlight_style")
echo "$styled_if_tty"
echo "$styled_if_tty" > /tmp/styled_output.txt  # Will be plain text
```

## Text Processing

Process text with library utilities:

```sh
#!/bin/sh
. ./lib_msg.sh
SCRIPT_NAME="text-demo"

# Strip ANSI escape sequences
styled_text=$(lib_msg_apply_style "Colored text" "$(lib_msg_get_style "info")")
plain_text=$(lib_msg_strip_ansi "$styled_text")

echo "Original: $styled_text"
echo "Stripped: $plain_text"
echo "Original length with ANSI: ${#styled_text} chars"
echo "Actual text length: ${#plain_text} chars"

# Wrap text to specific width
long_text="This is a very long paragraph that should be wrapped to fit within a specific width. Text wrapping ensures your output looks clean and professional, especially when displaying large blocks of text in the terminal."

msg "Text wrapped to 40 columns:"
wrapped_text=$(lib_msg_get_wrapped_text "$long_text" 40)
echo "$wrapped_text"

msg "Text wrapped to terminal width:"
auto_wrapped=$(lib_msg_get_wrapped_text "$long_text" 0)
echo "$auto_wrapped"

# Demonstrate text wrapping in messages
info "$long_text"  # Automatically wrapped to terminal width
```

## Interactive Prompts

Create interactive prompts for user input:

```sh
#!/bin/sh
. ./lib_msg.sh
SCRIPT_NAME="prompt-demo"

# Basic text prompt
name=$(lib_msg_prompt "Enter your name")
msg "Hello, $name!"

# Prompt with default value
path=$(lib_msg_prompt "Enter config path" "./config.json")
msg "Using config path: $path"

# Styled prompt
highlight_style=$(lib_msg_get_style "highlight")
email=$(lib_msg_prompt "Enter your email address" "" "$highlight_style")
msg "Email: $email"

# Yes/No prompt (no default)
if lib_msg_prompt_yn "Do you want to continue?"; then
    info "Continuing..."
else
    warn "Operation cancelled by user"
fi

# Yes/No prompt with default "yes"
if lib_msg_prompt_yn "Save changes?" "y"; then
    info "Saving changes..."
else
    warn "Changes not saved"
fi

# Yes/No prompt with default "no" and styling
warning_style=$(lib_msg_get_style "warning")
if lib_msg_prompt_yn "Delete all files? (dangerous)" "n" "$warning_style"; then
    err "Deleting files..."
else
    info "Operation cancelled"
fi
```

## Progress Indicators

Show progress for long operations:

```sh
#!/bin/sh
. ./lib_msg.sh
SCRIPT_NAME="progress-demo"

# Simple progress indicator
infon "Downloading... "
sleep 1  # Simulating work
echo "done"

# Progress bar with default characters
total=10
for i in $(seq 1 $total); do
    progress=$(lib_msg_progress_bar "$i" "$total" 30)
    printf "\rProgress: %s" "$progress"
    sleep 0.3  # Simulate work
done
echo  # Final newline

# Progress bar with custom characters
total=5
for i in $(seq 1 $total); do
    bar=$(lib_msg_progress_bar "$i" "$total" 20 "=" " ")
    printf "\rProcessing: %s" "$bar"
    sleep 0.5  # Simulate work
done
echo  # Final newline

# Progress bar with styled characters
total=8
highlight_style=$(lib_msg_get_style "highlight")
for i in $(seq 1 $total); do
    filled=$(lib_msg_apply_style "#" "$highlight_style")
    bar=$(lib_msg_progress_bar "$i" "$total" 15 "$filled" "-")
    printf "\rDownloading: %s" "$bar"
    sleep 0.4  # Simulate work
done
echo  # Final newline
```

## Advanced Usage Patterns

### Custom Message Formatting

Create custom message formats:

```sh
#!/bin/sh
. ./lib_msg.sh
SCRIPT_NAME="custom-demo"

# Create custom prefixes with styling
info_style=$(lib_msg_get_style "info")
warning_style=$(lib_msg_get_style "warning")
error_style=$(lib_msg_get_style "error")
success_style=$(lib_msg_get_style "success")

# Create styled prefixes
debug_prefix=$(lib_msg_create_prefix "DEBUG" "$dim_style")
status_prefix=$(lib_msg_create_prefix "STATUS" "$info_style")
success_prefix=$(lib_msg_create_prefix "SUCCESS" "$success_style")
fail_prefix=$(lib_msg_create_prefix "FAIL" "$error_style")

# Output with custom prefixes
lib_msg_output "Debug information" "$debug_prefix"
lib_msg_output "Status update" "$status_prefix"
lib_msg_output "Operation succeeded" "$success_prefix"
lib_msg_output "Operation failed" "$fail_prefix" "" "true"  # To stderr

# Custom prefix with custom bracket style
tag_style=$(lib_msg_get_style "warning")
bracket_style=$(lib_msg_build_style_sequence "$_LIB_MSG_SGR_FG_CYAN")
custom_prefix=$(lib_msg_create_prefix "NOTE" "$tag_style" "$bracket_style")
lib_msg_output "This is an important note" "$custom_prefix"
```

### Dynamic Terminal Width Handling

Work with changing terminal dimensions:

```sh
#!/bin/sh
. ./lib_msg.sh
SCRIPT_NAME="width-demo"

# Show current terminal width
current_width=$(lib_msg_get_terminal_width)
msg "Current terminal width: $current_width columns"

# Simulate terminal resize
msg "After terminal resize, update width:"
export COLUMNS=100  # Simulate changed width
lib_msg_update_terminal_width
new_width=$(lib_msg_get_terminal_width)
msg "Updated terminal width: $new_width columns"

# Demonstrate auto-wrapping behavior
long_text="This text will automatically wrap according to the current terminal width setting. When the terminal is resized, you should call lib_msg_update_terminal_width to ensure wrapping adapts to the new dimensions."
msg "Text with original width:"
info "$long_text"

# Text with new width
export COLUMNS=50
lib_msg_update_terminal_width
msg "Text with narrower width (50 columns):"
info "$long_text"
```

## Real-world Examples

### Configuration Script

```sh
#!/bin/sh
. ./lib_msg.sh
SCRIPT_NAME="config-tool"

CONFIG_FILE="app_config.json"

info "Welcome to the Configuration Tool"
info "This utility helps you configure your application settings"

# Check for existing config
if [ -f "$CONFIG_FILE" ]; then
    info "Found existing configuration file"
    if ! lib_msg_prompt_yn "Do you want to overwrite it?" "n"; then
        die 0 "Configuration cancelled. Existing file preserved."
    fi
fi

# Collect configuration data
info "Please provide the following configuration details:"

# Use prompts with defaults and styling
highlight_style=$(lib_msg_get_style "highlight")
server=$(lib_msg_prompt "Server address" "localhost" "$highlight_style")
port=$(lib_msg_prompt "Server port" "8080" "$highlight_style")
user=$(lib_msg_prompt "Username" "$USER" "$highlight_style")
timeout=$(lib_msg_prompt "Connection timeout (seconds)" "30" "$highlight_style")

# Confirm settings
info "Configuration Summary:"
msg "Server: $server"
msg "Port: $port"
msg "User: $user"
msg "Timeout: ${timeout}s"

if ! lib_msg_prompt_yn "Save this configuration?" "y"; then
    die 0 "Configuration cancelled by user."
fi

# Simulate saving configuration
infon "Saving configuration... "
sleep 1  # Simulate work

# Create JSON config
cat > "$CONFIG_FILE" <<EOF
{
  "server": "$server",
  "port": "$port",
  "user": "$user",
  "timeout": $timeout
}
EOF

echo "done"
info "Configuration saved to $CONFIG_FILE"
```

### Deployment Script

```sh
#!/bin/sh
. ./lib_msg.sh
SCRIPT_NAME="deploy-app"

# Simulate deployment steps
deploy() {
    local total_steps=5
    
    info "Starting deployment process"
    
    # Step 1: Build application
    infon "Building application... "
    sleep 1  # Simulate work
    echo "done"
    
    # Step 2: Run tests with progress bar
    info "Running tests..."
    local tests=10
    for i in $(seq 1 $tests); do
        progress=$(lib_msg_progress_bar "$i" "$tests" 30)
        printf "\rTest progress: %s" "$progress"
        sleep 0.3  # Simulate work
    done
    echo  # Final newline
    
    # Step 3: Package application
    infon "Packaging application... "
    sleep 1.5  # Simulate work
    echo "done"
    
    # Step 4: Upload with progress bar
    info "Uploading to server..."
    local chunks=8
    for i in $(seq 1 $chunks); do
        progress=$(lib_msg_progress_bar "$i" "$chunks" 30)
        printf "\rUpload progress: %s" "$progress"
        sleep 0.5  # Simulate work
    done
    echo  # Final newline
    
    # Step 5: Finalize deployment
    infon "Finalizing deployment... "
    sleep 1  # Simulate work
    echo "done"
    
    # Success message
    success_style=$(lib_msg_get_style "success")
    success_prefix=$(lib_msg_create_prefix "SUCCESS" "$success_style")
    lib_msg_output "Deployment completed successfully!" "$success_prefix"
}

# Error handling example
handle_error() {
    err "Deployment failed: $1"
    
    if lib_msg_prompt_yn "Do you want to retry?" "y"; then
        info "Retrying deployment..."
        deploy
    else
        die 1 "Deployment aborted by user"
    fi
}

# Main execution
if ! command -v curl >/dev/null 2>&1; then
    handle_error "curl command not found"
else
    deploy
fi
```

### Log Processing Script

```sh
#!/bin/sh
. ./lib_msg.sh
SCRIPT_NAME="log-analyzer"

# Process log file with color-coded output
process_log() {
    local log_file="$1"
    local line_count=0
    local error_count=0
    local warning_count=0
    
    info "Analyzing log file: $log_file"
    
    # Get total lines
    total=$(wc -l < "$log_file")
    
    # Error style
    error_style=$(lib_msg_get_style "error")
    warning_style=$(lib_msg_get_style "warning")
    info_style=$(lib_msg_get_style "info")
    
    # Process each line
    while IFS= read -r line; do
        line_count=$((line_count + 1))
        
        # Show progress every 100 lines
        if [ $((line_count % 100)) -eq 0 ]; then
            progress=$(lib_msg_progress_bar "$line_count" "$total" 30)
            printf "\rAnalyzing: %s" "$progress"
        fi
        
        # Classify and count lines
        case "$line" in
            *ERROR*|*FATAL*)
                error_count=$((error_count + 1))
                ;;
            *WARN*|*WARNING*)
                warning_count=$((warning_count + 1))
                ;;
        esac
    done < "$log_file"
    
    echo  # Final newline after progress bar
    
    # Output results with styling
    msg "Log analysis complete: $log_file"
    echo "$(lib_msg_apply_style "Errors:   $error_count" "$error_style")"
    echo "$(lib_msg_apply_style "Warnings: $warning_count" "$warning_style")"
    echo "$(lib_msg_apply_style "Total:    $line_count lines" "$info_style")"
}

# Example usage
if [ $# -eq 0 ]; then
    die 1 "Usage: $0 <log_file>"
fi

if [ ! -f "$1" ]; then
    die 1 "Error: Log file not found: $1"
fi

process_log "$1"
```

These examples demonstrate how to effectively use lib_msg.sh for a variety of common scripting tasks. Adapt them to your specific needs and refer to the [API Reference](API_REFERENCE.md) for complete details on all available functions.