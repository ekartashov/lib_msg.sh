# Troubleshooting Guide for lib_msg.sh

This document provides solutions for common issues you might encounter when using the lib_msg.sh library.

## Table of Contents

- [Display Issues](#display-issues)
  - [Colors Not Displaying](#colors-not-displaying)
  - [Text Not Wrapping Correctly](#text-not-wrapping-correctly)
  - [Broken ANSI Sequences](#broken-ansi-sequences)
- [Integration Issues](#integration-issues)
  - [Script Name Not Showing Correctly](#script-name-not-showing-correctly)
  - [Messages Appearing on Wrong Output Stream](#messages-appearing-on-wrong-output-stream)
- [Performance Issues](#performance-issues)
  - [Slow Output with Large Messages](#slow-output-with-large-messages)
  - [High CPU Usage](#high-cpu-usage)
- [Behavioral Issues](#behavioral-issues)
  - [Die Function Not Exiting](#die-function-not-exiting)
  - [Die Function Exiting When It Shouldn't](#die-function-exiting-when-it-shouldnt)

## Display Issues

### Colors Not Displaying

**Symptoms:**
- Messages appear without color
- ANSI style sequences are visible as plain text

**Possible Causes:**
1. Terminal does not support ANSI colors
2. `NO_COLOR` environment variable is set
3. `LIB_MSG_COLOR_MODE` is set to "off"
4. Output is being redirected to a file or pipe

**Solutions:**
1. Check terminal compatibility:
   ```sh
   echo -e "\033[31mRed Text\033[0m"
   ```
   If you don't see red text, your terminal doesn't support ANSI colors.

2. Check environment variables:
   ```sh
   echo "NO_COLOR: ${NO_COLOR:-not set}"
   echo "LIB_MSG_COLOR_MODE: ${LIB_MSG_COLOR_MODE:-auto}"
   ```

3. Force colors on (if your terminal supports them):
   ```sh
   export LIB_MSG_COLOR_MODE="force_on"
   ```

4. Check if colors are enabled in the library:
   ```sh
   lib_msg_colors_enabled  # Should output "true" if colors are enabled
   ```

5. Reinitialize colors after changing environment:
   ```sh
   lib_msg_reinit_colors
   ```

### Text Not Wrapping Correctly

**Symptoms:**
- Text extends beyond terminal width
- Text wraps at unexpected points
- Line breaks appear in unusual places

**Possible Causes:**
1. `COLUMNS` environment variable is not set or incorrect
2. Terminal width detection is failing
3. Text contains ANSI sequences that are affecting length calculations

**Solutions:**
1. Check terminal width detection:
   ```sh
   echo "COLUMNS: ${COLUMNS:-not set}"
   echo "Detected width: $(lib_msg_get_terminal_width)"
   ```

2. Manually set and update terminal width:
   ```sh
   export COLUMNS=$(tput cols)
   lib_msg_update_terminal_width
   ```

3. For messages with ANSI colors, ensure the library is correctly calculating visible length:
   ```sh
   # Check if the library's ANSI stripping works correctly
   colored_text=$(lib_msg_apply_style "Test text" "$(lib_msg_get_style "info")")
   echo "Original: $colored_text"
   echo "Stripped: $(lib_msg_strip_ansi "$colored_text")"
   ```

### Broken ANSI Sequences

**Symptoms:**
- Text color or style changes unexpectedly
- Terminal shows garbage characters
- Styling doesn't reset properly after message

**Possible Causes:**
1. Incomplete ANSI sequences
2. Missing reset code after styled text
3. Nested or overlapping style sequences

**Solutions:**
1. Always reset after applying styles:
   ```sh
   # Ensure styles are properly closed
   styled_text="$(lib_msg_apply_style "Important" "$(lib_msg_get_style "error")") normal text"
   ```

2. Use the library's built-in styling functions instead of manual ANSI codes:
   ```sh
   # Instead of this:
   echo "\033[31mRed\033[0m"
   
   # Do this:
   echo "$(lib_msg_apply_style "Red" "$(lib_msg_build_style_sequence "$_LIB_MSG_SGR_FG_RED")")"
   ```

3. Strip ANSI codes completely if needed:
   ```sh
   clean_text=$(lib_msg_strip_ansi "$problematic_text")
   ```

## Integration Issues

### Script Name Not Showing Correctly

**Symptoms:**
- Messages show "lib_msg.sh" instead of your script name
- Wrong script name appears in message prefixes

**Possible Causes:**
1. `SCRIPT_NAME` variable not set
2. `SCRIPT_NAME` being overwritten elsewhere

**Solutions:**
1. Set `SCRIPT_NAME` at the beginning of your script:
   ```sh
   # At the top of your script, after sourcing lib_msg.sh
   SCRIPT_NAME="my_script.sh"
   ```

2. Use a more robust approach to get the script name:
   ```sh
   # For direct execution (not when sourced)
   SCRIPT_NAME=$(basename "$0")
   ```

3. Check if `SCRIPT_NAME` is being maintained:
   ```sh
   msg "Current script name: $SCRIPT_NAME"
   ```

### Messages Appearing on Wrong Output Stream

**Symptoms:**
- Error messages appear on stdout instead of stderr
- Regular messages appear on stderr instead of stdout

**Possible Causes:**
1. Using the wrong message functions
2. Redirecting output incorrectly

**Solutions:**
1. Use the correct functions for each stream:
   - For stdout: `msg`, `msgn`, `info`, `infon`
   - For stderr: `err`, `errn`, `warn`, `warnn`, `die`

2. When using custom output functions, specify the stream correctly:
   ```sh
   # For stderr (fourth parameter is "true")
   lib_msg_output "Error message" "" "" "true"
   
   # For stdout (fourth parameter is "false" or omitted)
   lib_msg_output "Normal message"
   ```

## Performance Issues

### Slow Output with Large Messages

**Symptoms:**
- Noticeable delay when displaying large messages
- Script pauses during text wrapping or formatting

**Possible Causes:**
1. Pure shell implementations being used instead of external commands
2. Excessive text wrapping due to narrow terminal
3. Complex ANSI sequence processing

**Solutions:**
1. Ensure external commands are available:
   ```sh
   # Check if sed and tr are available
   command -v sed >/dev/null 2>&1 && echo "sed available" || echo "sed not available"
   command -v tr >/dev/null 2>&1 && echo "tr available" || echo "tr not available"
   ```

2. Pre-process very large text before displaying:
   ```sh
   # For large text, pre-wrap it to avoid processing overhead
   large_text="..."
   wrapped_text=$(lib_msg_get_wrapped_text "$large_text" "$(lib_msg_get_terminal_width)")
   echo "$wrapped_text"
   ```

3. Consider using chunked output for very large text:
   ```sh
   # Process and display in smaller chunks
   while IFS= read -r line; do
       msg "$line"
   done <<< "$large_text"
   ```

### High CPU Usage

**Symptoms:**
- High CPU usage when processing messages
- Script becomes unresponsive with large text

**Possible Causes:**
1. Inefficient fallback implementations being used
2. Excessive text processing operations
3. Large input with character-by-character processing

**Solutions:**
1. Ensure optimal implementations are used:
   ```sh
   # Set up environment for optimal performance
   export LIB_MSG_FORCE_TEXT_WRAP_IMPL="shell"  # Shell impl is optimized
   ```

2. Reduce the complexity of message formatting:
   ```sh
   # Avoid complex styling for very large messages
   simple_text=$(lib_msg_strip_ansi "$complex_styled_text")
   msg "$simple_text"
   ```

3. Consider pre-processing or splitting very large messages:
   ```sh
   # Break down large content into smaller chunks
   echo "$large_content" | head -n 100 | while IFS= read -r line; do
       msg "$line"
   done
   ```

## Behavioral Issues

### Die Function Not Exiting

**Symptoms:**
- Script continues after calling `die`
- Error message is shown but execution doesn't stop

**Possible Causes:**
1. The script containing `die` is being sourced, not executed
2. Error code detection is failing

**Solutions:**
1. Check if your script is being sourced:
   ```sh
   # At the beginning of your script
   (return 0 2>/dev/null) && echo "Script is being sourced" || echo "Script is being executed"
   ```

2. Use explicit exit in critical scenarios:
   ```sh
   # For cases where you absolutely need to exit:
   err "Critical error"
   exit 1  # Explicitly exit instead of using die
   ```

3. Check your sourcing pattern if you're intentionally sourcing the script:
   ```sh
   # Source a script and capture its return code
   . ./my_script.sh
   if [ $? -ne 0 ]; then
       echo "Sourced script indicated an error"
   fi
   ```

### Die Function Exiting When It Shouldn't

**Symptoms:**
- Script exits when `die` is called in a sourced context
- Functions or libraries using `die` cause unexpected exits

**Possible Causes:**
1. Return validation is failing
2. Complex sourcing chain affecting context detection

**Solutions:**
1. Test return validation:
   ```sh
   # Test function to verify return behavior
   test_return() {
       if _lib_msg_is_return_valid; then
           echo "Return is valid in this context"
           return 0
       else
           echo "Return is not valid, would exit"
           return 1
       fi
   }
   
   # Call the test function
   test_return
   ```

2. Use a more explicit approach for critical libraries:
   ```sh
   # Define a context-aware exit function
   safe_exit() {
       if (return 0 2>/dev/null); then
           return "$1"
       else
           exit "$1"
       fi
   }
   
   # Use it instead of die for simple cases
   err "Error occurred"
   safe_exit 1
   ```

3. Check the context at the beginning of your script:
   ```sh
   # Detect and store whether we're being sourced
   (return 0 2>/dev/null)
   SCRIPT_IS_SOURCED=$?