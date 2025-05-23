# shellcheck shell=sh
# lib_msg.sh - POSIX-compliant shell library for formatted messages
# License: GNU General Public License v3.0

# ========================================================================
# --- Internal Utility Functions ---
# ========================================================================

_lib_msg_has_command() {
    # Check if a command is available (works with BATS command stubbing)
    if ! command -v "$1" >/dev/null 2>&1; then
        return 1
    fi
    return 0
}

# ========================================================================
# --- TTY Detection and Terminal Width Management ---
# ========================================================================

# Global state variables
_LIB_MSG_STDOUT_IS_TTY=""  # Unset initially
_LIB_MSG_STDERR_IS_TTY=""  # Unset initially
_LIB_MSG_TERMINAL_WIDTH=0  # Default to 0 (no wrapping)

# Function for test force-reinitialization (used by tests)
# This allows tests to reset the library state between test cases
_lib_msg_force_reinit() {
    _LIB_MSG_STDOUT_IS_TTY=""
    _LIB_MSG_STDERR_IS_TTY=""
    _LIB_MSG_TERMINAL_WIDTH=0
    _lib_msg_init_detection
    _lib_msg_init_colors
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

    # Initialize terminal width
    _lib_msg_update_terminal_width
}

# Updates terminal width by checking COLUMNS env var
# Called before each public API function to ensure we have the current width
_lib_msg_update_terminal_width() {
    # Always start with width 0, then evaluate conditions
    _LIB_MSG_TERMINAL_WIDTH=0

    # Critical: If both stdout and stderr are not TTY, always use width 0
    if [ "$_LIB_MSG_STDOUT_IS_TTY" = "false" ] && [ "$_LIB_MSG_STDERR_IS_TTY" = "false" ]; then
        return
    fi
    
    # One or both streams is a TTY, check COLUMNS
    _temp_cols="${COLUMNS:-}"
    case "$_temp_cols" in
        ''|*[!0-9]*) _LIB_MSG_TERMINAL_WIDTH=0 ;;
        0|0*) _LIB_MSG_TERMINAL_WIDTH=0 ;;
        *[0-9]) _LIB_MSG_TERMINAL_WIDTH="$_temp_cols" ;;
    esac
}

# Initialize TTY detection at library load time
_lib_msg_init_detection

# ========================================================================
# --- ANSI Color Codes and Special Characters ---
# ========================================================================

# Color code variables
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

# SGR (Select Graphic Rendition) code constants for public API
# These are exported to allow users to build custom style sequences
# Format/Style codes
export _LIB_MSG_SGR_RESET="0"      # Reset all styles
export _LIB_MSG_SGR_BOLD="1"       # Bold/increased intensity
export _LIB_MSG_SGR_FAINT="2"      # Faint/decreased intensity
export _LIB_MSG_SGR_ITALIC="3"     # Italic
export _LIB_MSG_SGR_UNDERLINE="4"  # Underline
export _LIB_MSG_SGR_BLINK="5"      # Slow blink
export _LIB_MSG_SGR_INVERT="7"     # Invert foreground/background
export _LIB_MSG_SGR_HIDE="8"       # Conceal/hide text
export _LIB_MSG_SGR_STRIKE="9"     # Strikethrough

# Foreground color codes (normal intensity)
export _LIB_MSG_SGR_FG_BLACK="30"
export _LIB_MSG_SGR_FG_RED="31"
export _LIB_MSG_SGR_FG_GREEN="32"
export _LIB_MSG_SGR_FG_YELLOW="33"
export _LIB_MSG_SGR_FG_BLUE="34"
export _LIB_MSG_SGR_FG_MAGENTA="35"
export _LIB_MSG_SGR_FG_CYAN="36"
export _LIB_MSG_SGR_FG_WHITE="37"

# Foreground color codes (bright intensity)
export _LIB_MSG_SGR_FG_BRIGHT_BLACK="90"
export _LIB_MSG_SGR_FG_BRIGHT_RED="91"
export _LIB_MSG_SGR_FG_BRIGHT_GREEN="92"
export _LIB_MSG_SGR_FG_BRIGHT_YELLOW="93"
export _LIB_MSG_SGR_FG_BRIGHT_BLUE="94"
export _LIB_MSG_SGR_FG_BRIGHT_MAGENTA="95"
export _LIB_MSG_SGR_FG_BRIGHT_CYAN="96"
export _LIB_MSG_SGR_FG_BRIGHT_WHITE="97"

