# lib_msg.sh Quick Start Guide

A fast introduction to using the lib_msg.sh library for formatted terminal messages.

## Installation

Add to your project with a single command:

```sh
# Option 1: Copy directly to your project
curl -o lib_msg.sh https://raw.githubusercontent.com/ekartashov/lib_msg.sh/main/lib_msg.sh

# Option 2: Clone the repository
git clone https://github.com/ekartashov/lib_msg.sh.git
```

See [INSTALLATION.md](./INSTALLATION.md) for more options.

## Basic Usage

1. Source the library in your script:

```sh
#!/bin/sh
. ./lib_msg.sh
```

2. Set your script name (optional but recommended):

```sh
SCRIPT_NAME="myscript"
```

3. Use the message functions:

```sh
# Standard message
msg "Hello world"              # Output: myscript: Hello world

# Colored status messages
info "Loading configuration"   # Blue info prefix
warn "File not found"          # Yellow warning prefix
err "Connection failed"        # Red error prefix

# Exit with error message
die 1 "Critical error"         # Prints error and exits with code 1
```

## Common Use Cases

### Interactive Prompts

```sh
# Yes/No prompt
if [ "$(lib_msg_prompt_yn "Continue with installation?" "y")" = "true" ]; then
    info "Continuing installation..."
else
    warn "Installation cancelled by user"
    exit 0
fi

# Text input with default
config_path=$(lib_msg_prompt "Enter config path" "./config.json")
```

### Progress Indicators

```sh
# Simple progress indicators
infon "Downloading... "  # No newline
# ... do work ...
msg "done"

# Progress bar
total=10
for i in $(seq 1 $total); do
    bar=$(lib_msg_progress_bar "$i" "$total" 30)
    printf "\rProgress: %s" "$bar"
    sleep 0.5
done
echo
```

### Custom Styling

```sh
# Apply custom styles
highlight_style=$(lib_msg_get_style "highlight")
echo "$(lib_msg_apply_style "Important information" "$highlight_style")"

# Build custom style
custom_style=$(lib_msg_build_style_sequence "$_LIB_MSG_SGR_BOLD" "$_LIB_MSG_SGR_FG_GREEN")
echo "$(lib_msg_apply_style "Success" "$custom_style")"
```

### Error Handling

```sh
# Check command success
if ! command -v jq >/dev/null 2>&1; then
    die 1 "Required command 'jq' not found"
fi

# Handle command errors
if ! output=$(some_command 2>&1); then
    err "Command failed: $output"
    exit 1
fi
```

## Performance Tips

- The library automatically detects TTY capabilities and terminal width
- Use `lib_msg_strip_ansi` when calculating string lengths with ANSI colors
- Set `LIB_MSG_COLOR_MODE="off"` if you know colors aren't needed

## Where to Find More

- [API_REFERENCE.md](./API_REFERENCE.md) - Complete function documentation
- [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) - Solving common issues
- [Examples directory](../examples/) - More usage examples