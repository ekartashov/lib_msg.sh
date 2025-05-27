<div align="center">

# 🖥️ lib_msg.sh

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![POSIX Compliant](https://img.shields.io/badge/POSIX-compliant-brightgreen.svg)](https://pubs.opengroup.org/onlinepubs/9699919799/)
[![Shell](https://img.shields.io/badge/Shell-POSIX_sh-orange.svg)](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/sh.html)
[![Status](https://img.shields.io/badge/Status-Stable-success.svg)](https://github.com/ekartashov/lib_msg.sh)

**A lightweight, dependency-free shell library for beautiful terminal output**

![Terminal Output Example](docs/media/usage_output.svg)

</div>

## 📋 Table of Contents

- [Introduction](#-introduction)
- [Quick Start](#-quick-start)
- [Features](#-features)
- [Installation](#-installation)
- [Basic Usage](#-basic-usage)
- [Configuration](#-configuration)
- [Public API Reference](#-public-api-reference)
- [Examples](#-examples)
- [Troubleshooting](#-troubleshooting)
- [Advanced Topics](#-advanced-topics)
- [Documentation](#-documentation)
- [License](#-license)

## 📘 Introduction

`lib_msg.sh` is a modern shell library designed for developers who need reliable, professional-looking terminal output in their shell scripts. Whether you're writing system utilities, developer tools, or DevOps scripts, this library provides everything you need to create clear, colorized, and well-formatted terminal messages.

**Why use lib_msg.sh?**

- **Zero dependencies** - Works with basic POSIX shells and built-ins
- **Professional output** - Standardized, colorized message formatting
- **Context-aware** - Automatically adapts to the terminal environment
- **Intelligent text handling** - Text wrapping based on terminal width
- **Comprehensive API** - Terminal state, text styling, and advanced formatting

## 🚀 Quick Start

### Installation

Add lib_msg.sh to your project with a single command:

```sh
# Option 1: Download directly to your project
curl -o lib_msg.sh https://raw.githubusercontent.com/ekartashov/lib_msg.sh/main/lib_msg.sh

# Option 2: Clone the repository
git clone https://github.com/ekartashov/lib_msg.sh.git
```

### Basic Usage

```sh
#!/bin/sh
# Source the library
. ./lib_msg.sh

# Set your script name (recommended)
SCRIPT_NAME="my-script"

# Display formatted messages
msg   "Standard message"              # my-script: Standard message
info  "Information with blue prefix"  # my-script: I: Information with blue prefix
warn  "Warning with yellow prefix"    # my-script: W: Warning with yellow prefix
err   "Error with red prefix"         # my-script: E: Error with red prefix
die 1 "Fatal error, exits script"     # my-script: E: Fatal error, exits script
```

## ✨ Features

- **Standardized Message Formatting**
  - Consistent message prefixes with proper styling
  - Color-coded status indicators (`I:` blue, `W:` yellow, `E:` red)
  - Automatic text wrapping to terminal width

- **Smart Environment Detection**
  - Automatic TTY detection for stdout and stderr
  - Dynamic terminal width detection and adaptation
  - ANSI color support with graceful fallbacks

- **Intelligent Message Handling**
  - Text wrapping respecting terminal width
  - Proper stream handling (stdout vs stderr)
  - Context-aware `die` function (exits or returns based on context)

- **Comprehensive Public API**
  - Terminal state detection
  - Text styling and ANSI color support
  - Interactive prompts and progress indicators
  - Custom message formatting tools

## 💾 Installation

### Basic Installation

**Option 1: Direct download**
```sh
# Download to current directory
curl -o lib_msg.sh https://raw.githubusercontent.com/ekartashov/lib_msg.sh/main/lib_msg.sh

# Source in your scripts
. ./lib_msg.sh
```

**Option 2: Clone repository**
```sh
# Clone the repository
git clone https://github.com/ekartashov/lib_msg.sh.git

# Source in your scripts
. ./lib_msg.sh/lib_msg.sh
```

For system-wide installation or more advanced setups, see [INSTALLATION.md](./docs/INSTALLATION.md).

## 🔧 Basic Usage

### Message Functions

**Standard Output (stdout)**

```sh
msg "General message"              # my-script: General message
msgn "Message without newline"     # my-script: Message without newline (no line break)
info "Information message"         # my-script: I: Information message (blue prefix)
infon "Info without newline"       # my-script: I: Info without newline (no line break)
```

**Error Output (stderr)**

```sh
err "Error message"                # my-script: E: Error message (red prefix)
errn "Error without newline"       # my-script: E: Error without newline (no line break)
warn "Warning message"             # my-script: W: Warning message (yellow prefix)
warnn "Warning without newline"    # my-script: W: Warning without newline (no line break)
die 1 "Fatal error"                # my-script: E: Fatal error (red prefix, then exit)
```

### Set Your Script Name

Setting your script name is highly recommended for proper message prefixes:

```sh
# Set at the start of your script, after sourcing lib_msg.sh
SCRIPT_NAME="my-application"

# Now all messages will be prefixed with your script name
info "Starting application"        # my-application: I: Starting application
```

## ⚙️ Configuration

Configure the library using these environment variables:

| Variable | Description | Default | Options |
|----------|-------------|---------|---------|
| `SCRIPT_NAME` | Prefix for messages | `lib_msg.sh` | Any string |
| `LIB_MSG_COLOR_MODE` | Color output control | `auto` | `auto`, `on`, `off`, `force_on` |
| `NO_COLOR` | Standard var to disable colors | (not set) | Any non-empty value disables colors |
| `COLUMNS` | Terminal width | (auto-detected) | Integer column count |

**Examples:**

```sh
# Set script name for message prefixes
export SCRIPT_NAME="my-app"

# Force colors on even when output is piped
export LIB_MSG_COLOR_MODE="force_on"

# Disable colors completely
export NO_COLOR=1

# Force specific terminal width
export COLUMNS=80
```

## 🧰 Public API Reference

The library provides a comprehensive API for advanced usage. See [API_REFERENCE.md](./docs/API_REFERENCE.md) for complete documentation.

Key function categories:

- **Core Message Functions**: `msg`, `err`, `warn`, `info`, `die`, etc.
- **Terminal Detection Functions**: `lib_msg_stdout_is_tty`, `lib_msg_get_terminal_width`, etc.
- **Text Styling Functions**: `lib_msg_apply_style`, `lib_msg_get_style`, etc.
- **Text Processing Functions**: `lib_msg_strip_ansi`, `lib_msg_get_wrapped_text`, etc.
- **Prompt Functions**: `lib_msg_prompt`, `lib_msg_prompt_yn`, etc.
- **Convenience Functions**: `lib_msg_progress_bar`, `lib_msg_create_prefix`, etc.

## 📝 Examples

The library includes a comprehensive demo script that showcases all features:

```sh
# Clone the repository and run the demo
git clone https://github.com/ekartashov/lib_msg.sh.git
cd lib_msg.sh
./examples/public_api_demo.sh
```

For more examples, see [USAGE_GUIDE.md](./docs/USAGE_GUIDE.md).

## ❓ Troubleshooting

Common issues and their solutions:

| Issue | Solution |
|-------|----------|
| **Colors not displaying** | Check terminal support with `echo -e "\033[31mTest\033[0m"` <br> Verify `NO_COLOR` is not set <br> Try `export LIB_MSG_COLOR_MODE="force_on"` |
| **Text wrapping incorrectly** | Update terminal width: `export COLUMNS=$(tput cols); lib_msg_update_terminal_width` <br> Verify terminal width: `echo "Width: $(lib_msg_get_terminal_width)"` |
| **Broken styling** | Ensure you're using `lib_msg_apply_style` which handles reset codes <br> Strip ANSI codes if needed: `lib_msg_strip_ansi "$text"` |
| **Die function not exiting** | Check if script is being sourced: `(return 0 2>/dev/null) && echo "Sourced"` |

For detailed troubleshooting guidance, see [TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md).

## 🔬 Advanced Topics

### Testing

The library includes a comprehensive test suite using [BATS](https://github.com/bats-core/bats-core):

```sh
# Run tests
bats ./test/

# Run tests in parallel
bats -T test/ -j $(nproc --ignore 2)
```

For detailed testing information, see [TESTING.md](./docs/TESTING.md).

### Performance Considerations

The library optimizes performance through smart implementation selection:

- **Text Wrapping:** Pure shell implementation outperforms external commands
- **ANSI Stripping:** Optimized shell implementation performs comparably to `sed`
- **Auto-detection:** Uses best available implementation based on environment

For detailed benchmarks, see [TESTING.md](./docs/TESTING.md#performance-test-results).

## 📚 Documentation

The project includes comprehensive documentation:

**Core Documentation**
- [README.md](./README.md) - Overview and quick start guide
- [API_REFERENCE.md](./docs/API_REFERENCE.md) - Complete function documentation
- [INSTALLATION.md](./docs/INSTALLATION.md) - Detailed installation options
- [USAGE_GUIDE.md](./docs/USAGE_GUIDE.md) - Extended usage examples

**User Guides**
- [TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md) - Solutions to common issues

**Developer Documentation**
- [TESTING.md](./docs/TESTING.md) - Test suite usage and performance benchmarks
- [CONTRIBUTING.md](./docs/CONTRIBUTING.md) - Guidelines for contributors

## 📄 License

This project is licensed under the [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0).

Copyright (c) 2023-2025 [ekartashov](https://github.com/ekartashov)

The full license text is available in [`LICENSE.md`](LICENSE.md).