# Background color codes (normal intensity)
export _LIB_MSG_SGR_BG_BLACK="40"
export _LIB_MSG_SGR_BG_RED="41"
export _LIB_MSG_SGR_BG_GREEN="42"
export _LIB_MSG_SGR_BG_YELLOW="43"
export _LIB_MSG_SGR_BG_BLUE="44"
export _LIB_MSG_SGR_BG_MAGENTA="45"
export _LIB_MSG_SGR_BG_CYAN="46"
export _LIB_MSG_SGR_BG_WHITE="47"

# Background color codes (bright intensity)
export _LIB_MSG_SGR_BG_BRIGHT_BLACK="100"
export _LIB_MSG_SGR_BG_BRIGHT_RED="101"
export _LIB_MSG_SGR_BG_BRIGHT_GREEN="102"
export _LIB_MSG_SGR_BG_BRIGHT_YELLOW="103"
export _LIB_MSG_SGR_BG_BRIGHT_BLUE="104"
export _LIB_MSG_SGR_BG_BRIGHT_MAGENTA="105"
export _LIB_MSG_SGR_BG_BRIGHT_CYAN="106"
export _LIB_MSG_SGR_BG_BRIGHT_WHITE="107"

# Internal state for color configuration
_LIB_MSG_COLORS_ENABLED="false"

# Special characters for internal use
_LIB_MSG_NL='
'
_LIB_MSG_ESC=$(printf '\033')
_LIB_MSG_RS=$(printf '\036') # Record Separator (unlikely to appear in normal text)

_lib_msg_init_colors() {
    # Reset all color codes first
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
    
    # Default: colors disabled
    _LIB_MSG_COLORS_ENABLED="false"
    
    # First determine if we *should* enable colors according to policy
    # Get color mode configuration
    _color_mode="${LIB_MSG_COLOR_MODE:-auto}"
    
    # Check NO_COLOR (standard env var that disables colors when set)
    # Unless color mode is 'force_on', NO_COLOR takes precedence when set
    if [ -n "${NO_COLOR+x}" ] && [ "$_color_mode" != "force_on" ]; then
        # NO_COLOR is set, colors are definitely OFF
        return
    fi
    
    # Check specific color mode values
    case "$_color_mode" in
        off)
            # Colors explicitly disabled
            return
            ;;
        force_on)
            # Attempt to enable colors, ignoring NO_COLOR
            # Still respect TTY check and TERM=dumb check below
            ;;
        on|auto|*)
            # 'on', 'auto', or any unrecognized value: default behavior
            # NO_COLOR check was already done above
            ;;
    esac
    
    # Next, check if any stream is actually a TTY and TERM isn't "dumb"
    # Only enable colors if at least one output stream is a TTY
    if { [ "$_LIB_MSG_STDOUT_IS_TTY" = "true" ] || [ "$_LIB_MSG_STDERR_IS_TTY" = "true" ]; } && \
       [ "${TERM:-}" != "dumb" ]; then
        # TTY detected and TERM is not "dumb"
        _LIB_MSG_COLORS_ENABLED="true"
        
        # Initialize color escape sequences
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

# Initialize colors at library load time
_lib_msg_init_colors

# ========================================================================
# --- ANSI Escape Sequence Handling ---
# ========================================================================

# Pure shell implementation for stripping ANSI escape sequences
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
# Checks availability each time to work properly with command stubbing in tests
_lib_msg_strip_ansi() {
    if _lib_msg_has_command sed; then
        # Use optimized sed implementation if available
        _lib_msg_strip_ansi_sed "$1"
    else
        # Fall back to pure shell implementation
        _lib_msg_strip_ansi_shell "$1"
    fi
}

# ========================================================================
# --- Text Wrapping Implementations ---
# ========================================================================

