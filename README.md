<div align="center">

# lib_msg.sh

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![POSIX Compliant](https://img.shields.io/badge/POSIX-compliant-brightgreen.svg)](https://pubs.opengroup.org/onlinepubs/9699919799/)

**A lightweight, POSIX-compliant shell library for beautiful terminal messages**

![Terminal Output Example](docs/media/usage_output.svg)

</div>

## 📋 Table of Contents

- [Quick Start](#-quick-start)
- [Overview](#-overview)
- [Installation](#-installation)
- [Basic Usage](#-basic-usage)
- [Configuration](#-configuration)
- [Public API](#-public-api)
  - [TTY and Terminal Functions](#tty-and-terminal-functions)
  - [Color Support Functions](#color-support-functions)
  - [Text Styling Functions](#text-styling-functions)
  - [Text Processing Functions](#text-processing-functions)
  - [Custom Message Output Functions](#custom-message-output-functions)
  - [Prompt Functions](#prompt-functions)
  - [Convenience Functions](#convenience-functions)
- [Examples](#-examples)
- [Troubleshooting](#-troubleshooting)
- [Testing](#-testing)
- [Performance Considerations](#-performance-considerations)
- [How It Works](#-how-it-works)
- [Developer Documentation](#-developer-documentation)
- [License](#-license)

## 🚀 Quick Start

1. **Source the library in your shell script:**

```sh
#!/bin/sh

# Source the library
. "/path/to/lib_msg.sh"

# Set your script name (optional but recommended)
SCRIPT_NAME="my-script"

# Use message functions
msg     "Script started."
info    "Here's some information."
warn    "Something to be cautious about."
err     "An error occurred (but not fatal)."
die  1  "A fatal error occurred, exiting."
```

## 📖 Overview

`lib_msg.sh` is a POSIX-compliant shell library designed to be dependency-free, primarily using shell builtins. It makes shell scripting more pleasant and robust by providing:

- Standardized, colorized message prefixes (`I:`, `W:`, `E:`)
- Automatic TTY detection for stdout and stderr
- Text wrapping based on terminal width
- ANSI color support with graceful fallbacks
- Dynamic terminal width detection
- A comprehensive public API for terminal state, text styling, and advanced formatting
- An intelligent `die` function that exits or returns based on context (direct execution vs. sourced)

## 💾 Installation

### Method 1: Download the file directly

```sh
curl -o lib_msg.sh https://raw.githubusercontent.com/ekartashov/lib_msg.sh/main/lib_msg.sh
chmod +x lib_msg.sh
```

### Method 2: Clone the repository

```sh
git clone https://github.com/ekartashov/lib_msg.sh.git
cd lib_msg.sh
```

### Usage in your scripts

Once you have the library file, source it in your shell scripts:

```sh
. "/path/to/lib_msg.sh"
```

## 🔧 Basic Usage

### Set script name (Optional but Recommended)

The library uses the `SCRIPT_NAME` environment variable for message prefixes. If not set, it defaults to `lib_msg.sh`.

```sh
SCRIPT_NAME="my_script.sh"
# Or (Won't work when target script is sourced)
# SCRIPT_NAME="${0##*/}"
```

### Standard Output Functions (stdout)

- `msg "message"`: Prints a general message with a prefix and newline
- `msgn "message"`: Same but without a trailing newline
- `info "message"`: Prints an information message with a blue "I: " prefix
- `infon "message"`: Same but without a trailing newline

### Error Output Functions (stderr)

- `err "message"`: Prints an error message with a red "E: " prefix
- `errn "message"`: Same but without a trailing newline
- `warn "message"`: Prints a warning message with a yellow "W: " prefix
- `warnn "message"`: Same but without a trailing newline
- `die <exit_code> "message"`: Prints an error message, then exits with `<exit_code>` (or returns if sourced)

## ⚙️ Configuration

You can configure the library behavior using these environment variables:

- `SCRIPT_NAME`: Sets the prefix for all messages (default: "lib_msg.sh")
- `LIB_MSG_COLOR_MODE`: Controls color output with values:
  - `auto`: Enable colors if outputting to a TTY (default)
  - `on`: Enable colors regardless of TTY status (still respects NO_COLOR)
  - `off`: Disable colors completely
  - `force_on`: Enable colors regardless of TTY status or NO_COLOR
- `NO_COLOR`: Standard environment variable that disables colors when set (unless LIB_MSG_COLOR_MODE=force_on)

## 🧰 Public API

The library provides a comprehensive public API that gives you access to all its core capabilities:

### TTY and Terminal Functions

```sh
# Check if stdout/stderr is a TTY
if [ "$(lib_msg_stdout_is_tty)" = "true" ]; then
    echo "Running in an interactive terminal"
fi

# Get terminal width
width=$(lib_msg_get_terminal_width)
echo "Terminal is $width columns wide"

# Force update terminal width from COLUMNS environment variable
lib_msg_update_terminal_width
```

### Color Support Functions

```sh
# Check if colors are enabled
if [ "$(lib_msg_colors_enabled)" = "true" ]; then
    echo "Colors are enabled"
fi

# Reinitialize color support (useful after changing environment)
lib_msg_reinit_colors
```

### Text Styling Functions

```sh
# Create a bold red style
bold_red=$(lib_msg_build_style_sequence "$_LIB_MSG_SGR_BOLD" "$_LIB_MSG_SGR_FG_RED")

# Apply the style to text
styled_text=$(lib_msg_apply_style "Important warning" "$bold_red")
echo "$styled_text"

# Or get a predefined style
highlight_style=$(lib_msg_get_style "highlight")
echo "$(lib_msg_apply_style "Highlighted text" "$highlight_style")"
```

### Text Processing Functions

```sh
# Strip ANSI codes
raw_text=$(lib_msg_strip_ansi "$styled_text")

# Wrap text to terminal width
wrapped=$(lib_msg_get_wrapped_text "A long paragraph of text that needs to be wrapped..." 0)
echo "$wrapped"
```

### Custom Message Output Functions

```sh
# Create a custom prefix with styling
success_style=$(lib_msg_get_style "success")
prefix=$(lib_msg_create_prefix "SUCCESS" "$success_style" "")

# Output a message with this prefix
lib_msg_output "Operation completed successfully" "$prefix"
```

### Prompt Functions

```sh
# Simple prompt
name=$(lib_msg_prompt "Enter your name" "User")
echo "Hello, $name!"

# Yes/No prompt
if lib_msg_prompt_yn "Continue with the operation?" "y"; then
    echo "Continuing..."
else
    echo "Operation cancelled."
fi
```

### Convenience Functions

```sh
# Create a progress bar
for i in 1 2 3 4 5; do
    progress=$(lib_msg_progress_bar "$i" 5)
    printf "\r%s" "$progress"
    sleep 1
done
echo # Final newline
```

## 📝 Examples

See the [`examples/public_api_demo.sh`](examples/public_api_demo.sh) script for a comprehensive demonstration of all public API functionality.

## ❓ Troubleshooting

### Colors not displaying correctly

1. Check if your terminal supports ANSI colors
2. Ensure `NO_COLOR` environment variable is not set
3. Try setting `LIB_MSG_COLOR_MODE="force_on"`

### Text not wrapping properly

1. Ensure `COLUMNS` environment variable is set correctly
2. Use `lib_msg_update_terminal_width` to force a refresh
3. Verify with `lib_msg_get_terminal_width` that the width is detected correctly

### Incomplete or broken styling

1. Check that your terminal supports the SGR codes you're using
2. Verify styles are being properly closed with `$_LIB_MSG_CLR_RESET`
3. Use `lib_msg_strip_ansi` to remove all ANSI codes if needed

### Performance issues with large output

1. Ensure external commands (`sed`, `tr`) are available for better performance
2. Consider preprocessing very large text before displaying
3. Review the [Performance Considerations](#-performance-considerations) section

## 🧪 Testing

The library includes a comprehensive test suite using [BATS (Bash Automated Testing System)](https://github.com/bats-core/bats-core).

### Install BATS

**Ubuntu/Debian:**
```sh
sudo apt-get update
sudo apt-get install bats
```

**macOS (using Homebrew):**
```sh
brew install bats-core
```

**Other systems:** Refer to the [BATS installation guide](https://bats-core.readthedocs.io/en/stable/installation.html).

### Initialize Required Submodules

The test suite relies on several BATS helper libraries included as Git submodules:

```sh
git submodule init
git submodule update
```

### Run Tests

```sh
# Run all tests
bats ./test/

# Run tests in parallel
bats -T test/ -j $(nproc --ignore 2)
```

For more detailed testing information, see [Testing Guide](./docs/TESTING.md).

## ⚡ Performance Considerations

Performance tests reveal significant differences between implementation methods:

- **ANSI Stripping:** Our optimized shell implementation now performs comparably to `sed` (7.86ms vs 7.76ms for 5000 chars)
- **Newline Conversion/Whitespace Removal:** `tr` command outperforms shell by 14-724x depending on input size
- **Text Wrapping:** The pure shell implementation outperforms the `awk` implementation, which is why we now exclusively use shell for text wrapping

The library automatically selects the best available implementation based on command availability, validating our hybrid approach of preferring external commands when available while maintaining shell fallbacks for portability.

**Terminal Width Impact:** Narrower terminals (40 vs 80 columns) increase processing time for larger messages by approximately 35% due to increased wrapping operations.

For detailed performance test results, see the [Testing Guide](./docs/TESTING.md#performance-test-results).

## 🔍 How It Works

- **TTY Detection:** The library checks if stdout and stderr are connected to a terminal using `[ -t 1 ]` and `[ -t 2 ]`.
- **Terminal Width:** If a TTY is detected, it attempts to get the terminal width from the `COLUMNS` environment variable.
- **Color Initialization:** If a TTY is detected, ANSI escape codes for various colors and styles are initialized.
- **Wrapping Logic:** Text is intelligently wrapped based on terminal width, handling edge cases like very long words.
- **Core Printing Logic:** Determines the correct output stream, applies colors if appropriate, and handles text wrapping.
- **Context-Aware Exiting:** The `die` function detects whether it's being called from a sourced context or directly executed script.

## 📚 Developer Documentation

Additional documents for developers, including future plans and improvement ideas:

- [Improvement Plan](./docs/IMPROVEMENT_PLAN.md): Detailed analysis of weak points and proposed actions
- [TODO List](./docs/TODO.md): Pending tasks and potential enhancements
- [Shell Functions Review](./docs/SHELL_FUNCTIONS_REVIEW.md): Review of pure shell fallback functions
- [Optimization Plan](./docs/OPTIMIZATION_PLAN.md): Strategies for improving performance

## 📄 License

This project is licensed under the GNU General Public License v3.0.
The full license text is available in [`LICENSE.md`](LICENSE.md).