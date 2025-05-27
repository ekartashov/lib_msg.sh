# Installation Guide for lib_msg.sh

This document provides detailed instructions for installing and incorporating the lib_msg.sh library into your projects.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation Methods](#installation-methods)
  - [Direct Download](#direct-download)
  - [Git Clone](#git-clone)
  - [Manual Integration](#manual-integration)
- [Integration Methods](#integration-methods)
  - [Direct Source](#direct-source)
  - [Submodule Integration](#submodule-integration)
  - [Copy Integration](#copy-integration)
- [Shell Compatibility](#shell-compatibility)
- [Configuration](#configuration)
- [Validation](#validation)
- [Advanced Installation](#advanced-installation)
- [Uninstallation](#uninstallation)

## Prerequisites

`lib_msg.sh` is designed to be lightweight and dependency-free. The only requirement is the shell itself:

- A POSIX-compliant shell (sh, bash, dash, ksh, zsh, etc.)

The library uses pure shell implementations for all functionality, making it suitable for even the most minimal environments.

## Installation Methods

### Direct Download

The simplest installation method is to download the library file directly:

```sh
# Create a directory for the library if needed
mkdir -p ~/lib

# Download the library
curl -o ~/lib/lib_msg.sh https://raw.githubusercontent.com/ekartashov/lib_msg.sh/main/lib_msg.sh

# Make it executable (optional, as it's normally sourced)
chmod +x ~/lib/lib_msg.sh
```

### Git Clone

If you want to keep up with updates or contribute to the library:

```sh
# Clone the repository
git clone https://github.com/ekartashov/lib_msg.sh.git

# Optionally, move just the library file to your preferred location
cp lib_msg.sh/lib_msg.sh ~/lib/
```

### Manual Integration

For simple standalone scripts or utilities:

```sh
# Download the library directly to your project directory
curl -o lib_msg.sh https://raw.githubusercontent.com/ekartashov/lib_msg.sh/main/lib_msg.sh
```


(Note: This library is not currently available through package managers)

## Integration Methods

There are several ways to integrate the library into your projects:

### Direct Source

The simplest method is to source the library directly from an absolute path:

```sh
#!/bin/sh
# Source lib_msg.sh from its installed location
. "$HOME/lib/lib_msg.sh"

# Use the library
SCRIPT_NAME="my-script"
info "Script started"
```

### Submodule Integration

For git projects, you can include lib_msg.sh as a git submodule:

```sh
# Add as a submodule to your project
cd your-project
git submodule add https://github.com/ekartashov/lib_msg.sh.git lib/lib_msg

# In your script, source it relative to the script location
#!/bin/sh
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
. "$SCRIPT_DIR/lib/lib_msg/lib_msg.sh"
```

### Copy Integration

For standalone scripts or when you want to ensure the library is always available:

```sh
# Copy the library directly into your project
cp ~/lib/lib_msg.sh your-project/lib/

# In your script, source it relative to the script
#!/bin/sh
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
. "$SCRIPT_DIR/lib/lib_msg.sh"
```

### Relative Path with Fallback

For scripts that might be run from various locations:

```sh
#!/bin/sh
# Try to find lib_msg.sh in several common locations
if [ -f "./lib_msg.sh" ]; then
    . "./lib_msg.sh"
elif [ -f "./lib/lib_msg.sh" ]; then
    . "./lib/lib_msg.sh"
elif [ -f "$HOME/lib/lib_msg.sh" ]; then
    . "$HOME/lib/lib_msg.sh"
else
    echo "Error: Could not find lib_msg.sh" >&2
    exit 1
fi
```

## Shell Compatibility

### Shell Support

This library is designed for POSIX-compliant shells. It has been tested with:
- bash (version 3.2+)
- dash
- ksh
- zsh (in sh emulation mode)

No shell-specific features are required, as the library uses only standard POSIX shell constructs.

### Platform Notes

The library is designed to work on any POSIX-compliant system, including:
- Linux (all distributions)
- macOS
- FreeBSD, OpenBSD, and other BSD variants
- Embedded Linux systems
- MinGW/MSYS2 and Git Bash on Windows

For optimal performance, the library will use external commands like `sed` and `tr` when available, but will fall back to pure shell implementations when these commands are not present.


## Configuration

After installation, configure the library's behavior with environment variables:

```sh
# Set your script name
export SCRIPT_NAME="my-application"

# Configure color behavior
export LIB_MSG_COLOR_MODE="auto"  # Options: auto, on, off, force_on

# Disable colors completely (honored unless LIB_MSG_COLOR_MODE=force_on)
export NO_COLOR=1
```

Permanent configuration can be added to your shell profile:

```sh
# Add to ~/.bashrc, ~/.zshrc, etc.
if [ -f "$HOME/lib/lib_msg.sh" ]; then
    export LIB_MSG_COLOR_MODE="auto"
    # ... other configurations
fi
```

## Validation

After installation, verify that the library works correctly:

```sh
#!/bin/sh

# Source the library
. "$HOME/lib/lib_msg.sh"

# Test basic functionality
SCRIPT_NAME="validation-test"
msg "Basic message test"
info "Information message test"
warn "Warning message test"
err "Error message test"

# Test TTY detection
echo "stdout is TTY: $(lib_msg_stdout_is_tty)"
echo "stderr is TTY: $(lib_msg_stderr_is_tty)"
echo "Terminal width: $(lib_msg_get_terminal_width)"
echo "Colors enabled: $(lib_msg_colors_enabled)"

# Test styling
echo "$(lib_msg_apply_style "Styled text test" "$(lib_msg_get_style "highlight")")"

echo "Validation complete. If you see properly formatted and colored messages, the installation is successful."
```

Save this as `validate_lib_msg.sh`, make it executable with `chmod +x validate_lib_msg.sh`, and run it to verify your installation.

## Advanced Installation

### Multi-user Installation

For system-wide installation:

```sh
# Install to a shared location
sudo mkdir -p /usr/local/lib
sudo cp lib_msg.sh /usr/local/lib/

# Make it available to all users
echo '. /usr/local/lib/lib_msg.sh' | sudo tee /etc/profile.d/lib_msg.sh
```

### Versioned Installation

To maintain multiple versions:

```sh
# Create versioned directory
mkdir -p ~/lib/lib_msg/1.0

# Install specific version
cp lib_msg.sh ~/lib/lib_msg/1.0/

# Create symlink to current version
ln -sf ~/lib/lib_msg/1.0/lib_msg.sh ~/lib/lib_msg.sh
```

This allows you to switch between versions by updating the symlink.

## Uninstallation

To remove the library:

```sh
# Remove single file installation
rm ~/lib/lib_msg.sh

# Or remove git repository
rm -rf path/to/lib_msg.sh/

# If installed as a submodule
git submodule deinit -f path/to/lib_msg
git rm -f path/to/lib_msg
rm -rf .git/modules/path/to/lib_msg