# Plan: Exposing and Reusing `lib_msg.sh` Core Capabilities

**Goal:** Enable users to easily build custom interactive elements (like prompts) by leveraging `lib_msg.sh`'s underlying terminal intelligence without needing to replicate its logic. This involves exposing existing functionalities through a clear public API.

**Core Principles:**

1.  **Expose State via Functions:** Provide simple, public accessor functions for users to query detected terminal states (TTY, width, color support) instead of directly accessing internal `_LIB_MSG_` variables. This ensures API stability.
2.  **Provide Formatting Primitives:** Offer public functions that take raw text and apply specific transformations (like colorization or text wrapping) based on the detected terminal state, returning the modified string.
3.  **Consistent Configuration:** Primarily rely on existing `LIB_MSG_FORCE_*` TTY environment variables and `COLUMNS` for TTY/width detection. Color configuration will use a new `LIB_MSG_COLOR_MODE` environment variable and respect the standard `NO_COLOR` variable.
4.  **Guidance through Examples/Templates:** Develop and document clear examples (e.g., a robust yes/no prompt) to demonstrate how to combine these new primitive functions to build complex custom interactions.

## Proposed New Public Functions in `lib_msg.sh`

*(Function names are illustrative and prefixed with `lib_msg_` for the public API.)*

### A. State Accessor Functions

1.  **`lib_msg_is_stdout_tty()`**
    *   **Description:** Checks if standard output is connected to a TTY.
    *   **Returns:** Exit code `0` (true) if `$_LIB_MSG_STDOUT_IS_TTY` is "true", else `1` (false).
    *   **Usage:** `if lib_msg_is_stdout_tty; then ... fi`

2.  **`lib_msg_is_stderr_tty()`**
    *   **Description:** Checks if standard error is connected to a TTY.
    *   **Returns:** Exit code `0` (true) if `$_LIB_MSG_STDERR_IS_TTY` is "true", else `1` (false).

3.  **`lib_msg_get_terminal_width()`**
    *   **Description:** Gets the current terminal width. Ensures width detection logic is run.
    *   **Output:** Prints the detected terminal width (integer) to stdout. `0` typically means no wrapping or width not applicable.
    *   **Usage:** `current_width=$(lib_msg_get_terminal_width)`

4.  **`lib_msg_colors_enabled()`**
    *   **Description:** Checks if color output is effectively enabled by the library, based on `LIB_MSG_COLOR_MODE`, `NO_COLOR`, TTY status, and `TERM` value, as determined during library initialization.
    *   **Returns:** Exit code `0` (true) if colors are generally enabled by the library's policy, else `1` (false). (Actual application of color by `lib_msg_apply_style` also depends on the specific target stream being a TTY).

### B. Formatting Primitive Functions

#### Color and Style Handling

1.  **`lib_msg_build_style_sequence <sgr_code_1> [sgr_code_2] ... [sgr_code_n]`**
    *   **Description:** Constructs a valid ANSI SGR (Select Graphic Rendition) escape sequence from one or more numeric SGR codes.
    *   **Parameters:** One or more numeric SGR codes (e.g., "1" for bold, "32" for green foreground, intended to be used with exported `_LIB_MSG_SGR_*` constants).
    *   **Behavior:**
        *   Performs basic validation: checks if provided SGR codes are numeric.
        *   Non-numeric codes are ignored. A warning message (e.g., `lib_msg.sh: build_style_sequence: Warning: Non-numeric SGR code 'foo' ignored.`) is printed to `stderr` for each ignored code.
        *   Constructs an ANSI sequence (e.g., `\033[1;32m`) from all *valid* provided codes.
    *   **Output:** Prints the combined ANSI SGR sequence to `stdout`.
    *   **Returns:** Exit code `0` if all provided codes were valid. Exit code `1` if *any* code was invalid (and thus ignored/warned about).
    *   **Usage Guidance:** Users should call this function *once* to define a style, store its output in a variable, and reuse that variable. Example: `MY_ERROR_STYLE=$(lib_msg_build_style_sequence "$_LIB_MSG_SGR_BOLD" "$_LIB_MSG_SGR_FG_RED")`.

2.  **`lib_msg_apply_style <text> <style_sequence> [stream_fd]`**
    *   **Description:** Applies a complete, pre-formed ANSI style sequence to the given text and appends a global reset, if colors are generally enabled by `lib_msg_colors_enabled()` AND the specific target `stream_fd` is a TTY.
    *   **Parameters:**
        *   `text`: The string to be styled.
        *   `style_sequence`: The full ANSI escape sequence for the desired style(s) (e.g., output from `lib_msg_build_style_sequence`). This sequence should *not* include a final reset; this function adds `$_LIB_MSG_CLR_RESET`.
        *   `stream_fd` (optional): The file descriptor to target (defaults to `1` for `stdout`; use `2` for `stderr`).
    *   **Output:** Prints the styled (or plain) text to the specified `stream_fd`.
    *   **Usage:** `error_text=$(lib_msg_apply_style "Critical Error" "$MY_ERROR_STYLE" 2)`