# POSIX sh implementation (no arrays) for wrapping text
# Uses $_LIB_MSG_RS (record separator) to delimit lines for POSIX compatibility
_lib_msg_wrap_text_sh() {
    _text_to_wrap="$1"
    _max_width="$2"
    _result_lines=""
    
    # Replace newlines with spaces to match AWK implementation behavior
    # This is crucial to ensure similar handling of multi-line input across both implementations
    # The tr command needs to be properly escaped to handle input with special characters
    _text_to_wrap="$(_lib_msg_tr_newline_to_space "$_text_to_wrap")"
    
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
    _text_to_wrap_nl_normalized="$(_lib_msg_tr_newline_to_space "$_text_to_wrap")"

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

# Pure shell implementation to replace tr for newline to space conversion
_lib_msg_tr_newline_to_space_shell() {
    _input="$1"
    _result=""
    _i=0
    
    while [ "$_i" -lt "${#_input}" ]; do
        _char="${_input:$_i:1}"
        if [ "$_char" = $'\n' ]; then
            _result="${_result} "
        else
            _result="${_result}${_char}"
        fi
        _i=$((_i + 1))
    done
    
    printf '%s' "$_result"
}

# Pure shell implementation to replace tr for removing whitespace
_lib_msg_tr_remove_whitespace_shell() {
    _input="$1"
    _result=""
    _i=0
    
    while [ "$_i" -lt "${#_input}" ]; do
        _char="${_input:$_i:1}"
        case "$_char" in
            " "|$'\t'|$'\n'|$'\r'|$'\v'|$'\f')
                # Skip whitespace
                ;;
            *)
                _result="${_result}${_char}"
                ;;
        esac
        _i=$((_i + 1))
    done
    
    printf '%s' "$_result"
}

# Function to convert newlines to spaces using best available method
_lib_msg_tr_newline_to_space() {
    _input="$1"
    
    if _lib_msg_has_command tr; then
        printf '%s' "$_input" | tr '\n' ' '
    else
        _lib_msg_tr_newline_to_space_shell "$_input"
    fi
}

# Function to remove all whitespace using best available method
_lib_msg_tr_remove_whitespace() {
    _input="$1"
    
    if _lib_msg_has_command tr; then
        printf '%s' "$_input" | tr -d '[:space:]'
    else
        _lib_msg_tr_remove_whitespace_shell "$_input"
    fi
}

# This function selects the best available text wrapping implementation
# and returns the result as an RS-delimited string.
_lib_msg_wrap_text() {
    _text_to_wrap="$1"
    _max_width="$2"
    
    # Handle the special case of empty input or only whitespace
    if [ -z "$_text_to_wrap" ]; then
        printf "%s" ""
        return
    fi
    
    # Check if input is only whitespace
    _text_no_spaces="$(_lib_msg_tr_remove_whitespace "$_text_to_wrap")"
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
    
    # Select the best implementation for text wrapping
    if [ -n "$_LIB_MSG_FORCE_TEXT_WRAP_IMPL" ]; then
        # Implementation forced via environment variable (for testing)
        if [ "$_LIB_MSG_FORCE_TEXT_WRAP_IMPL" = "sh" ]; then
            _result=$(_lib_msg_wrap_text_sh "$_text_to_wrap" "$_max_width")
        else
            _result=$(_lib_msg_wrap_text_awk "$_text_to_wrap" "$_max_width")
        fi
    # Check command availability each time for proper stubbing support in tests
    elif _lib_msg_has_command awk; then
        # Use optimized awk implementation if available
        _result=$(_lib_msg_wrap_text_awk "$_text_to_wrap" "$_max_width")
    else
        # Fall back to pure shell implementation
        _result=$(_lib_msg_wrap_text_sh "$_text_to_wrap" "$_max_width")
    fi
    
    # Return the RS-delimited string
    printf "%s" "$_result"
}

# Helper function to colorize text if TTY
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

