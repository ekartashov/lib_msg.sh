# Troubleshooting Guide for lib_msg.sh

This document provides solutions to common issues you might encounter when using the lib_msg.sh library.

## Table of Contents

- [Display Issues](#display-issues)
  - [Colors Not Showing](#colors-not-showing)
  - [Unexpected Text Wrapping](#unexpected-text-wrapping)
  - [Inconsistent Message Formatting](#inconsistent-message-formatting)
- [Function Issues](#function-issues)
  - [Die Function Not Exiting](#die-function-not-exiting)
  - [Text Styling Not Working](#text-styling-not-working)
  - [TTY Detection Problems](#tty-detection-problems)
- [Integration Issues](#integration-issues)
  - [Library Not Found When Sourcing](#library-not-found-when-sourcing)
  - [Conflicts With Other Libraries](#conflicts-with-other-libraries)
- [Performance Issues](#performance-issues)
  - [Slow Text Processing](#slow-text-processing)
  - [High CPU Usage](#high-cpu-usage)
- [Environment-Specific Issues](#environment-specific-issues)
  - [Docker/Container Environments](#dockercontainer-environments)
  - [CI/CD Environments](#cicd-environments)
  - [Remote SSH Sessions](#remote-ssh-sessions)

## Display Issues

### Colors Not Showing

**Problem:** Messages appear without any color, even though you expect colored output.

**Possible Causes:**
- Terminal doesn't support color
- Color mode is disabled or incorrectly set
- `NO_COLOR` environment variable is set
- Output is being redirected or piped

**Solutions:**

1. **Check terminal color support:**
   ```sh
   echo -e "\033[31mTest\033[0m"  # Should appear red
   ```

2. **Force colors on:**
   ```sh
   export LIB_MSG_COLOR_MODE="force_on"
   lib_msg_reinit_colors
   ```

3. **Check if NO_COLOR is set:**
   ```sh
   echo $NO_COLOR
   unset NO_COLOR  # To enable colors
   lib_msg_reinit_colors
   ```

4. **Check if output is being redirected:**
   ```sh
   if [ "$(lib_msg_stdout_is_tty)" = "true" ]; then
     echo "Terminal output - colors should work"
   else
     echo "Redirected output - colors may be disabled"
   fi
   ```

### Unexpected Text Wrapping

**Problem:** Text wraps at unexpected positions or doesn't wrap at all.

**Possible Causes:**
- Incorrect terminal width detection
- COLUMNS environment variable not set or incorrect
- Terminal width changed since initialization

**Solutions:**

1. **Check detected terminal width:**
   ```sh
   echo "Detected width: $(lib_msg_get_terminal_width)"
   ```

2. **Update terminal width manually:**
   ```sh
   export COLUMNS=$(tput cols 2>/dev/null || echo 80)
   lib_msg_update_terminal_width
   echo "Updated width: $(lib_msg_get_terminal_width)"
   ```

3. **Force specific width:**
   ```sh
   export COLUMNS=80  # Or another desired width
   lib_msg_update_terminal_width
   ```

### Inconsistent Message Formatting

**Problem:** Message prefixes or formatting looks different in different parts of your script.

**Possible Causes:**
- SCRIPT_NAME variable changed or unset
- Mixing direct echo commands with lib_msg functions
- Using different styling approaches

**Solutions:**

1. **Set SCRIPT_NAME consistently:**
   ```sh
   # At the beginning of your script, after sourcing lib_msg.sh
   SCRIPT_NAME="my-app"
   ```

2. **Use lib_msg functions consistently:**
   ```sh
   # Instead of:
   echo "Error: Something went wrong"
   
   # Use:
   err "Something went wrong"
   ```

3. **Create consistent custom prefixes:**
   ```sh
   # For custom output formats
   DEBUG_PREFIX=$(lib_msg_create_prefix "DEBUG" "$(lib_msg_get_style "dim")")
   
   # Then use consistently
   lib_msg_output "Debug information" "$DEBUG_PREFIX"
   ```

## Function Issues

### Die Function Not Exiting

**Problem:** The `die` function displays the error message but doesn't exit the script.

**Possible Causes:**
- Script is being sourced, not executed
- Shell options like `set -e` might be interfering

**Solutions:**

1. **Check if script is sourced:**
   ```sh
   (return 0 2>/dev/null) && echo "Script is being sourced" || echo "Script is being executed"
   ```

2. **Use explicit exit after die when sourced:**
   ```sh
   # When script might be sourced
   if ! some_condition; then
       die 1 "Error message"
       # If script is sourced, code continues here
       return 1  # Additional precaution
   fi
   ```

3. **Check shell error handling:**
   ```sh
   # If you're using set -e, you might need to disable it temporarily
   set +e
   command_that_might_fail
   status=$?
   set -e
   if [ $status -ne 0 ]; then
       die $status "Command failed"
   fi
   ```

### Text Styling Not Working

**Problem:** Attempts to apply styling manually don't work or cause formatting issues.

**Possible Causes:**
- Missing reset codes
- Incorrect style sequences
- Colors disabled
- Incompatible terminal

**Solutions:**

1. **Use lib_msg styling functions:**
   ```sh
   # Instead of manually applying ANSI codes:
   echo "\033[1;31mError\033[0m"
   
   # Use the library functions:
   error_style=$(lib_msg_get_style "error")
   echo "$(lib_msg_apply_style "Error" "$error_style")"
   ```

2. **Always include reset code:**
   ```sh
   echo "${bold_text}Important${_LIB_MSG_CLR_RESET} normal text"
   ```

3. **Use apply_style instead of raw sequences:**
   ```sh
   styled=$(lib_msg_apply_style "Text" "$style_sequence")
   echo "$styled"  # This handles reset codes automatically
   ```

### TTY Detection Problems

**Problem:** TTY detection returns incorrect results.

**Possible Causes:**
- Running in an unusual environment (CI/CD, container, etc.)
- Custom terminal might not report correctly

**Solutions:**

1. **Force TTY status:**
   ```sh
   export LIB_MSG_FORCE_STDOUT_TTY="true"
   export LIB_MSG_FORCE_STDERR_TTY="true"
   ```

2. **Override color behavior instead:**
   ```sh
   export LIB_MSG_COLOR_MODE="force_on"  # or "off" if needed
   lib_msg_reinit_colors
   ```

3. **Make your script TTY-agnostic:**
   ```sh
   # Always use lib_msg_apply_style instead of lib_msg_apply_style_if_tty
   # Always check lib_msg_colors_enabled explicitly if needed
   ```

## Integration Issues

### Library Not Found When Sourcing

**Problem:** Attempts to source the library fail with "file not found" or similar errors.

**Possible Causes:**
- Incorrect file path
- Script running from unexpected directory
- Permissions issues

**Solutions:**

1. **Use absolute path:**
   ```sh
   # If library is in a standard location
   . /path/to/lib_msg.sh
   ```

2. **Use path relative to script:**
   ```sh
   SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
   . "$SCRIPT_DIR/lib/lib_msg.sh"
   ```

3. **Try multiple locations:**
   ```sh
   if [ -f "./lib_msg.sh" ]; then
       . ./lib_msg.sh
   elif [ -f "./lib/lib_msg.sh" ]; then
       . ./lib/lib_msg.sh
   elif [ -f "$HOME/lib/lib_msg.sh" ]; then
       . "$HOME/lib/lib_msg.sh"
   else
       echo "Error: lib_msg.sh not found" >&2
       exit 1
   fi
   ```

### Conflicts With Other Libraries

**Problem:** lib_msg.sh functions conflict with other libraries or existing functions.

**Possible Causes:**
- Function name collisions
- Environment variable conflicts
- ANSI color code conflicts

**Solutions:**

1. **Check for naming conflicts:**
   ```sh
   # Before sourcing lib_msg.sh
   command -v msg >/dev/null && echo "Warning: 'msg' function already exists"
   command -v err >/dev/null && echo "Warning: 'err' function already exists"
   # etc. for other key functions
   ```

2. **Source libraries in specific order:**
   ```sh
   # If sourcing order matters
   . ./lib_msg.sh  # First to establish baseline
   . ./other_library.sh  # May override some functions
   ```

3. **Use namespaced variables in your scripts:**
   ```sh
   # Instead of generic variable names
   MY_APP_COLUMNS=$COLUMNS  # Save original value
   ```

## Performance Issues

### Slow Text Processing

**Problem:** Text processing operations (wrapping, ANSI stripping) are slow.

**Possible Causes:**
- Large text blocks
- Using pure shell functions when external commands would be faster
- Excessive style operations

**Solutions:**

1. **Process text in smaller chunks:**
   ```sh
   # Instead of one huge text block
   long_text="..."
   # Process in manageable sections
   while read -r line; do
       processed_line=$(lib_msg_get_wrapped_text "$line" 0)
       echo "$processed_line"
   done <<< "$long_text"
   ```

2. **Check external command availability:**
   ```sh
   # The library tries to use external commands like sed when available
   # Make sure basic commands are in PATH for performance
   command -v sed >/dev/null || echo "Warning: 'sed' not found, using slower shell fallbacks"
   ```

3. **Minimize redundant style operations:**
   ```sh
   # Cache style sequences
   ERROR_STYLE=$(lib_msg_get_style "error")
   
   # Use in multiple places
   echo "$(lib_msg_apply_style "Error 1" "$ERROR_STYLE")"
   echo "$(lib_msg_apply_style "Error 2" "$ERROR_STYLE")"
   ```

### High CPU Usage

**Problem:** Scripts using lib_msg.sh have higher CPU usage than expected.

**Possible Causes:**
- Excessive text wrapping on long text
- Inefficient use of lib_msg functions in loops
- Redundant style calculations

**Solutions:**

1. **Avoid redundant operations in loops:**
   ```sh
   # Inefficient:
   for i in $(seq 1 100); do
       info "Processing item $i"  # Re-formats prefix each time
   done
   
   # More efficient:
   info_prefix="$(SCRIPT_NAME="$SCRIPT_NAME" lib_msg_create_prefix "I" "$(lib_msg_get_style "info")")"
   for i in $(seq 1 100); do
       lib_msg_output "Processing item $i" "$info_prefix"
   done
   ```

2. **Pre-process large text blocks:**
   ```sh
   # Pre-wrap long help text
   HELP_TEXT=$(lib_msg_get_wrapped_text "$LONG_HELP_TEXT" 0)
   
   # Then output when needed
   echo "$HELP_TEXT"
   ```

3. **Use external commands for bulk processing:**
   ```sh
   # For large files with ANSI codes:
   sed -E 's/\x1B\[[0-9;]*[mK]//g' large_file.log > clean_file.log
   ```

## Environment-Specific Issues

### Docker/Container Environments

**Problem:** Library doesn't work as expected in Docker or other container environments.

**Possible Causes:**
- TTY detection issues
- Terminal size reporting
- Minimal shell environment

**Solutions:**

1. **Force TTY settings:**
   ```sh
   # In your entrypoint script
   export LIB_MSG_FORCE_STDOUT_TTY="true"
   export LIB_MSG_FORCE_STDERR_TTY="true"
   ```

2. **Set explicit terminal size:**
   ```sh
   export COLUMNS=80
   export LINES=24
   lib_msg_update_terminal_width
   ```

3. **Force color mode:**
   ```sh
   # For CI environments that support color
   export LIB_MSG_COLOR_MODE="force_on"
   
   # For environments that don't support color
   export LIB_MSG_COLOR_MODE="off"
   ```

### CI/CD Environments

**Problem:** Different behavior in CI/CD pipelines compared to local development.

**Possible Causes:**
- Non-interactive environment
- Limited terminal capabilities
- Environment variable differences

**Solutions:**

1. **Set appropriate color mode for CI:**
   ```sh
   # In CI config or script
   export LIB_MSG_COLOR_MODE="off"  # Most predictable for logs
   ```

2. **Set explicit script name:**
   ```sh
   export SCRIPT_NAME="ci-build"  # Consistent identifier in logs
   ```

3. **For GitHub Actions with color support:**
   ```sh
   # GitHub Actions supports color
   export LIB_MSG_COLOR_MODE="on"
   ```

### Remote SSH Sessions

**Problem:** Unexpected behavior in remote SSH sessions or screen/tmux sessions.

**Possible Causes:**
- Limited terminal information
- $TERM variable differences
- Screen size reporting issues

**Solutions:**

1. **Update terminal size after connection:**
   ```sh
   # At the beginning of your script
   export COLUMNS=$(tput cols 2>/dev/null || echo 80)
   export LINES=$(tput lines 2>/dev/null || echo 24)
   lib_msg_update_terminal_width
   ```

2. **Check for screen/tmux:**
   ```sh
   if [ -n "$TMUX" ] || [ -n "$STY" ]; then
       # Running in tmux or screen
       export COLUMNS=$(tput cols 2>/dev/null || echo 80)
       lib_msg_update_terminal_width
   fi
   ```

3. **Verify TTY status:**
   ```sh
   if [ "$(lib_msg_stdout_is_tty)" = "true" ]; then
       echo "Interactive SSH session - normal mode"
   else
       echo "Non-interactive session - adapting output"
       export LIB_MSG_COLOR_MODE="off"
       lib_msg_reinit_colors
   fi