#### Text Wrapping

3.  **`lib_msg_get_wrapped_text <text> [<width>]`**
    *   **Description:** Wraps the given text to a specified width or the auto-detected terminal width.
    *   **Parameters:**
        *   `text`: The text string to wrap.
        *   `width` (optional): The specific width to wrap to. If omitted or `0`, uses the result of `lib_msg_get_terminal_width()`. If effective width is `0` or less, text is returned as is (single line).
    *   **Behavior:**
        *   Internally calls `_lib_msg_wrap_text` which produces `$_LIB_MSG_RS` (Record Separator) delimited lines.
        *   Converts these `$_LIB_MSG_RS` delimiters to actual newline characters (`\n`).
        *   This conversion will attempt to use `tr "$_LIB_MSG_RS" '\n'` if `tr` is available (checked via `_lib_msg_has_command tr`).
        *   If `tr` is *not* available, a pure POSIX shell loop will be used as a fallback to perform the RS-to-newline replacement.
    *   **Output:** Prints the wrapped text to `stdout`, with lines delimited by actual newline characters (`\n`), ready for display.
    *   **Usage:**
        ```sh
        very_long_message="This is a very long message that needs to be wrapped."
        display_wrapped=$(lib_msg_get_wrapped_text "$very_long_message")
        printf '%s\n' "$display_wrapped" # Or simply: printf '%s\n' "$(lib_msg_get_wrapped_text "$msg")"
        ```

#### ANSI Stripping

4.  **`lib_msg_strip_ansi <text>`**
    *   **Description:** Removes ANSI escape sequences from the given text. Public alias for the internal `_lib_msg_strip_ansi` dispatcher.
    *   **Parameters:**
        *   `text`: The text string potentially containing ANSI codes.
    *   **Output:** Prints the plain text string to `stdout`.
    *   **Usage:** `plain_text=$(lib_msg_strip_ansi "$colored_input")`

### C. Configuration

*   **TTY/Width Detection:** Continue to use `LIB_MSG_FORCE_STDOUT_TTY`, `LIB_MSG_FORCE_STDERR_TTY` (for TTY detection) and `COLUMNS` (for width) environment variables.
*   **Color Output Configuration:**
    *   **`NO_COLOR` (Standard Environment Variable):** If set (non-empty), colors are **OFF**. This has the highest precedence for disabling colors.
    *   **`LIB_MSG_COLOR_MODE` (Library-Specific Environment Variable):**
        *   Values:
            *   `off`: Colors are definitively **OFF** for `lib_msg.sh`. This is the highest library-specific "off" switch.
            *   `force_on`: Attempts to enable colors if the target stream is a TTY AND `TERM` is not "dumb". **This mode IGNORES the `NO_COLOR` variable.** (Use with caution).
            *   `on`: Enables colors if `NO_COLOR` is *not* set, AND the target stream is a TTY, AND `TERM` is not "dumb".
            *   `auto` (Default if `LIB_MSG_COLOR_MODE` is unset or unrecognized): Behaves identically to `on`.
        *   The decision based on these variables is made once during library initialization (`_lib_msg_init_colors`) and determines the general color policy for the library session.

### D. Exported SGR Code Constants

*   `lib_msg.sh` will define and document a set of exported shell variables holding standard numeric SGR codes (e.g., `_LIB_MSG_SGR_BOLD="1"`, `_LIB_MSG_SGR_FG_RED="31"`). These are intended for use with `lib_msg_build_style_sequence`.

## Implementation Steps & Refinement

1.  **Implement Accessor Functions.**
2.  **Implement Formatting Primitives** (including SGR constants, `lib_msg_build_style_sequence`, `lib_msg_apply_style`, revised `lib_msg_get_wrapped_text` with `tr`/shell fallback, and `lib_msg_strip_ansi` alias).
3.  **Implement Color Configuration Logic** in `_lib_msg_init_colors` based on `NO_COLOR` and `LIB_MSG_COLOR_MODE`.
4.  **Develop Comprehensive Examples** (e.g., `ask_yes_no` prompt) in documentation.
5.  **Documentation:** Thoroughly document all new public API aspects.
6.  **Testing:** Add BATS tests for all new functions, configurations, and fallbacks.
7.  **Internal Refactoring (Optional):** Consider if `_print_msg_core` could use new primitives.

This plan provides a clear path to enhancing `lib_msg.sh` by making its powerful internal terminal handling capabilities available as a well-defined public API.