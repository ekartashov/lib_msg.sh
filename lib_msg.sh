# shellcheck shell=sh

# --- Command Availability Detection ---
_lib_msg_has_command() {
    # Use a more specific check that will work with BATS command stubbing
    if ! command -v "$1" >/dev/null 2>&1; then
        return 1
    fi
    return 0
}

# --- lib_msg TTY and Width Detection ---
_LIB_MSG_STDOUT_IS_TTY="" # Unset initially
_LIB_MSG_STDERR_IS_TTY="" # Unset initially
_LIB_MSG_TERMINAL_WIDTH=0   # Default to 0 (no wrapping)

# This function is no longer used
_lib_msg_test_t() {
    test -t "$1"
}

# We need BATS to be able to stub this function for testing
# IMPORTANT: DO NOT CHANGE THE COMMAND FORMAT "test -t N"
# It needs to be exactly this format for BATS test stubbing
_lib_msg_init_detection() {
    # TTY detection - only run if not already set
    if [ -z "$_LIB_MSG_STDOUT_IS_TTY" ]; then
        # Allow overriding TTY detection via environment variables for testing
        if [ -n "$LIB_MSG_FORCE_STDOUT_TTY" ]; then
            _LIB_MSG_STDOUT_IS_TTY="$LIB_MSG_FORCE_STDOUT_TTY"
        # IMPORTANT: Format must be exactly "test -t 1" for BATS stubbing to work
        elif test -t 1; then
            # Set to true if test -t 1 returns success (FD 1 is a TTY)
            _LIB_MSG_STDOUT_IS_TTY="true"
        else
            # Set to false otherwise
            _LIB_MSG_STDOUT_IS_TTY="false"
        fi

        if [ -n "$LIB_MSG_FORCE_STDERR_TTY" ]; then
            _LIB_MSG_STDERR_IS_TTY="$LIB_MSG_FORCE_STDERR_TTY"
        # IMPORTANT: Format must be exactly "test -t 2" for BATS stubbing to work
        elif test -t 2; then
            # Set to true if test -t 2 returns success (FD 2 is a TTY)
            _LIB_MSG_STDERR_IS_TTY="true"
        else
            # Set to false otherwise
            _LIB_MSG_STDERR_IS_TTY="false"
        fi
    fi

    # Initialize terminal width (done here for historical reasons)
    _lib_msg_update_terminal_width
}

# Updates terminal width by checking COLUMNS env var
# Called before each public API function to ensure we have the current width
_lib_msg_update_terminal_width() {
    # Always start with width 0, then evaluate conditions
    _LIB_MSG_TERMINAL_WIDTH=0

    # Critical: If both stdout and stderr are not TTY, always use width 0
    if [ "$_LIB_MSG_STDOUT_IS_TTY" = "false" ] && [ "$_LIB_MSG_STDERR_IS_TTY" = "false" ]; then
        # Force to 0 for test compliance and correctness
        _LIB_MSG_TERMINAL_WIDTH=0
        return
    fi
    
    # One or both streams is a TTY, check COLUMNS
    _temp_cols="${COLUMNS:-}"
    case "$_temp_cols" in
        ''|*[!0-9]*) _LIB_MSG_TERMINAL_WIDTH=0 ;;
        0) _LIB_MSG_TERMINAL_WIDTH=0 ;;
        0*) _LIB_MSG_TERMINAL_WIDTH=0 ;;
        *[0-9]) _LIB_MSG_TERMINAL_WIDTH="$_temp_cols" ;;
        *) _LIB_MSG_TERMINAL_WIDTH=0 ;;
    esac
}

# Initialize TTY detection only once at library load time
_lib_msg_init_detection

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

