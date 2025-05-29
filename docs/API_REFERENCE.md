# API Reference for lib_msg.sh

This document provides a complete reference for all public functions available in the lib_msg.sh library.

## Table of Contents

- [Core Message Functions](#core-message-functions)
- [Terminal Detection Functions](#terminal-detection-functions)
- [Color Support Functions](#color-support-functions)
- [Text Styling Functions](#text-styling-functions)
- [Text Processing Functions](#text-processing-functions)
- [Custom Message Output Functions](#custom-message-output-functions)
- [Prompt Functions](#prompt-functions)
- [Convenience Functions](#convenience-functions)
- [Environment Variables](#environment-variables)
- [SGR (Select Graphic Rendition) Constants](#sgr-select-graphic-rendition-constants)

## Core Message Functions

These are the primary functions for displaying formatted messages.

### `msg`

Prints a general message to stdout with script name prefix and newline.

**Usage:**
```sh
msg "Your message here"
```

**Example:**
```sh
SCRIPT_NAME="demo"
msg "Script started successfully"
# Output: demo: Script started successfully
```

### `msgn`

Prints a general message to stdout with script name prefix but no trailing newline.

**Usage:**
```sh
msgn "Your message here"
```

**Example:**
```sh
msgn "Enter value: "
read value
# Output: demo: Enter value: [cursor remains on same line]
```

### `info`

Prints an information message to stdout with blue "I:" prefix and newline.

**Usage:**
```sh
info "Your information message here"
```

**Example:**
```sh
info "Configuration loaded from ~/.config/app"
# Output: demo: I: Configuration loaded from ~/.config/app
# (with "I:" in blue if colors enabled)
```

### `infon`

Prints an information message to stdout with blue "I:" prefix but no trailing newline.

**Usage:**
```sh
infon "Your information message here"
```

**Example:**
```sh
infon "Processing... "
# Output: demo: I: Processing... [cursor remains on same line]
```

### `warn`

Prints a warning message to stderr with yellow "W:" prefix and newline.

**Usage:**
```sh
warn "Your warning message here"
```

**Example:**
```sh
warn "Config file not found, using defaults"
# Output to stderr: demo: W: Config file not found, using defaults
# (with "W:" in yellow if colors enabled)
```

### `warnn`

Prints a warning message to stderr with yellow "W:" prefix but no trailing newline.

**Usage:**
```sh
warnn "Your warning message here"
```

**Example:**
```sh
warnn "Retrying in 5 seconds... "
# Output to stderr: demo: W: Retrying in 5 seconds... [cursor remains on same line]
```

### `err`

Prints an error message to stderr with red "E:" prefix and newline.

**Usage:**
```sh
err "Your error message here"
```

**Example:**
```sh
err "Failed to connect to server"
# Output to stderr: demo: E: Failed to connect to server
# (with "E:" in red if colors enabled)
```

### `errn`

Prints an error message to stderr with red "E:" prefix but no trailing newline.

**Usage:**
```sh
errn "Your error message here"
```

**Example:**
```sh
errn "Connection failed. Retrying... "
# Output to stderr: demo: E: Connection failed. Retrying... [cursor remains on same line]
```

### `die`

Prints an error message to stderr, then exits the script with the specified code (or returns if sourced).

**Usage:**
```sh
die <exit_code> "Your error message here"
```

**Example:**
```sh
die 1 "Critical error: Unable to access required file"
# Output to stderr: demo: E: Critical error: Unable to access required file
# Then exits with code 1 (or returns 1 if sourced)
```

If the first argument is not a number, it's treated as part of the message and exit code defaults to 1:

```sh
die "Critical error"
# Same as: die 1 "Critical error"
```

## Terminal Detection Functions

Functions for checking terminal capabilities and dimensions.

### `lib_msg_stdout_is_tty`

Checks if stdout is a terminal (TTY).

**Usage:**
```sh
lib_msg_stdout_is_tty
```

**Returns:** String "true" if stdout is a TTY, "false" otherwise.

**Example:**
```sh
if [ "$(lib_msg_stdout_is_tty)" = "true" ]; then
    echo "Output is going to a terminal"
else
    echo "Output is being redirected or piped"
fi
```

### `lib_msg_stderr_is_tty`

Checks if stderr is a terminal (TTY).

**Usage:**
```sh
lib_msg_stderr_is_tty
```

**Returns:** String "true" if stderr is a TTY, "false" otherwise.

**Example:**
```sh
if [ "$(lib_msg_stderr_is_tty)" = "true" ]; then
    echo "Error output is going to a terminal"
else
    echo "Error output is being redirected or piped"
fi
```

### `lib_msg_get_terminal_width`

Gets the current terminal width in columns.

**Usage:**
```sh
lib_msg_get_terminal_width
```

**Returns:** Integer representing terminal width in columns, or 0 if not a TTY or width unknown.

**Example:**
```sh
width=$(lib_msg_get_terminal_width)
if [ "$width" -gt 0 ]; then
    echo "Terminal is $width columns wide"
else
    echo "Not a TTY or terminal width unknown"
fi
```

### `lib_msg_update_terminal_width`

Forces updating the terminal width from the current `COLUMNS` environment variable.

**Usage:**
```sh
lib_msg_update_terminal_width
```

**Returns:** The updated terminal width.

**Example:**
```sh
# After terminal has been resized
export COLUMNS=$(tput cols)
lib_msg_update_terminal_width
echo "Updated terminal width: $(lib_msg_get_terminal_width)"
```

## Color Support Functions

Functions for handling color support detection and management.

### `lib_msg_colors_enabled`

Checks if color output is currently enabled.

**Usage:**
```sh
lib_msg_colors_enabled
```

**Returns:** String "true" if colors are enabled, "false" otherwise.

**Example:**
```sh
if [ "$(lib_msg_colors_enabled)" = "true" ]; then
    echo "Colors are enabled"
else
    echo "Colors are disabled"
fi
```

### `lib_msg_reinit_colors`

Reinitializes color support based on current environment. Useful after changing relevant environment variables.

**Usage:**
```sh
lib_msg_reinit_colors
```

**Returns:** String "true" if colors are now enabled, "false" otherwise.

**Example:**
```sh
# Disable colors
export NO_COLOR=1
lib_msg_reinit_colors
echo "Colors enabled: $(lib_msg_colors_enabled)"  # Should be "false"

# Re-enable colors
unset NO_COLOR
export LIB_MSG_COLOR_MODE="on"
lib_msg_reinit_colors
echo "Colors enabled: $(lib_msg_colors_enabled)"  # Should be "true"
```

## Text Styling Functions

Functions for creating and applying ANSI text styles.

### `lib_msg_build_style_sequence`

Builds an ANSI style sequence from SGR (Select Graphic Rendition) codes.

**Usage:**
```sh
lib_msg_build_style_sequence <sgr_code1> [sgr_code2] [...]
```

**Returns:** ANSI escape sequence for the specified style, or empty string if colors are disabled.

**Example:**
```sh
# Create a bold blue style
bold_blue=$(lib_msg_build_style_sequence "$_LIB_MSG_SGR_BOLD" "$_LIB_MSG_SGR_FG_BLUE")
echo "${bold_blue}This text is bold and blue${_LIB_MSG_CLR_RESET}"

# Create an underlined yellow on black style
special_style=$(lib_msg_build_style_sequence "$_LIB_MSG_SGR_UNDERLINE" "$_LIB_MSG_SGR_FG_YELLOW" "$_LIB_MSG_SGR_BG_BLACK")
echo "${special_style}Warning: Important!${_LIB_MSG_CLR_RESET}"
```

### `lib_msg_apply_style`

Applies a style sequence to text, handling the reset code automatically.

**Usage:**
```sh
lib_msg_apply_style <text> <style_sequence>
```

**Returns:** The text with the style applied if colors are enabled, otherwise the original text.

**Example:**
```sh
# Apply a custom style to text
bold_green=$(lib_msg_build_style_sequence "$_LIB_MSG_SGR_BOLD" "$_LIB_MSG_SGR_FG_GREEN")
styled_text=$(lib_msg_apply_style "Success!" "$bold_green")
echo "$styled_text"

# Get and apply a predefined style
warning_style=$(lib_msg_get_style "warning")
echo "$(lib_msg_apply_style "Be careful" "$warning_style")"
```

### `lib_msg_apply_style_if_tty`

Applies a style sequence to text only if the specified output stream is a TTY.

**Usage:**
```sh
lib_msg_apply_style_if_tty <text> <style_sequence> [use_stderr]
```

**Parameters:**
- `text`: The text to style
- `style_sequence`: The ANSI style sequence to apply
- `use_stderr`: Set to "true" to check stderr instead of stdout (optional, defaults to stdout)

**Returns:** The text with the style applied if appropriate stream is a TTY and colors are enabled, otherwise the original text.

**Example:**
```sh
# Style text only if stdout is a TTY
error_style=$(lib_msg_get_style "error")
styled_msg=$(lib_msg_apply_style_if_tty "Error details" "$error_style" "false")
echo "$styled_msg"

# Style text only if stderr is a TTY
warning_style=$(lib_msg_get_style "warning")
styled_err=$(lib_msg_apply_style_if_tty "Warning details" "$warning_style" "true")
echo "$styled_err" >&2
```

## Text Processing Functions

Functions for manipulating and formatting text.

### `lib_msg_strip_ansi`

Removes ANSI escape sequences from text.

**Usage:**
```sh
lib_msg_strip_ansi <text>
```

**Returns:** The input text with all ANSI escape sequences removed.

**Example:**
```sh
# Apply styling then strip it for length calculation
styled_text=$(lib_msg_apply_style "Important Message" "$(lib_msg_get_style "error")")
plain_text=$(lib_msg_strip_ansi "$styled_text")
echo "Original: $styled_text"
echo "Stripped: $plain_text"
echo "Length: ${#plain_text} characters"
```

### `lib_msg_get_wrapped_text`

Wraps text to a specified width, or to terminal width if width is 0.

**Usage:**
```sh
lib_msg_get_wrapped_text <text> <width>
```

**Parameters:**
- `text`: The text to wrap
- `width`: Maximum width in characters (use 0 to use terminal width)

**Returns:** The input text wrapped to the specified width with newlines.

**Example:**
```sh
# Wrap text to 40 columns
long_text="This is a very long paragraph that needs to be wrapped to fit within a specific width to ensure readability and proper formatting in the terminal or other display environments."
wrapped_text=$(lib_msg_get_wrapped_text "$long_text" 40)
echo "$wrapped_text"

# Wrap text to terminal width
auto_wrapped=$(lib_msg_get_wrapped_text "$long_text" 0)
echo "$auto_wrapped"
```

## Custom Message Output Functions

Functions for creating custom formatted messages.

### `lib_msg_output`

Outputs a message with optional prefix, style, and destination.

**Usage:**
```sh
lib_msg_output <message> [prefix] [style] [use_stderr] [no_newline]
```

**Parameters:**
- `message`: The message to output
- `prefix`: Optional prefix to prepend to the message
- `style`: Optional style to apply to the prefix
- `use_stderr`: Set to "true" to output to stderr instead of stdout (optional, defaults to "false")
- `no_newline`: Set to "true" to omit the trailing newline (optional, defaults to "false")

**Example:**
```sh
# Simple message with custom prefix
lib_msg_output "Operation completed" "[STATUS] "

# Styled prefix
success_style=$(lib_msg_get_style "success")
lib_msg_output "All tests passed" "[PASS] " "$success_style"

# Error message to stderr
error_style=$(lib_msg_get_style "error")
lib_msg_output "Failed to connect" "[FAIL] " "$error_style" "true"

# Message without newline
lib_msg_output "Working... " "" "" "false" "true"
```

### `lib_msg_output_n`

Shorthand for `lib_msg_output` with no trailing newline.

**Usage:**
```sh
lib_msg_output_n <message> [prefix] [style] [use_stderr]
```

**Example:**
```sh
# Output prompt without newline
lib_msg_output_n "Enter your name: " "" "$(lib_msg_get_style "highlight")"
read name
```

## Prompt Functions

Functions for interactive user input.

### `lib_msg_prompt`

Displays a prompt and returns user input.

**Usage:**
```sh
lib_msg_prompt <prompt_text> [default_value] [style]
```

**Parameters:**
- `prompt_text`: The text to display as prompt
- `default_value`: Optional default value if user presses Enter without input
- `style`: Optional style for the prompt

**Returns:** The user's input, or the default value if no input was provided.

**Example:**
```sh
# Simple prompt
name=$(lib_msg_prompt "Enter your name")
echo "Hello, $name!"

# Prompt with default value
path=$(lib_msg_prompt "Enter file path" "./config.txt")
echo "Using file: $path"

# Styled prompt
highlight_style=$(lib_msg_get_style "highlight")
answer=$(lib_msg_prompt "What's your favorite color?" "blue" "$highlight_style")
echo "You chose: $answer"
```

### `lib_msg_prompt_yn`

Displays a yes/no prompt and returns a shell exit code.

**Usage:**
```sh
lib_msg_prompt_yn <prompt_text> [style] <default_char>
```

**Parameters:**
- `prompt_text`: The text to display as prompt
- `style`: Optional style for the prompt ("bracketed", "simple", or "" for no style)
- `default_char`: **Mandatory** default choice ("Y", "y", "N", or "n")

**Returns:** Exit code 0 if user answered yes, exit code 1 if user answered no.

**Example:**
```sh
# Yes/no prompt with default yes (no style)
if lib_msg_prompt_yn "Continue with installation?" "" "y"; then
    echo "Continuing..."
else
    echo "Aborting."
    exit 0
fi

# Yes/no prompt with default yes and simple style
if lib_msg_prompt_yn "Save changes before exiting?" "simple" "y"; then
    echo "Saving changes..."
else
    echo "Discarding changes..."
fi

# Styled yes/no prompt with default no
if lib_msg_prompt_yn "Delete all files?" "bracketed" "n"; then
    echo "Deleting files..."
else
    echo "Operation cancelled."
fi
```

## Convenience Functions

Helper functions for common formatting tasks.

### `lib_msg_get_style`

Returns a predefined style sequence for common styles.

**Usage:**
```sh
lib_msg_get_style <style_name>
```

**Parameters:**
- `style_name`: One of: "error", "warning", "info", "success", "highlight", "dim"

**Returns:** ANSI style sequence for the requested style.

**Example:**
```sh
# Get and apply predefined styles
error_style=$(lib_msg_get_style "error")
echo "$(lib_msg_apply_style "Error message" "$error_style")"

warning_style=$(lib_msg_get_style "warning")
echo "$(lib_msg_apply_style "Warning message" "$warning_style")"

info_style=$(lib_msg_get_style "info")
echo "$(lib_msg_apply_style "Information message" "$info_style")"

success_style=$(lib_msg_get_style "success")
echo "$(lib_msg_apply_style "Success message" "$success_style")"

highlight_style=$(lib_msg_get_style "highlight")
echo "$(lib_msg_apply_style "Highlighted message" "$highlight_style")"

dim_style=$(lib_msg_get_style "dim")
echo "$(lib_msg_apply_style "Dimmed message" "$dim_style")"
```

### `lib_msg_create_prefix`

Creates a formatted prefix with optional styling.

**Usage:**
```sh
lib_msg_create_prefix <tag> [tag_style] [bracket_style]
```

**Parameters:**
- `tag`: The text to use as tag in the prefix
- `tag_style`: Optional style to apply to the tag
- `bracket_style`: Optional style to apply to the brackets

**Returns:** A formatted prefix like "[TAG] ".

**Example:**
```sh
# Simple prefix
prefix=$(lib_msg_create_prefix "NOTE")
echo "${prefix}This is a note."  # Outputs: [NOTE] This is a note.

# Styled tag
info_style=$(lib_msg_get_style "info")
info_prefix=$(lib_msg_create_prefix "INFO" "$info_style")
echo "${info_prefix}System is running normally."

# Fully styled prefix
tag_style=$(lib_msg_build_style_sequence "$_LIB_MSG_SGR_BOLD" "$_LIB_MSG_SGR_FG_RED")
bracket_style=$(lib_msg_build_style_sequence "$_LIB_MSG_SGR_FG_WHITE")
alert_prefix=$(lib_msg_create_prefix "ALERT" "$tag_style" "$bracket_style")
echo "${alert_prefix}Critical system error!"
```

### `lib_msg_progress_bar`

Generates a text progress bar.

**Usage:**
```sh
lib_msg_progress_bar <current> <max> [width] [filled_char] [empty_char]
```

**Parameters:**
- `current`: Current progress value
- `max`: Maximum progress value
- `width`: Total output width including brackets and percentage (default: 20, minimum: 10)
- `filled_char`: Character for filled portion (default: #)
- `empty_char`: Character for empty portion (default: -)

**Returns:** A text progress bar like "[#####-----] [ 50%]".

**Example:**
```sh
# Basic progress bar
echo "$(lib_msg_progress_bar 5 10)"  # Shows: [##########----------] [ 50%]

# Custom width progress bar
echo "$(lib_msg_progress_bar 7 10 30)"  # Shows: [#####################---------] [ 70%]

# Custom characters
echo "$(lib_msg_progress_bar 3 10 20 "=" " ")"  # Shows: [======              ] [ 30%]

# Dynamic progress in a loop
total=10
for i in $(seq 1 $total); do
    progress=$(lib_msg_progress_bar "$i" "$total" 30)
    printf "\rProcessing: %s" "$progress"
    sleep 0.5
done
echo  # Add final newline
```

## Environment Variables

These environment variables control the behavior of the library:

| Variable | Description | Default | Options |
|----------|-------------|---------|---------|
| `SCRIPT_NAME` | Name displayed in message prefixes | "lib_msg.sh" | Any string |
| `LIB_MSG_COLOR_MODE` | Controls color output behavior | "auto" | "auto", "on", "off", "force_on" |
| `NO_COLOR` | Standard variable to disable colors | unset | Any value to disable colors |
| `COLUMNS` | Terminal width in columns | From system | Positive integer |
| `LIB_MSG_FORCE_STDOUT_TTY` | Force stdout TTY status (testing) | unset | "true" or "false" |
| `LIB_MSG_FORCE_STDERR_TTY` | Force stderr TTY status (testing) | unset | "true" or "false" |

## SGR (Select Graphic Rendition) Constants

These constants are exported for use with styling functions:

### Text Formatting

| Constant | Value | Description |
|----------|-------|-------------|
| `$_LIB_MSG_SGR_RESET` | 0 | Reset all styles |
| `$_LIB_MSG_SGR_BOLD` | 1 | Bold/increased intensity |
| `$_LIB_MSG_SGR_FAINT` | 2 | Faint/decreased intensity |
| `$_LIB_MSG_SGR_ITALIC` | 3 | Italic |
| `$_LIB_MSG_SGR_UNDERLINE` | 4 | Underline |
| `$_LIB_MSG_SGR_BLINK` | 5 | Slow blink |
| `$_LIB_MSG_SGR_INVERT` | 7 | Invert foreground/background |
| `$_LIB_MSG_SGR_HIDE` | 8 | Conceal/hide text |
| `$_LIB_MSG_SGR_STRIKE` | 9 | Strikethrough |

### Foreground Colors (Normal Intensity)

| Constant | Value | Description |
|----------|-------|-------------|
| `$_LIB_MSG_SGR_FG_BLACK` | 30 | Black foreground |
| `$_LIB_MSG_SGR_FG_RED` | 31 | Red foreground |
| `$_LIB_MSG_SGR_FG_GREEN` | 32 | Green foreground |
| `$_LIB_MSG_SGR_FG_YELLOW` | 33 | Yellow foreground |
| `$_LIB_MSG_SGR_FG_BLUE` | 34 | Blue foreground |
| `$_LIB_MSG_SGR_FG_MAGENTA` | 35 | Magenta foreground |
| `$_LIB_MSG_SGR_FG_CYAN` | 36 | Cyan foreground |
| `$_LIB_MSG_SGR_FG_WHITE` | 37 | White foreground |

### Foreground Colors (Bright Intensity)

| Constant | Value | Description |
|----------|-------|-------------|
| `$_LIB_MSG_SGR_FG_BRIGHT_BLACK` | 90 | Bright black (gray) foreground |
| `$_LIB_MSG_SGR_FG_BRIGHT_RED` | 91 | Bright red foreground |
| `$_LIB_MSG_SGR_FG_BRIGHT_GREEN` | 92 | Bright green foreground |
| `$_LIB_MSG_SGR_FG_BRIGHT_YELLOW` | 93 | Bright yellow foreground |
| `$_LIB_MSG_SGR_FG_BRIGHT_BLUE` | 94 | Bright blue foreground |
| `$_LIB_MSG_SGR_FG_BRIGHT_MAGENTA` | 95 | Bright magenta foreground |
| `$_LIB_MSG_SGR_FG_BRIGHT_CYAN` | 96 | Bright cyan foreground |
| `$_LIB_MSG_SGR_FG_BRIGHT_WHITE` | 97 | Bright white foreground |

### Background Colors (Normal Intensity)

| Constant | Value | Description |
|----------|-------|-------------|
| `$_LIB_MSG_SGR_BG_BLACK` | 40 | Black background |
| `$_LIB_MSG_SGR_BG_RED` | 41 | Red background |
| `$_LIB_MSG_SGR_BG_GREEN` | 42 | Green background |
| `$_LIB_MSG_SGR_BG_YELLOW` | 43 | Yellow background |
| `$_LIB_MSG_SGR_BG_BLUE` | 44 | Blue background |
| `$_LIB_MSG_SGR_BG_MAGENTA` | 45 | Magenta background |
| `$_LIB_MSG_SGR_BG_CYAN` | 46 | Cyan background |
| `$_LIB_MSG_SGR_BG_WHITE` | 47 | White background |

### Background Colors (Bright Intensity)

| Constant | Value | Description |
|----------|-------|-------------|
| `$_LIB_MSG_SGR_BG_BRIGHT_BLACK` | 100 | Bright black (gray) background |
| `$_LIB_MSG_SGR_BG_BRIGHT_RED` | 101 | Bright red background |
| `$_LIB_MSG_SGR_BG_BRIGHT_GREEN` | 102 | Bright green background |
| `$_LIB_MSG_SGR_BG_BRIGHT_YELLOW` | 103 | Bright yellow background |
| `$_LIB_MSG_SGR_BG_BRIGHT_BLUE` | 104 | Bright blue background |
| `$_LIB_MSG_SGR_BG_BRIGHT_MAGENTA` | 105 | Bright magenta background |
| `$_LIB_MSG_SGR_BG_BRIGHT_CYAN` | 106 | Bright cyan background |
| `$_LIB_MSG_SGR_BG_BRIGHT_WHITE` | 107 | Bright white background |