# Core function that handles message formatting and output
# All public API functions ultimately call this
_print_msg_core() {
    _message_content="$1"
    _prefix_str="$2"
    _is_stderr="$3"
    _no_final_newline="$4"

    # Update terminal width before formatting output
    # This is critical for dynamic width detection
    _lib_msg_update_terminal_width

    # Determine if output stream is a TTY
    _is_tty=$_LIB_MSG_STDOUT_IS_TTY
    if [ "$_is_stderr" = "true" ]; then
        _is_tty=$_LIB_MSG_STDERR_IS_TTY
    fi

    # Calculate visible prefix length (without ANSI codes)
    _stripped_prefix_for_len=$(_lib_msg_strip_ansi "$_prefix_str")
    _visible_prefix_len=${#_stripped_prefix_for_len}
    _processed_output=""

    # Handle text wrapping if we're outputting to a TTY and have a valid width
    if [ "$_is_tty" = "true" ] && [ "$_LIB_MSG_TERMINAL_WIDTH" -gt 0 ]; then
        _text_wrap_width=$((_LIB_MSG_TERMINAL_WIDTH - _visible_prefix_len))

        # Only wrap if we have enough space for meaningful text (at least 5 chars)
        if [ "$_text_wrap_width" -ge 5 ]; then
            # Get wrapped lines as a string with $_LIB_MSG_RS separator
            _wrapped_lines=$(_lib_msg_wrap_text "$_message_content" "$_text_wrap_width")
            
            # Handle special case: empty wrapped lines but non-empty message content
            if [ -z "$_wrapped_lines" ] && [ -n "$_message_content" ]; then
                _processed_output="${_prefix_str}${_message_content}"
            else
                # Process the wrapped lines with proper indentation
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
                    
                    # Add current line to output with appropriate prefix/indentation
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
        else
            # Prefix too long for meaningful wrapping, so don't wrap
            _processed_output="${_prefix_str}${_message_content}"
        fi
    else
        # Not a TTY or no terminal width for wrapping
        _processed_output="${_prefix_str}${_message_content}"
    fi

    # Output the processed message to the appropriate stream
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

# ========================================================================
# --- Core Message Formatting and Display ---
# ========================================================================

# Helper function to detect if a 'return' statement is valid in the current context
# Used by die() to determine whether to exit or return
_lib_msg_is_return_valid() {
    if (return 0 2>/dev/null); then
        return 0
    else
        return 1
    fi
}

# ========================================================================
# --- Public API Functions ---
# ========================================================================

# Output an error message to stderr with red "E:" prefix and newline
err() {
    _prefix_tag=$(_lib_msg_colorize "E: " "$_LIB_MSG_CLR_RED" "$_LIB_MSG_STDERR_IS_TTY")
    _print_msg_core "$1" "${SCRIPT_NAME:-lib_msg.sh}: ${_prefix_tag}" "true" ""
}

# Output an error message to stderr with red "E:" prefix and NO newline
errn() {
    _prefix_tag=$(_lib_msg_colorize "E: " "$_LIB_MSG_CLR_RED" "$_LIB_MSG_STDERR_IS_TTY")
    _print_msg_core "$1" "${SCRIPT_NAME:-lib_msg.sh}: ${_prefix_tag}" "true" "true"
}

# Output a warning message to stderr with yellow "W:" prefix and newline
warn() {
    _prefix_tag=$(_lib_msg_colorize "W: " "$_LIB_MSG_CLR_YELLOW" "$_LIB_MSG_STDERR_IS_TTY")
    _print_msg_core "$1" "${SCRIPT_NAME:-lib_msg.sh}: ${_prefix_tag}" "true" ""
}

# Output a warning message to stderr with yellow "W:" prefix and NO newline
warnn() {
    _prefix_tag=$(_lib_msg_colorize "W: " "$_LIB_MSG_CLR_YELLOW" "$_LIB_MSG_STDERR_IS_TTY")
    _print_msg_core "$1" "${SCRIPT_NAME:-lib_msg.sh}: ${_prefix_tag}" "true" "true"
}

# Output a fatal error message to stderr and exit (or return if in sourced context)
# Usage: die [exit_code] "message"
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

# Output a standard message to stdout with newline
msg() {
    _print_msg_core "$1" "${SCRIPT_NAME:-lib_msg.sh}: " "" ""
}

# Output a standard message to stdout with NO newline
msgn() {
    _print_msg_core "$1" "${SCRIPT_NAME:-lib_msg.sh}: " "" "true"
}

# Output an information message to stdout with blue "I:" prefix and newline
info() {
    _prefix_tag=$(_lib_msg_colorize "I: " "$_LIB_MSG_CLR_BLUE" "$_LIB_MSG_STDOUT_IS_TTY")
    _print_msg_core "$1" "${SCRIPT_NAME:-lib_msg.sh}: ${_prefix_tag}" "" ""
}

# Output an information message to stdout with blue "I:" prefix and NO newline
infon() {
    _prefix_tag=$(_lib_msg_colorize "I: " "$_LIB_MSG_CLR_BLUE" "$_LIB_MSG_STDOUT_IS_TTY")
    _print_msg_core "$1" "${SCRIPT_NAME:-lib_msg.sh}: ${_prefix_tag}" "" "true"
}

# ========================================================================
# --- Public API Functions for TTY State and Terminal Width ---
# ========================================================================

# Check if stdout is a TTY
# Returns: "true" or "false" string
lib_msg_stdout_is_tty() {
    printf "%s" "$_LIB_MSG_STDOUT_IS_TTY"
}

# Check if stderr is a TTY
# Returns: "true" or "false" string
lib_msg_stderr_is_tty() {
    printf "%s" "$_LIB_MSG_STDERR_IS_TTY"
}

# Get current terminal width (0 if not a TTY or width unknown)
# Returns: integer width in columns
lib_msg_get_terminal_width() {
    printf "%s" "$_LIB_MSG_TERMINAL_WIDTH"
}

# Force update terminal width from current COLUMNS value
# Returns: updated terminal width
lib_msg_update_terminal_width() {
    _lib_msg_update_terminal_width
    printf "%s" "$_LIB_MSG_TERMINAL_WIDTH"
}

# ========================================================================
# --- Public API Functions for Color Support ---
# ========================================================================

# Check if colors are enabled
# Returns: "true" or "false" string
lib_msg_colors_enabled() {
    printf "%s" "$_LIB_MSG_COLORS_ENABLED"
}

# Redetect color support based on current environment
# Returns: "true" if colors now enabled, "false" otherwise
lib_msg_reinit_colors() {
    _lib_msg_init_colors
    printf "%s" "$_LIB_MSG_COLORS_ENABLED"
}

# ========================================================================
# --- Public API Functions for Text Styling ---
# ========================================================================

# Build an ANSI style sequence from SGR codes
# Args: list of SGR codes, separated by spaces
# Returns: Complete ANSI escape sequence or empty string if colors disabled
lib_msg_build_style_sequence() {
    if [ "$_LIB_MSG_COLORS_ENABLED" != "true" ]; then
        # Colors disabled, return empty string
        return
    fi

    _sgr_codes="$*"
    if [ -z "$_sgr_codes" ]; then
        # No codes provided, use reset
        _sgr_codes="$_LIB_MSG_SGR_RESET"
    fi

    # Convert space-separated list to semicolon-separated for SGR
    _sgr_param=$(printf '%s' "$_sgr_codes" | tr ' ' ';')
    
    # Return the complete escape sequence
    printf '\033[%sm' "$_sgr_param"
}

# Apply styling to text if colors are enabled
# Args: $1 = text, $2 = style sequence (from lib_msg_build_style_sequence)
# Returns: styled text if colors enabled, original text otherwise
lib_msg_apply_style() {
    _text="$1"
    _style="$2"
    
    if [ "$_LIB_MSG_COLORS_ENABLED" = "true" ] && [ -n "$_style" ]; then
        printf '%s%s%s' "$_style" "$_text" "$_LIB_MSG_CLR_RESET"
    else
        printf '%s' "$_text"
    fi
}

# Apply styling to text if output stream is a TTY
# Args: $1 = text, $2 = style sequence, $3 = "true" for stderr, anything else for stdout
# Returns: styled text if appropriate stream is TTY, original text otherwise
lib_msg_apply_style_if_tty() {
    _text="$1"
    _style="$2"
    _use_stderr="$3"
    
    _is_tty="$_LIB_MSG_STDOUT_IS_TTY"
    if [ "$_use_stderr" = "true" ]; then
        _is_tty="$_LIB_MSG_STDERR_IS_TTY"
    fi
    
    if [ "$_is_tty" = "true" ] && [ "$_LIB_MSG_COLORS_ENABLED" = "true" ] && [ -n "$_style" ]; then
        printf '%s%s%s' "$_style" "$_text" "$_LIB_MSG_CLR_RESET"
    else
        printf '%s' "$_text"
    fi
}

# ========================================================================
# --- Public API Functions for Text Processing ---
# ========================================================================

# Strip ANSI escape sequences from text
# Args: $1 = text with ANSI sequences
# Returns: text without any ANSI sequences
lib_msg_strip_ansi() {
    _lib_msg_strip_ansi "$1"
}

# Wrap text to specified width using newlines, respecting terminal width if width=0
# Args: $1 = text to wrap, $2 = max width (0 for terminal width)
# Returns: wrapped text with newlines
lib_msg_get_wrapped_text() {
    _text="$1"
    _width="$2"
    
    # Handle case where caller wants to use terminal width
    if [ "$_width" -eq 0 ]; then
        _width="$_LIB_MSG_TERMINAL_WIDTH"
        # If terminal width is still 0, don't wrap
        if [ "$_width" -eq 0 ]; then
            printf '%s' "$_text"
            return
        fi
    fi
    
    # Get wrapped text as RS-delimited string
    _wrapped_text=$(_lib_msg_wrap_text "$_text" "$_width")
    
    # Convert RS to newlines for public API
    if [ -z "$_wrapped_text" ]; then
        printf '%s' "$_text"
        return
    fi
    
    # Replace RS with newlines
    _remaining="$_wrapped_text"
    _result=""
    _first=true
    
    while [ -n "$_remaining" ]; do
        case "$_remaining" in
            *"$_LIB_MSG_RS"*)
                _current="${_remaining%%"$_LIB_MSG_RS"*}"
                _remaining="${_remaining#*"$_LIB_MSG_RS"}"
                ;;
            *)
                _current="$_remaining"
                _remaining=""
                ;;
        esac
        
        if $_first; then
            _result="$_current"
            _first=false
        else
            _result="${_result}${_LIB_MSG_NL}${_current}"
        fi
    done
    
    printf '%s' "$_result"
}

