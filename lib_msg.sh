# shellcheck shell=sh

# --- lib_msg TTY and Width Detection (Initialize Once) ---
_LIB_MSG_STDOUT_IS_TTY="" # Unset initially
_LIB_MSG_STDERR_IS_TTY="" # Unset initially
_LIB_MSG_TERMINAL_WIDTH=0   # Default to 0 (no wrapping)

_lib_msg_init_detection() {
    # Only run initialization once
    if [ -n "$_LIB_MSG_STDOUT_IS_TTY" ]; then
        return
    fi

    if [ -t 1 ]; then
        _LIB_MSG_STDOUT_IS_TTY="true"
    else
        _LIB_MSG_STDOUT_IS_TTY="false"
    fi

    if [ -t 2 ]; then
        _LIB_MSG_STDERR_IS_TTY="true"
    else
        _LIB_MSG_STDERR_IS_TTY="false"
    fi

    # Try to get terminal width from COLUMNS env var if either stdout or stderr is a TTY
    if [ "$_LIB_MSG_STDOUT_IS_TTY" = "true" ] || [ "$_LIB_MSG_STDERR_IS_TTY" = "true" ]; then
        _temp_cols="${COLUMNS:-}"
        case "$_temp_cols" in
            ''|*[!0-9]*) # Empty or contains a non-digit
                _LIB_MSG_TERMINAL_WIDTH=0 ;;
            0) # Is exactly "0"
                _LIB_MSG_TERMINAL_WIDTH=0 ;;
            0*) # Starts with "0" but isn't just "0" (e.g. "01", "007") - treat as invalid
                _LIB_MSG_TERMINAL_WIDTH=0 ;;
            *[0-9]) # All digits, not empty, doesn't start with 0 (unless "0" itself, handled above)
                    # This means it's a positive integer string like "1", "80", "120"
                _LIB_MSG_TERMINAL_WIDTH="$_temp_cols" ;;
            *) # Fallback, e.g. if COLUMNS was something truly unexpected or for safety
                _LIB_MSG_TERMINAL_WIDTH=0 ;;
        esac
    fi
}
_lib_msg_init_detection # Call initialization
# --- ANSI Color Codes (Initialize Once) ---
_LIB_MSG_CLR_RESET=""
_LIB_MSG_CLR_BLACK=""
_LIB_MSG_CLR_RED=""
_LIB_MSG_CLR_GREEN=""
_LIB_MSG_CLR_YELLOW=""
_LIB_MSG_CLR_BLUE=""
_LIB_MSG_CLR_MAGENTA=""
_LIB_MSG_CLR_CYAN=""
_LIB_MSG_CLR_WHITE=""
_LIB_MSG_CLR_BOLD=""
# Add more (backgrounds, other styles) if needed

_lib_msg_init_colors() {
    # Only initialize if stdout or stderr is a TTY
    if [ "$_LIB_MSG_STDOUT_IS_TTY" = "true" ] || [ "$_LIB_MSG_STDERR_IS_TTY" = "true" ]; then
        _LIB_MSG_CLR_RESET=$(printf '\033[0m')
        _LIB_MSG_CLR_BLACK=$(printf '\033[0;30m')
        _LIB_MSG_CLR_RED=$(printf '\033[0;31m')
        _LIB_MSG_CLR_GREEN=$(printf '\033[0;32m')
        _LIB_MSG_CLR_YELLOW=$(printf '\033[0;33m')
        _LIB_MSG_CLR_BLUE=$(printf '\033[0;34m')
        _LIB_MSG_CLR_MAGENTA=$(printf '\033[0;35m')
        _LIB_MSG_CLR_CYAN=$(printf '\033[0;36m')
        _LIB_MSG_CLR_WHITE=$(printf '\033[0;37m')
        _LIB_MSG_CLR_BOLD=$(printf '\033[1m')
    fi
}
_lib_msg_init_colors # Call color initialization
# --- End ANSI Color Codes ---
# --- End lib_msg TTY and Width Detection ---