_lib_msg_init_colors() {
    _LIB_MSG_CLR_RESET="" # Clear them first
    _LIB_MSG_CLR_BLACK=""
    _LIB_MSG_CLR_RED=""
    _LIB_MSG_CLR_GREEN=""
    _LIB_MSG_CLR_YELLOW=""
    _LIB_MSG_CLR_BLUE=""
    _LIB_MSG_CLR_MAGENTA=""
    _LIB_MSG_CLR_CYAN=""
    _LIB_MSG_CLR_WHITE=""
    _LIB_MSG_CLR_BOLD=""
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
_lib_msg_init_colors

_LIB_MSG_NL='
'
_LIB_MSG_ESC=$(printf '\033')
_LIB_MSG_RS=$(printf '\036') # Record Separator (unlikely to appear in normal text)
# --- End lib_msg TTY and Width Detection ---

# The record separator is used internally for line delimiting
# making the code POSIX-compatible without relying on arrays

# --- ANSI Stripping Implementations ---

# Shell implementation for stripping ANSI escape sequences
_lib_msg_strip_ansi_shell() {
    _input_str_to_strip="$1"
    _result_str=""
    _remaining_input="$_input_str_to_strip"

    while [ -n "$_remaining_input" ]; do
        case "$_remaining_input" in
            "$_LIB_MSG_ESC"*)
                # Handle escape sequence
                _after_esc="${_remaining_input#"$_LIB_MSG_ESC"}"
                if [ "${_after_esc%"${_after_esc#?}"}" = "[" ]; then
                    # This is potentially a CSI sequence
                    _sequence_part="${_after_esc#?}"
                    _params_and_cmd="$_sequence_part"
                    _cmd_char=""
                    _loop_idx=0
                    _max_loop_idx=${#_params_and_cmd}
                    _found_valid_sequence=false

                    # Scan for the command character
                    while [ "$_loop_idx" -lt "$_max_loop_idx" ]; do
                        _temp_str_for_char="$_params_and_cmd"
                        _char_idx_iter=0
                        while [ "$_char_idx_iter" -lt "$_loop_idx" ]; do
                            _temp_str_for_char="${_temp_str_for_char#?}"
                            _char_idx_iter=$((_char_idx_iter + 1))
                        done
                        _current_param_char="${_temp_str_for_char%"${_temp_str_for_char#?}"}"

                        case "$_current_param_char" in
                            [0-9\;:])
                                # Valid parameter character, keep scanning
                                ;;
                            [a-zA-Z])
                                # Found valid command character, this is a complete sequence
                                _cmd_char="$_current_param_char"
                                _temp_str_for_remainder="$_params_and_cmd"
                                _remainder_idx_iter=0
                                _num_chars_to_chop=$((_loop_idx + 1))
                                while [ "$_remainder_idx_iter" -lt "$_num_chars_to_chop" ]; do
                                    _temp_str_for_remainder="${_temp_str_for_remainder#?}"
                                    _remainder_idx_iter=$((_remainder_idx_iter + 1))
                                done
                                _remaining_input="$_temp_str_for_remainder"
                                _found_valid_sequence=true
                                break
                                ;;
                            *)
                                # Invalid character for CSI, treat whole sequence as literal
                                _cmd_char=""
                                break
                                ;;
                        esac
                        _loop_idx=$((_loop_idx + 1))
                    done

                    # If we found a valid sequence, skip it (strip it)
                    if $_found_valid_sequence; then
                        continue
                    fi

                    # If we didn't find a command char, this is an incomplete sequence
                    # We need to preserve it literally including ESC and [
                    _result_str="${_result_str}${_LIB_MSG_ESC}["
                    _remaining_input="$_sequence_part"
                else
                    # ESC followed by something other than [
                    # Preserve it literally
                    _result_str="${_result_str}${_LIB_MSG_ESC}"
                    _remaining_input="$_after_esc"
                fi
                ;;
            *)
                _char_to_add="${_remaining_input%"${_remaining_input#?}"}"
                _result_str="${_result_str}${_char_to_add}"
                _remaining_input="${_remaining_input#?}"
                ;;
        esac
    done
    printf '%s' "$_result_str"
}

# Optimized sed implementation for stripping ANSI escape sequences
_lib_msg_strip_ansi_sed() {
    printf '%s' "$1" | sed -e 's/\x1b\[[0-9;]*[a-zA-Z]//g'
}

# Select the best available implementation for stripping ANSI sequences
# Define as a function that checks availability each time to work properly with command stubbing
_lib_msg_strip_ansi() {
    if _lib_msg_has_command sed; then
        _lib_msg_strip_ansi_sed "$1"
    else
        _lib_msg_strip_ansi_shell "$1"
    fi
}

# --- Text Wrapping Implementations ---

# POSIX sh implementation (no arrays) for wrapping text
# Uses $_LIB_MSG_RS (record separator) to delimit lines
_lib_msg_wrap_text_sh() {
    _text_to_wrap="$1"
    _max_width="$2"
    _result_lines=""
    
    # Replace newlines with spaces to match AWK implementation behavior
    # This is crucial to ensure similar handling of multi-line input across both implementations
    # The tr command needs to be properly escaped to handle input with special characters
    _text_to_wrap="$(printf "%s" "$_text_to_wrap" | tr '\n' ' ')"
    
    _temp_text_for_check="$_text_to_wrap"
    _old_ifs_check="$IFS"
    IFS=' '
    # shellcheck disable=SC2086 # Word splitting is desired here for counting
    set -- $_temp_text_for_check
    _word_count=$#
    IFS="$_old_ifs_check"
    set -- # Clear positional params from check

    if [ "$_word_count" -eq 0 ]; then # Input was empty or all spaces
        # Add an empty line
        if [ -z "$_result_lines" ]; then
            _result_lines=""
        else
            _result_lines="${_result_lines}${_LIB_MSG_RS}"
        fi
        
        printf "%s" "$_result_lines"
        return
    fi

    if [ "$_max_width" -le 0 ]; then # No wrapping if width is 0 or less
        _result_lines="$_text_to_wrap"
        
        printf "%s" "$_result_lines"
        return
    fi

    _current_line=""
    _old_ifs="$IFS"
    IFS=' '
    # shellcheck disable=SC2086 # We explicitly want word splitting here
    set -- $_text_to_wrap # Words of _text_to_wrap become positional parameters $1, $2, ...
    IFS="$_old_ifs"

    _first_word_on_current_line=true
    for _word; do
        _word_len=${#_word}
        _current_line_len=${#_current_line}

        if $_first_word_on_current_line; then
            if [ "$_word_len" -gt "$_max_width" ]; then
                _temp_long_word="$_word"
                while [ "${#_temp_long_word}" -gt "$_max_width" ]; do
                    _chunk=""
                    _build_chunk_temp_word_copy="$_temp_long_word"
                    _char_count_for_chunk=0
                    while [ "$_char_count_for_chunk" -lt "$_max_width" ] && [ -n "$_build_chunk_temp_word_copy" ]; do
                        _one_char_for_chunk="${_build_chunk_temp_word_copy%"${_build_chunk_temp_word_copy#?}"}"
                        _chunk="${_chunk}${_one_char_for_chunk}"
                        _build_chunk_temp_word_copy="${_build_chunk_temp_word_copy#?}"
                        _char_count_for_chunk=$((_char_count_for_chunk + 1))
                    done
                    
                    # Add line to result with proper record separator
                    if [ -z "$_result_lines" ]; then
                        _result_lines="$_chunk"
                    else
                        _result_lines="${_result_lines}${_LIB_MSG_RS}${_chunk}"
                    fi
                    
                    _temp_long_word=${_temp_long_word#"$_chunk"}
                done
                if [ -n "$_temp_long_word" ]; then
                    _current_line="$_temp_long_word"
                    _first_word_on_current_line=false
                else
                    _current_line=""
                    _first_word_on_current_line=true
                fi
                continue
            else
                _current_line="$_word"
                _first_word_on_current_line=false
            fi
        elif [ $((_current_line_len + 1 + _word_len)) -le "$_max_width" ]; then
            _current_line="$_current_line $_word"
        else
            # Add current line to result
            if [ -z "$_result_lines" ]; then
                _result_lines="$_current_line"
            else
                _result_lines="${_result_lines}${_LIB_MSG_RS}${_current_line}"
            fi
            
            if [ "$_word_len" -gt "$_max_width" ]; then
                _temp_long_word="$_word"
                while [ "${#_temp_long_word}" -gt "$_max_width" ]; do
                    _chunk=""
                    _build_chunk_temp_word_copy="$_temp_long_word"
                    _char_count_for_chunk=0
                    while [ "$_char_count_for_chunk" -lt "$_max_width" ] && [ -n "$_build_chunk_temp_word_copy" ]; do
                        _one_char_for_chunk="${_build_chunk_temp_word_copy%"${_build_chunk_temp_word_copy#?}"}"
                        _chunk="${_chunk}${_one_char_for_chunk}"
                        _build_chunk_temp_word_copy="${_build_chunk_temp_word_copy#?}"
                        _char_count_for_chunk=$((_char_count_for_chunk + 1))
                    done
                    
                    # Add line to result with proper record separator
                    _result_lines="${_result_lines}${_LIB_MSG_RS}${_chunk}"
                    
                    _temp_long_word=${_temp_long_word#"$_chunk"}
                done
                if [ -n "$_temp_long_word" ]; then
                     _current_line="$_temp_long_word"
                     _first_word_on_current_line=false
                else
                    _current_line=""
                    _first_word_on_current_line=true
                fi
            else
                _current_line="$_word"
                _first_word_on_current_line=false
            fi
        fi
    done

    if [ -n "$_current_line" ]; then
        # Add the final line
        if [ -z "$_result_lines" ]; then
            _result_lines="$_current_line"
        else
            _result_lines="${_result_lines}${_LIB_MSG_RS}${_current_line}"
        fi
    elif [ $# -gt 0 ] && [ -z "$_result_lines" ] && ! $_first_word_on_current_line ; then
        # This case handles if _text_to_wrap was a single word shorter than _max_width
        # and the loop finished with _current_line holding that word, but it wasn't added.
        _result_lines="$_current_line"
    fi
    
    printf "%s" "$_result_lines"
}

# AWK implementation for wrapping text (optimized)
# Uses $_LIB_MSG_RS (record separator) to delimit lines
_lib_msg_wrap_text_awk() {
    _text_to_wrap="$1"
    _max_width="$2"

    if [ -z "$_text_to_wrap" ]; then # Handle empty string special case
        # Return empty string
        printf "%s" ""
        return
    fi

    if [ "$_max_width" -le 0 ]; then # No wrapping if width is 0 or less
        printf "%s" "$_text_to_wrap"
        return
    fi

    # First convert newlines to spaces for consistent behavior with shell implementation
    _text_to_wrap_nl_normalized=$(printf '%s' "$_text_to_wrap" | tr '\n' ' ')

    _result=$(printf '%s' "$_text_to_wrap_nl_normalized" | awk -v max_width="$_max_width" -v rs="$(printf '\036')" '
    BEGIN {
        result = "";
        current_line = "";
        first_word = 1;
        line_count = 0;
    }

    function add_line(line) {
        if (result == "")
            result = line;
        else
            result = result rs line;
        line_count++;
    }

    function process_long_word(word) {
        while (length(word) > max_width) {
            chunk = substr(word, 1, max_width);
            add_line(chunk);
            word = substr(word, max_width + 1);
        }
        return word;
    }

    {
        if ($0 == "") {
            add_line("");
            next;
        }

        # Preserve exactly one space between words, but not leading/trailing spaces
        gsub(/^[ \t]+/, "");    # Remove leading spaces
        gsub(/[ \t]+$/, "");    # Remove trailing spaces
        gsub(/[ \t]+/, " ");    # Normalize multiple spaces to single space

        # Split by spaces for word processing
        split($0, words, " ");
        for (i = 1; i <= length(words); i++) {
            word = words[i];
            word_len = length(word);

            if (word_len == 0) continue;

            if (first_word) {
                if (word_len > max_width) {
                    remainder = process_long_word(word);
                    if (remainder != "") {
                        current_line = remainder;
                        first_word = 0;
                    }
                } else {
                    current_line = word;
                    first_word = 0;
                }
            } else if (length(current_line) + 1 + word_len <= max_width) {
                current_line = current_line " " word;
            } else {
                add_line(current_line);

                if (word_len > max_width) {
                    remainder = process_long_word(word);
                    if (remainder != "") {
                        current_line = remainder;
                        first_word = 0;
                    } else {
                        current_line = "";
                        first_word = 1;
                    }
                } else {
                    current_line = word;
                    first_word = 0;
                }
            }
        }

        if (current_line != "" || !first_word) {
            add_line(current_line);
        }
    }

    END {
        # Output the result directly
        printf("%s", result);
    }')

    printf "%s" "$_result"
}

# This function selects the best available text wrapping implementation (_awk or _sh)
# and returns the result as an RS-delimited string.
# The underlying implementations are POSIX sh compatible.
_lib_msg_wrap_text() {
    _text_to_wrap="$1"
    _max_width="$2"
    
    # Handle the special case of empty input or only whitespace - always create at least one line
    # First check if completely empty
    if [ -z "$_text_to_wrap" ]; then
        printf "%s" ""
        return
    fi
    
    # Then check if it's only spaces (which would be treated differently by the wrapping algorithms)
    # By removing all spaces and checking if result is empty
    _text_no_spaces="$(printf '%s' "$_text_to_wrap" | tr -d '[:space:]')"
    if [ -z "$_text_no_spaces" ]; then
        # It's only whitespace, treat as empty
        printf "%s" ""
        return
    fi
    
    # Handle special case of width <= 0 (no wrapping)
    if [ "$_max_width" -le 0 ]; then
        printf "%s" "$_text_to_wrap"
        return
    fi
    
    # Select the best implementation to get RS-delimited lines
    # First check if implementation is forced via environment variable
    if [ -n "$_LIB_MSG_FORCE_TEXT_WRAP_IMPL" ]; then
        if [ "$_LIB_MSG_FORCE_TEXT_WRAP_IMPL" = "sh" ]; then
            _result=$(_lib_msg_wrap_text_sh "$_text_to_wrap" "$_max_width")
        else
            _result=$(_lib_msg_wrap_text_awk "$_text_to_wrap" "$_max_width")
        fi
    # Otherwise check command availability each time for proper stubbing support in tests
    elif _lib_msg_has_command awk; then
        _result=$(_lib_msg_wrap_text_awk "$_text_to_wrap" "$_max_width")
    else
        _result=$(_lib_msg_wrap_text_sh "$_text_to_wrap" "$_max_width")
    fi
    
    # Return the RS-delimited string directly
    printf "%s" "$_result"
}

_lib_msg_colorize() {
    _text_to_color_val="$1"
    _color_code_val="$2"
    _is_stream_tty_val="$3"

    if [ "$_is_stream_tty_val" = "true" ] && [ -n "$_color_code_val" ] && [ -n "$_LIB_MSG_CLR_RESET" ]; then
        printf '%s%s%s' "$_color_code_val" "$_text_to_color_val" "$_LIB_MSG_CLR_RESET"
    else
        printf '%s' "$_text_to_color_val"
    fi
}

_print_msg_core() {
    _message_content="$1"
    _prefix_str="$2"
    _is_stderr="$3"
    _no_final_newline="$4"

    # Update terminal width before formatting output
    _lib_msg_update_terminal_width

    _is_tty=$_LIB_MSG_STDOUT_IS_TTY
    if [ "$_is_stderr" = "true" ]; then
        _is_tty=$_LIB_MSG_STDERR_IS_TTY
    fi

    _stripped_prefix_for_len=$(_lib_msg_strip_ansi "$_prefix_str")
    _visible_prefix_len=${#_stripped_prefix_for_len}
    _processed_output=""

    if [ "$_is_tty" = "true" ] && [ "$_LIB_MSG_TERMINAL_WIDTH" -gt 0 ]; then
        _text_wrap_width=$((_LIB_MSG_TERMINAL_WIDTH - _visible_prefix_len))

        if [ "$_text_wrap_width" -ge 5 ]; then
            # Get wrapped lines as a string with $_LIB_MSG_RS separator
            _wrapped_lines=$(_lib_msg_wrap_text "$_message_content" "$_text_wrap_width")
            
            # No lines generated? Handle empty case
            if [ -z "$_wrapped_lines" ] && [ -n "$_message_content" ]; then
                _processed_output="${_prefix_str}${_message_content}"
            else
                # Process the wrapped lines
                _indent_spaces=$(printf "%*s" "$_visible_prefix_len" "")
                _first_line=true
                _remaining_lines="$_wrapped_lines"
                
                while [ -n "$_remaining_lines" ] || $_first_line; do
                    # Extract current line (up to record separator)
                    case "$_remaining_lines" in
                        *"$_LIB_MSG_RS"*)
                            _current_line="${_remaining_lines%%"$_LIB_MSG_RS"*}"
                            _remaining_lines="${_remaining_lines#*"$_LIB_MSG_RS"}"
                            ;;
                        *)
                            _current_line="$_remaining_lines"
                            _remaining_lines=""
                            ;;
                    esac
                    
                    # Add current line to output with appropriate prefix
                    if $_first_line; then
                        _processed_output="${_prefix_str}${_current_line}"
                        _first_line=false
                    else
                        _processed_output="${_processed_output}${_LIB_MSG_NL}${_indent_spaces}${_current_line}"
                    fi
                    
                    # Break if no more lines
                    [ -z "$_remaining_lines" ] && break
                done
            fi
        else # Prefix too long for meaningful wrapping
            _processed_output="${_prefix_str}${_message_content}"
        fi
    else # Not a TTY or no terminal width for wrapping
        _processed_output="${_prefix_str}${_message_content}"
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
}

_lib_msg_is_return_valid() {
    if (return 0 2>/dev/null); then
        return 0
    else
        return 1
    fi
}

err() {
    _prefix_tag=$(_lib_msg_colorize "E: " "$_LIB_MSG_CLR_RED" "$_LIB_MSG_STDERR_IS_TTY")
    _print_msg_core "$1" "${SCRIPT_NAME:-lib_msg.sh}: ${_prefix_tag}" "true" ""
}

errn() {
    _prefix_tag=$(_lib_msg_colorize "E: " "$_LIB_MSG_CLR_RED" "$_LIB_MSG_STDERR_IS_TTY")
    _print_msg_core "$1" "${SCRIPT_NAME:-lib_msg.sh}: ${_prefix_tag}" "true" "true"
}

warn() {
    _prefix_tag=$(_lib_msg_colorize "W: " "$_LIB_MSG_CLR_YELLOW" "$_LIB_MSG_STDERR_IS_TTY")
    _print_msg_core "$1" "${SCRIPT_NAME:-lib_msg.sh}: ${_prefix_tag}" "true" ""
}

warnn() {
    _prefix_tag=$(_lib_msg_colorize "W: " "$_LIB_MSG_CLR_YELLOW" "$_LIB_MSG_STDERR_IS_TTY")
    _print_msg_core "$1" "${SCRIPT_NAME:-lib_msg.sh}: ${_prefix_tag}" "true" "true"
}

die() {
    _error_code_arg="$1"
    shift # Remove error code, remaining args are the message
    _message_arg="$*" # Combine all remaining arguments into the message string

    _actual_error_code=1 # Default
    _actual_message="$_message_arg"

    case "$_error_code_arg" in
        ''|*[!0-9]*) # Empty, or not all digits
            _actual_message="${_error_code_arg}${_message_arg:+ }$_message_arg"
            _actual_error_code=1
            ;;
        *[0-9]) # All digits
            # Check if it's a valid number for exit status (0-255 typically, but sh allows wider for return)
            # For simplicity, we'll assume any non-negative integer string is fine for the code itself.
            _actual_error_code="$_error_code_arg"
            # _actual_message remains $_message_arg
            ;;
    esac

    # Ensure we have colors initialized if stderr is forced to TTY
    # Check for both string "true" and numeric "0" for backward compatibility with tests
    if [ -n "$LIB_MSG_FORCE_STDERR_TTY" ] && { [ "$LIB_MSG_FORCE_STDERR_TTY" = "true" ] || [ "$LIB_MSG_FORCE_STDERR_TTY" = "0" ]; }; then
        _LIB_MSG_STDERR_IS_TTY="true"
        # Make sure colors are initialized if not already
        if [ -z "$_LIB_MSG_CLR_RED" ]; then
            _lib_msg_init_colors
        fi
    fi

    # Always generate these right at the point of use
    _err_color_code="$_LIB_MSG_CLR_RED"
    _reset_code="$_LIB_MSG_CLR_RESET"

    if [ "$_LIB_MSG_STDERR_IS_TTY" = "true" ] && [ -n "$_err_color_code" ] && [ -n "$_reset_code" ]; then
        _prefix_tag="${_err_color_code}E: ${_reset_code}"
    else
        _prefix_tag="E: "
    fi

    _print_msg_core "$_actual_message" "${SCRIPT_NAME:-lib_msg.sh}: ${_prefix_tag}" "true" ""

    if _lib_msg_is_return_valid; then
        return "$_actual_error_code"
    else
        exit "$_actual_error_code"
    fi
}

msg() {
    _print_msg_core "$1" "${SCRIPT_NAME:-lib_msg.sh}: " "" ""
}

msgn() {
    _print_msg_core "$1" "${SCRIPT_NAME:-lib_msg.sh}: " "" "true"
}

info() {
    _prefix_tag=$(_lib_msg_colorize "I: " "$_LIB_MSG_CLR_BLUE" "$_LIB_MSG_STDOUT_IS_TTY")
    _print_msg_core "$1" "${SCRIPT_NAME:-lib_msg.sh}: ${_prefix_tag}" "" ""
}

infon() {
    _prefix_tag=$(_lib_msg_colorize "I: " "$_LIB_MSG_CLR_BLUE" "$_LIB_MSG_STDOUT_IS_TTY")
    _print_msg_core "$1" "${SCRIPT_NAME:-lib_msg.sh}: ${_prefix_tag}" "" "true"
}