# ========================================================================
# --- Public API Functions for Custom Message Output ---
# ========================================================================

# Output a message with optional prefix, styled based on TTY
# Args: $1 = message, $2 = prefix (optional), $3 = style (optional), $4 = "true" for stderr (optional)
# Returns: nothing
lib_msg_output() {
    _message="$1"
    _prefix="${2:-}"
    _style="${3:-}"
    _use_stderr="${4:-false}"
    _no_newline="${5:-false}"
    
    # Apply style to prefix if needed
    if [ -n "$_prefix" ] && [ -n "$_style" ]; then
        _prefix="$(lib_msg_apply_style_if_tty "$_prefix" "$_style" "$_use_stderr")"
    fi
    
    # Determine stream
    _is_tty="$_LIB_MSG_STDOUT_IS_TTY"
    if [ "$_use_stderr" = "true" ]; then
        _is_tty="$_LIB_MSG_STDERR_IS_TTY"
    fi
    
    # Call the core print function
    _print_msg_core "$_message" "$_prefix" "$_use_stderr" "$_no_newline"
}

# Output a message to stdout/stderr with NO newline
# Args: same as lib_msg_output
# Returns: nothing
lib_msg_output_n() {
    lib_msg_output "$1" "${2:-}" "${3:-}" "${4:-false}" "true"
}