# Internal function to wrap text.
# Outputs one or more lines, each terminated by a newline.
# Usage: _lib_msg_wrap_text "message_content" "max_content_width"
_lib_msg_wrap_text() {
    _text_to_wrap="$1"
    _max_width="$2" # Max width for the content part of the message

    # If no width, or width is too small, or text is empty, print text as is with a newline.
    if [ "$_max_width" -le 0 ] || [ -z "$_text_to_wrap" ]; then
        printf '%s\n' "$_text_to_wrap"
        return
    fi

    _current_line=""
    _old_ifs="$IFS"
    IFS=' ' # Split by single space for word iteration
    # shellcheck disable=SC2086 # We explicitly want word splitting here
    set -- $_text_to_wrap # Words of _text_to_wrap become positional parameters $1, $2, ...
    IFS="$_old_ifs"

    _first_word_on_current_line=true
    for _word; do
        _word_len=${#_word}
        _current_line_len=${#_current_line}

        if $_first_word_on_current_line; then
            # Word is the first on the current line (or a new line)
            if [ "$_word_len" -gt "$_max_width" ]; then # Word itself is longer than max width
                _temp_long_word="$_word"
                while [ "${#_temp_long_word}" -gt "$_max_width" ]; do
                    _chunk=$(echo "$_temp_long_word" | cut -c -"$_max_width")
                    printf '%s\n' "$_chunk"
                    _temp_long_word=$(echo "$_temp_long_word" | cut -c "$((_max_width + 1))"-)
                done
                if [ -n "$_temp_long_word" ]; then # Remainder of the long word
                    _current_line="$_temp_long_word"
                    _first_word_on_current_line=false
                else # Long word was perfectly consumed
                    _current_line=""
                    _first_word_on_current_line=true # Next word will start a new line
                fi
                continue # Move to next positional parameter (_word)
            else # Word fits or is shorter than max_width
                _current_line="$_word"
                _first_word_on_current_line=false
            fi
        elif [ $((_current_line_len + 1 + _word_len)) -le "$_max_width" ]; then # Word fits on current line with a space
            _current_line="$_current_line $_word"
        else # Word does not fit on current line, print current line and start new one
            printf '%s\n' "$_current_line"
            # Now handle the current _word for the new line
            if [ "$_word_len" -gt "$_max_width" ]; then # This new word is also too long
                _temp_long_word="$_word"
                while [ "${#_temp_long_word}" -gt "$_max_width" ]; do
                    _chunk=$(echo "$_temp_long_word" | cut -c -"$_max_width")
                    printf '%s\n' "$_chunk"
                    _temp_long_word=$(echo "$_temp_long_word" | cut -c "$((_max_width + 1))"-)
                done
                if [ -n "$_temp_long_word" ]; then
                     _current_line="$_temp_long_word"
                     _first_word_on_current_line=false
                else
                    _current_line=""
                    _first_word_on_current_line=true
                fi
            else # New word fits fine on its own new line
                _current_line="$_word"
                _first_word_on_current_line=false
            fi
        fi
    done

    # Print any remaining text in _current_line
    if [ -n "$_current_line" ]; then
        printf '%s\n' "$_current_line"
    elif [ $# -eq 0 ] && [ -n "$_text_to_wrap" ]; then
        # This case handles if _text_to_wrap was non-empty but had no spaces (single word)
        # and it was shorter than _max_width, thus loop was not entered but text needs printing.
        # However, the loop `for _word` (after `set -- $_text_to_wrap`) will run once for a single word.
        # So this specific elif might be redundant if the loop handles single words correctly.
        # The initial check `[ -z "$_text_to_wrap" ]` in the function handles empty input.
        # If _text_to_wrap is non-empty, the loop runs. If loop finishes, _current_line has content.
        : # Covered by `if [ -n "$_current_line" ]`
    elif [ -z "$_text_to_wrap" ] && [ $# -eq 0 ]; then
        # Original text was empty, and `set --` resulted in no positional parameters.
        # _lib_msg_wrap_text "" should produce a single newline.
        # This is handled by the initial check: `printf '%s\n' ""` prints a newline.
        :
    fi
}

# Internal function to apply color if on TTY.
# Does not add a newline itself.
# Expects color codes to be initialized (e.g., _LIB_MSG_CLR_RED, _LIB_MSG_CLR_RESET).
# Usage: _lib_msg_colorize "text_to_color" "$_COLOR_CODE_VAR" "$_IS_TTY_FLAG"
_lib_msg_colorize() {
    _text_to_color_val="$1"
    _color_code_val="$2"
    _is_stream_tty_val="$3" # Should be "true" or "false"

    # Only apply color if the stream is a TTY and a color code is provided (non-empty)
    # and the reset code is also available (implicitly, if colors are initialized, reset is too)
    if [ "$_is_stream_tty_val" = "true" ] && [ -n "$_color_code_val" ] && [ -n "$_LIB_MSG_CLR_RESET" ]; then
        printf '%s%s%s' "$_color_code_val" "$_text_to_color_val" "$_LIB_MSG_CLR_RESET"
    else
        printf '%s' "$_text_to_color_val" # Print plain text if not TTY or no color
    fi
}
_print_msg_core() {
    _message_content="$1"
    _prefix_str="$2"
    _is_stderr="$3" # "true" if stderr, "false" or empty for stdout
    _no_final_newline="$4" # "true" if no final newline (for *n functions)

    _is_tty=$_LIB_MSG_STDOUT_IS_TTY
    if [ "$_is_stderr" = "true" ]; then
        _is_tty=$_LIB_MSG_STDERR_IS_TTY
    fi

    _prefix_len=${#_prefix_str}

    if [ "$_is_tty" = "true" ] && [ "$_LIB_MSG_TERMINAL_WIDTH" -gt 0 ]; then
        _text_wrap_width=$((_LIB_MSG_TERMINAL_WIDTH - _prefix_len))
        if [ "$_text_wrap_width" -lt 1 ]; then # Ensure at least 1 char width for content
            _text_wrap_width=1
        fi

        # _lib_msg_wrap_text outputs lines, each ending with \n.
        # We pipe its output and prefix each line.
        _processed_output=""
        _first_line_processed=true
        # Use command substitution to capture all wrapped lines
        _all_wrapped_lines=$(_lib_msg_wrap_text "$_message_content" "$_text_wrap_width")

        # Check if _all_wrapped_lines is empty or just a newline (from empty input to wrapper)
        if [ -z "$_all_wrapped_lines" ] || [ "$_all_wrapped_lines" = "$(printf '\n')" ]; then
            if [ -z "$_message_content" ]; then # Original message was empty
                 _processed_output="$_prefix_str" # Just the prefix
            else # Wrapper produced nothing for a non-empty message (should not happen with current wrapper)
                 _processed_output="${_prefix_str}${_message_content}"
            fi
        else
            # Iterate over lines from _all_wrapped_lines
            # Iterate over lines from _all_wrapped_lines using a here document
            # to avoid a subshell for the loop body, ensuring _processed_output is modified
            # in the current shell context.
            while IFS= read -r _wrapped_line; do
                if $_first_line_processed; then
                    _processed_output="${_prefix_str}${_wrapped_line}"
                    _first_line_processed=false
                else
                    _processed_output="${_processed_output}\n${_prefix_str}${_wrapped_line}"
                fi
            done <<LIBMSG_HEREDOC_INPUT
${_all_wrapped_lines}
LIBMSG_HEREDOC_INPUT
        fi

        if [ "$_no_final_newline" = "true" ]; then
            if [ "$_is_stderr" = "true" ]; then
                printf '%s' "$_processed_output" >&2
            else
                printf '%s' "$_processed_output"
            fi
        else
            if [ "$_is_stderr" = "true" ]; then
                printf '%s\n' "$_processed_output" >&2
            else
                printf '%s\n' "$_processed_output"
            fi
        fi
        return
    fi

    # Fallback: No wrapping needed or possible
    if [ "$_no_final_newline" = "true" ]; then
        if [ "$_is_stderr" = "true" ]; then
            printf '%s%s' "$_prefix_str" "$_message_content" >&2
        else
            printf '%s%s' "$_prefix_str" "$_message_content"
        fi
    else
        if [ "$_is_stderr" = "true" ]; then
            printf '%s%s\n' "$_prefix_str" "$_message_content" >&2
        else
            printf '%s%s\n' "$_prefix_str" "$_message_content"
        fi
    fi
}

# Helper function to determine if the script/shell can 'return'
# (implies function context, likely sourced or within a function of an executed script)
_lib_msg_is_return_valid() {
    # Returns 0 (true) if 'return' is a valid operation, 1 (false) otherwise.
    if (return 0 2>/dev/null); then
        return 0 # true, can return
    else
        return 1 # false, cannot return, must exit
    fi
}

err() {
    _prefix_tag=$(_lib_msg_colorize "E:" "$_LIB_MSG_CLR_RED" "$_LIB_MSG_STDERR_IS_TTY")
    _print_msg_core "$1" "${SCRIPT_NAME:-lib_msg.sh}: ${_prefix_tag} " "true" ""
}

errn() {
    _prefix_tag=$(_lib_msg_colorize "E:" "$_LIB_MSG_CLR_RED" "$_LIB_MSG_STDERR_IS_TTY")
    _print_msg_core "$1" "${SCRIPT_NAME:-lib_msg.sh}: ${_prefix_tag} " "true" "true"
}

warn() {
    _prefix_tag=$(_lib_msg_colorize "W:" "$_LIB_MSG_CLR_YELLOW" "$_LIB_MSG_STDERR_IS_TTY")
    _print_msg_core "$1" "${SCRIPT_NAME:-lib_msg.sh}: ${_prefix_tag} " "true" ""
}

warnn() {
    _prefix_tag=$(_lib_msg_colorize "W:" "$_LIB_MSG_CLR_YELLOW" "$_LIB_MSG_STDERR_IS_TTY")
    _print_msg_core "$1" "${SCRIPT_NAME:-lib_msg.sh}: ${_prefix_tag} " "true" "true"
}

die() {
    _error_code="$1"
    shift # Remove error code, remaining args are the message
    _message="$*" # Combine all remaining arguments into the message string

    # Default error code if not provided or not a non-negative number
    if ! expr "$_error_code" : '^[0-9][0-9]*$' >/dev/null ; then
        _message="${_error_code}${_message:+ }$_message" # Prepend original $1 to message
        _error_code=1 # Default error code to 1
    elif [ "$_error_code" -lt 0 ]; then # Negative error codes are unusual for exit status
        # Silently convert negative codes to positive for exit status, or treat as message
        # For simplicity, let's ensure error_code is non-negative for exit/return
        _message="Note: Negative error code ($_error_code) used with die. ${_message}"
        _error_code=1 # Default to 1 if original was negative
    fi

    _prefix_tag=$(_lib_msg_colorize "E:" "$_LIB_MSG_CLR_RED" "$_LIB_MSG_STDERR_IS_TTY")
    _print_msg_core "$_message" "${SCRIPT_NAME:-lib_msg.sh}: ${_prefix_tag} " "true" ""

    if _lib_msg_is_return_valid; then
        return "$_error_code"
    else
        exit "$_error_code"
    fi
}

msg() {
    _print_msg_core "$1" "${SCRIPT_NAME:-lib_msg.sh}: " "" ""
}

msgn() {
    _print_msg_core "$1" "${SCRIPT_NAME:-lib_msg.sh}: " "" "true"
}

info() {
    _prefix_tag=$(_lib_msg_colorize "I:" "$_LIB_MSG_CLR_BLUE" "$_LIB_MSG_STDOUT_IS_TTY")
    _print_msg_core "$1" "${SCRIPT_NAME:-lib_msg.sh}: ${_prefix_tag} " "" ""
}

infon() {
    _prefix_tag=$(_lib_msg_colorize "I:" "$_LIB_MSG_CLR_BLUE" "$_LIB_MSG_STDOUT_IS_TTY")
    _print_msg_core "$1" "${SCRIPT_NAME:-lib_msg.sh}: ${_prefix_tag} " "" "true"
}