# ========================================================================
# --- Public API Functions for Prompts ---
# ========================================================================

# Display a prompt and read user input
# Args: $1 = prompt text, $2 = default value (optional), $3 = prompt style (optional)
# Returns: user input (echoes to stdout)
lib_msg_prompt() {
    _prompt_text="$1"
    _default_val="${2:-}"
    _prompt_style="${3:-}"
    
    # Prepare the complete prompt text
    if [ -n "$_default_val" ]; then
        _display_text="$_prompt_text [$_default_val]: "
    else
        _display_text="$_prompt_text: "
    fi
    
    # Display prompt with styling but no newline
    lib_msg_output_n "$_display_text" "" "$_prompt_style" "false"
    
    # Read user input
    read -r _user_input
    
    # Return default if user input is empty
    if [ -z "$_user_input" ] && [ -n "$_default_val" ]; then
        printf "%s" "$_default_val"
    else
        printf "%s" "$_user_input"
    fi
}

# Display a yes/no prompt and return the result
# Args: $1 = prompt text, $2 = default (y/n, optional), $3 = prompt style (optional)
# Returns: "true" for yes, "false" for no
lib_msg_prompt_yn() {
    _prompt_text="$1"
    _default="${2:-}"
    _prompt_style="${3:-}"
    
    # Normalize default to lowercase
    case "$_default" in
        [Yy]|[Yy][Ee][Ss]) _default="y" ;;
        [Nn]|[Nn][Oo]) _default="n" ;;
        *) _default="" ;;
    esac
    
    # Simplified implementation - directly ask for y/n
    if [ "$_default" = "y" ]; then
        printf "%s [Y/n]: " "$_prompt_text"
    elif [ "$_default" = "n" ]; then
        printf "%s [y/N]: " "$_prompt_text"
    else
        printf "%s [y/n]: " "$_prompt_text"
    fi
    
    # Read input directly
    read -r _answer
    
    # Convert to lowercase and trim
    _answer=$(printf "%s" "$_answer" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
    
    # Handle empty input with default
    if [ -z "$_answer" ] && [ -n "$_default" ]; then
        _answer="$_default"
    fi
    
    # Check input
    case "$_answer" in
        y|yes|true|1)
            printf "true"
            ;;
        n|no|false|0)
            printf "false"
            ;;
        *)
            # Invalid input, default to false
            printf "false"
            ;;
    esac
}

# ========================================================================
# --- Public API Convenience Functions ---
# ========================================================================

# Get a predefined style sequence for common styles
# Args: $1 = style name (error, warning, info, success, highlight, dim)
# Returns: ANSI style sequence
lib_msg_get_style() {
    _style_name="$1"
    
    case "$_style_name" in
        error)
            # Bold red
            lib_msg_build_style_sequence "$_LIB_MSG_SGR_BOLD" "$_LIB_MSG_SGR_FG_RED"
            ;;
        warning)
            # Bold yellow
            lib_msg_build_style_sequence "$_LIB_MSG_SGR_BOLD" "$_LIB_MSG_SGR_FG_YELLOW"
            ;;
        info)
            # Bold blue
            lib_msg_build_style_sequence "$_LIB_MSG_SGR_BOLD" "$_LIB_MSG_SGR_FG_BLUE"
            ;;
        success)
            # Bold green
            lib_msg_build_style_sequence "$_LIB_MSG_SGR_BOLD" "$_LIB_MSG_SGR_FG_GREEN"
            ;;
        highlight)
            # Bold cyan
            lib_msg_build_style_sequence "$_LIB_MSG_SGR_BOLD" "$_LIB_MSG_SGR_FG_CYAN"
            ;;
        dim)
            # Faint white
            lib_msg_build_style_sequence "$_LIB_MSG_SGR_FAINT" "$_LIB_MSG_SGR_FG_WHITE"
            ;;
        *)
            # Empty string for unknown style
            printf ""
            ;;
    esac
}

# Create a prefix with a tag, e.g. "[TAG] "
# Args: $1 = tag text, $2 = style (optional), $3 = bracket style (optional)
# Returns: formatted prefix string with styling if enabled
lib_msg_create_prefix() {
    _tag="$1"
    _tag_style="${2:-}"
    _bracket_style="${3:-}"
    
    if [ -z "$_tag" ]; then
        # Empty tag, return empty prefix
        return
    fi
    
    if [ -n "$_bracket_style" ]; then
        _left_bracket=$(lib_msg_apply_style "[" "$_bracket_style")
        _right_bracket=$(lib_msg_apply_style "]" "$_bracket_style")
    else
        _left_bracket="["
        _right_bracket="]"
    fi
    
    if [ -n "$_tag_style" ]; then
        _styled_tag=$(lib_msg_apply_style "$_tag" "$_tag_style")
    else
        _styled_tag="$_tag"
    fi
    
    printf '%s%s%s ' "$_left_bracket" "$_styled_tag" "$_right_bracket"
}

# Generate a progress bar
# Args: $1 = current value, $2 = max value, $3 = width (default 20), $4 = filled char (default #), $5 = empty char (default -)
# Returns: text progress bar
lib_msg_progress_bar() {
    _current="$1"
    _max="$2"
    _width="${3:-20}"
    _filled_char="${4:-#}"
    _empty_char="${5:--}"
    
    # Validate inputs
    if [ "$_current" -lt 0 ]; then _current=0; fi
    if [ "$_max" -le 0 ]; then _max=1; fi
    if [ "$_current" -gt "$_max" ]; then _current="$_max"; fi
    if [ "$_width" -le 0 ]; then _width=20; fi
    
    # Calculate filled portion
    _filled_count=$(( _current * _width / _max ))
    _empty_count=$(( _width - _filled_count ))
    
    # Generate progress bar
    _progress=""
    
    # Add filled portion
    _i=0
    while [ "$_i" -lt "$_filled_count" ]; do
        _progress="${_progress}${_filled_char}"
        _i=$(( _i + 1 ))
    done
    
    # Add empty portion
    _i=0
    while [ "$_i" -lt "$_empty_count" ]; do
        _progress="${_progress}${_empty_char}"
        _i=$(( _i + 1 ))
    done
    
    # Calculate percentage
    _percent=$(( _current * 100 / _max ))
    
    # Return formatted progress bar
    printf "[%s] %d%%" "$_progress" "$_percent"
}