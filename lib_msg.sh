# shellcheck shell=sh
# lib_msg.sh - POSIX-compliant shell library for formatted messages
# License: GNU General Public License v3.0

# ========================================================================
# --- Internal State and Variables ---
# ========================================================================

# ========================================================================
# --- TTY Detection and Terminal Width Management ---
# ========================================================================

# Global sif [ -z "${LIB_MSG_FORCE_STDOUT_TTY+x}" ]; thentate variables
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
        if [ -n "${LIB_MSG_FORCE_STDOUT_TTY+x}" ]; then
            _LIB_MSG_STDOUT_IS_TTY="$LIB_MSG_FORCE_STDOUT_TTY"
        # IMPORTANT: Format must be exactly "test -t 1" for BATS stubbing to work
        elif test -t 1; then
            # Set to true if test -t 1 returns success (FD 1 is a TTY)
            _LIB_MSG_STDOUT_IS_TTY="true"
        else
            # Set to false otherwise
            _LIB_MSG_STDOUT_IS_TTY="false"
        fi

            if [ -n "${LIB_MSG_FORCE_STDERR_TTY+x}" ]; then
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
    # Ultra-optimized implementation using efficient chunk processing
    _input="$1"
    _result=""
    
    # Process the input in chunks, splitting on escape character
    while [ -n "$_input" ]; do
        # Check if the input contains an escape character
        case "$_input" in
            *"$_LIB_MSG_ESC"*)
                # Extract the part before the escape character
                _before_esc="${_input%%"$_LIB_MSG_ESC"*}"
                _result="${_result}${_before_esc}"
                
                # Remove the processed part from input
                _input="${_input#*"$_LIB_MSG_ESC"}"
                
                # Check if this is a CSI sequence (ESC[...)
                case "$_input" in
                    "["*)
                        # This is a CSI sequence, remove the leading [
                        _input="${_input#[}"
                        
                        # Use parameter expansion to find the command character
                        # This pattern matches everything up to the first letter (command char)
                        _seq_pattern='[^a-zA-Z]*'
                        
                        case "$_input" in
                            [a-zA-Z]*)
                                # First character is already a command character
                                _input="${_input#?}"
                                ;;
                            ${_seq_pattern}[a-zA-Z]*)
                                # Extract up to and including the command character
                                _cmd_part="${_input%%[a-zA-Z]*}"
                                _cmd_char="${_input#"${_cmd_part}"}"
                                _cmd_char="${_cmd_char%"${_cmd_char#?}"}"
                                
                                # Remove the ANSI sequence from input
                                _input="${_input#"${_cmd_part}""${_cmd_char}"}"
                                ;;
                            *)
                                # No command character found, preserve ESC[ literally
                                _result="${_result}${_LIB_MSG_ESC}["
                                ;;
                        esac
                        ;;
                    *)
                        # Not a CSI sequence, preserve the escape character
                        _result="${_result}${_LIB_MSG_ESC}"
                        ;;
                esac
                ;;
            *)
                # No more escape characters, add the rest and exit
                _result="${_result}${_input}"
                _input=""
                ;;
        esac
    done
    
    printf '%s' "$_result"
}


# Select the best available implementation for stripping ANSI sequences
# Performance testing shows the optimized shell implementation is now consistently
# faster than sed across all input sizes, so we prioritize it
_lib_msg_strip_ansi() {
    # Use optimized shell implementation by default as it's now faster
    _lib_msg_strip_ansi_shell "$1"
}

# ========================================================================
# --- Text Wrapping Implementations ---
# ========================================================================

# POSIX sh implementation (no arrays) for wrapping text
# Uses $_LIB_MSG_RS (record separator) to delimit lines for POSIX compatibility
_lib_msg_wrap_text_sh() {
    _text_to_wrap="$1"
    _max_width="$2"
    _max_wrap_length="${3:-0}"  # Optional third parameter, default 0 (unlimited)
    
    # Early returns for special cases
    if [ -z "$_text_to_wrap" ]; then
        printf "%s" ""
        return
    fi
    
    if [ "$_max_width" -le 0 ]; then # No wrapping if width is 0 or less
        printf "%s" "$_text_to_wrap"
        return
    fi
    
    # Validate max_wrap_length parameter (negative values mean unlimited)
    if [ "$_max_wrap_length" -lt 0 ]; then
        _max_wrap_length=0  # Treat negative as unlimited
    fi
    
    # Replace newlines with spaces
    _text_to_wrap="$(_lib_msg_tr_newline_to_space "$_text_to_wrap")"
    
    # Use simple and reliable IFS-based word splitting to avoid infinite loops
    _result_lines=""
    _current_line=""
    _current_line_len=0
    _total_output_len=0  # Track total output length for max_wrap_length
    
    # Save original IFS and set to space for word splitting
    _old_IFS="$IFS"
    IFS=' '
    
    # Split text into words using IFS
    # shellcheck disable=SC2086 # Intentional word splitting
    set -- $_text_to_wrap
    
    # Restore original IFS
    IFS="$_old_IFS"
    
    # Process each word
    for _word in "$@"; do
        # Skip empty words
        if [ -z "$_word" ]; then
            continue
        fi
        
        _word_len=${#_word}
        
        # Check max_wrap_length before processing this word
        if [ "$_max_wrap_length" -gt 0 ]; then
            # Calculate what the total length would be if we add this word to current line
            _potential_current_line_len=$((_current_line_len + _word_len))
            if [ -n "$_current_line" ]; then
                _potential_current_line_len=$((_potential_current_line_len + 1))  # Account for space
            fi
            
            # Calculate what total output length would be with this expanded current line
            _potential_total_len="$_total_output_len"
            if [ -n "$_result_lines" ]; then
                _potential_total_len=$((_potential_total_len + 1))  # Account for RS before current line
            fi
            _potential_total_len=$((_potential_total_len + _potential_current_line_len))
            
            # If adding this word would exceed max_wrap_length, truncate and break
            if [ "$_potential_total_len" -gt "$_max_wrap_length" ]; then
                # Try to fit part of the word if there's space
                _remaining_space=$((_max_wrap_length - _total_output_len))
                if [ -n "$_result_lines" ]; then
                    _remaining_space=$((_remaining_space - 1))  # Account for record separator
                fi
                _remaining_space=$((_remaining_space - _current_line_len))
                if [ -n "$_current_line" ]; then
                    _remaining_space=$((_remaining_space - 1))  # Account for space before word
                fi
                
                if [ "$_remaining_space" -gt 0 ] && [ "$_remaining_space" -le "$_word_len" ]; then
                    # Truncate the word to fit remaining space
                    _truncated_word=$(printf "%.${_remaining_space}s" "$_word")
                    
                    # Add truncated word to current line
                    if [ -z "$_current_line" ]; then
                        _current_line="$_truncated_word"
                    else
                        _current_line="$_current_line $_truncated_word"
                    fi
                fi
                break  # Stop processing more words
            fi
        fi
        
        # Quick check: if word is longer than max width, handle separately
        if [ "$_word_len" -gt "$_max_width" ]; then
            # Add current line to results if not empty
            if [ -n "$_current_line" ]; then
                if [ -z "$_result_lines" ]; then
                    _result_lines="$_current_line"
                    _total_output_len=${#_current_line}
                else
                    _result_lines="${_result_lines}${_LIB_MSG_RS}${_current_line}"
                    _total_output_len=$((_total_output_len + 1 + ${#_current_line}))  # +1 for RS
                fi
                _current_line=""
                _current_line_len=0
            fi
            
            # OPTIMIZATION: Use efficient oversized word splitting with substr simulation
            _remaining_word="$_word"
            while [ "${#_remaining_word}" -gt "$_max_width" ]; do
                # Check max_wrap_length before adding more chunks
                if [ "$_max_wrap_length" -gt 0 ]; then
                    _chunk_len="$_max_width"
                    _potential_len=$((_total_output_len + _chunk_len))
                    if [ -n "$_result_lines" ]; then
                        _potential_len=$((_potential_len + 1))  # Account for RS
                    fi
                    
                    if [ "$_potential_len" -gt "$_max_wrap_length" ]; then
                        # Calculate how much space is left
                        _remaining_space=$((_max_wrap_length - _total_output_len))
                        if [ -n "$_result_lines" ]; then
                            _remaining_space=$((_remaining_space - 1))  # Account for RS
                        fi
                        
                        if [ "$_remaining_space" -gt 0 ]; then
                            _chunk=$(printf "%.${_remaining_space}s" "$_remaining_word")
                            if [ -z "$_result_lines" ]; then
                                _result_lines="$_chunk"
                            else
                                _result_lines="${_result_lines}${_LIB_MSG_RS}${_chunk}"
                            fi
                        fi
                        break  # Stop processing due to length limit
                    fi
                fi
                
                # Extract chunk using printf precision - this is reliable and fast
                _chunk=$(printf "%.${_max_width}s" "$_remaining_word")
                
                # Add chunk to results
                if [ -z "$_result_lines" ]; then
                    _result_lines="$_chunk"
                    _total_output_len=${#_chunk}
                else
                    _result_lines="${_result_lines}${_LIB_MSG_RS}${_chunk}"
                    _total_output_len=$((_total_output_len + 1 + ${#_chunk}))  # +1 for RS
                fi
                
                # Remove processed chunk from remaining word
                _remaining_word="${_remaining_word#"$_chunk"}"
            done
            
            # Handle the last piece of the word if any
            if [ -n "$_remaining_word" ]; then
                # Check if adding this piece would exceed max_wrap_length
                if [ "$_max_wrap_length" -gt 0 ]; then
                    _potential_len=$((_total_output_len + ${#_remaining_word}))
                    if [ -n "$_result_lines" ]; then
                        _potential_len=$((_potential_len + 1))  # Account for RS if this becomes a new line
                    fi
                    
                    if [ "$_potential_len" -gt "$_max_wrap_length" ]; then
                        # Skip this piece as it would exceed the limit
                        break
                    fi
                fi
                
                _current_line="$_remaining_word"
                _current_line_len=${#_remaining_word}
            fi
            continue
        fi
        
        # OPTIMIZATION: Calculate new length once and reuse
        _new_line_len=$((_current_line_len + 1 + _word_len))
        
        # Normal case: word fits or starts a new line
        if [ -z "$_current_line" ]; then
            # First word on line
            _current_line="$_word"
            _current_line_len="$_word_len"
        elif [ "$_new_line_len" -le "$_max_width" ]; then
            # Word fits on current line with a space
            _current_line="$_current_line $_word"
            _current_line_len="$_new_line_len"
        else
            # Word would overflow, start a new line
            if [ -z "$_result_lines" ]; then
                _result_lines="$_current_line"
                _total_output_len=${#_current_line}
            else
                _result_lines="${_result_lines}${_LIB_MSG_RS}${_current_line}"
                _total_output_len=$((_total_output_len + 1 + ${#_current_line}))  # +1 for RS
            fi
            
            # Before starting new line with this word, check max_wrap_length
            if [ "$_max_wrap_length" -gt 0 ]; then
                _potential_new_len=$((_total_output_len + 1 + _word_len))  # +1 for RS
                if [ "$_potential_new_len" -gt "$_max_wrap_length" ]; then
                    # Adding this word as a new line would exceed limit, truncate current result
                    break
                fi
            fi
            
            _current_line="$_word"
            _current_line_len="$_word_len"
        fi
    done
    
    # Add the last line if not empty
    if [ -n "$_current_line" ]; then
        # Check max_wrap_length before adding the final line
        if [ "$_max_wrap_length" -gt 0 ]; then
            _potential_len=$((_total_output_len + ${#_current_line}))
            if [ -n "$_result_lines" ]; then
                _potential_len=$((_potential_len + 1))  # Account for RS
            fi
            
            if [ "$_potential_len" -gt "$_max_wrap_length" ]; then
                # Truncate the final line to fit within max_wrap_length
                _remaining_space=$((_max_wrap_length - _total_output_len))
                if [ -n "$_result_lines" ]; then
                    _remaining_space=$((_remaining_space - 1))  # Account for RS
                fi
                
                if [ "$_remaining_space" -gt 0 ]; then
                    _truncated_line=$(printf "%.${_remaining_space}s" "$_current_line")
                    if [ -z "$_result_lines" ]; then
                        _result_lines="$_truncated_line"
                    else
                        _result_lines="${_result_lines}${_LIB_MSG_RS}${_truncated_line}"
                    fi
                fi
            else
                # Final line fits within limit
                if [ -z "$_result_lines" ]; then
                    _result_lines="$_current_line"
                else
                    _result_lines="${_result_lines}${_LIB_MSG_RS}${_current_line}"
                fi
            fi
        else
            # No max_wrap_length limit
            if [ -z "$_result_lines" ]; then
                _result_lines="$_current_line"
            else
                _result_lines="${_result_lines}${_LIB_MSG_RS}${_current_line}"
            fi
        fi
    fi
    
    # Return the result
    printf "%s" "$_result_lines"
}


# Convert newlines to spaces using optimized shell implementation
_lib_msg_tr_newline_to_space() {
    _input="$1"
    
    # Fast path: if no newlines, just return the input
    case "$_input" in
        *"$_LIB_MSG_NL"*) : ;; # Contains newlines, continue with processing
        *) printf '%s' "$_input"; return ;; # No newlines, return input as is
    esac
    
    # OPTIMIZATION: Use simple substitution approach for reliability and speed
    # This handles all edge cases correctly while still being fast
    _result="$_input"
    
    # Replace all newlines with spaces using a simple loop
    # This preserves empty segments correctly (newline -> space)
    while [ "$_result" != "${_result#*"$_LIB_MSG_NL"}" ]; do
        # Replace first newline with space
        _before="${_result%%"$_LIB_MSG_NL"*}"
        _after="${_result#*"$_LIB_MSG_NL"}"
        _result="${_before} ${_after}"
    done
    
    printf '%s' "$_result"
}

# Remove all whitespace using optimized shell implementation
_lib_msg_tr_remove_whitespace() {
    _input="$1"
    
    # Fast path: if no whitespace, just return the input
    case "$_input" in
        *[[:space:]]*) : ;; # Contains whitespace, continue with processing
        *) printf '%s' "$_input"; return ;; # No whitespace, return input as is
    esac
    
    # OPTIMIZATION: Use chunk processing instead of character-by-character
    # This is much faster for large inputs
    _result=""
    _remaining="$_input"
    
    # Process by removing each type of whitespace systematically
    # This avoids the expensive character-by-character loop
    while [ -n "$_remaining" ]; do
        case "$_remaining" in
            *[[:space:]]*)
                # Find first whitespace character and split around it
                # Use parameter expansion to efficiently skip whitespace chunks
                
                # Handle leading whitespace first
                case "$_remaining" in
                    [[:space:]]*)
                        # Remove leading whitespace characters
                        while [ -n "$_remaining" ]; do
                            case "$_remaining" in
                                [[:space:]]*) _remaining="${_remaining#?}" ;;
                                *) break ;;
                            esac
                        done
                        ;;
                    *)
                        # Extract chunk before next whitespace
                        _chunk="${_remaining%%[[:space:]]*}"
                        _result="${_result}${_chunk}"
                        _remaining="${_remaining#"$_chunk"}"
                        ;;
                esac
                ;;
            *)
                # No more whitespace, append remainder
                _result="${_result}${_remaining}"
                _remaining=""
                ;;
        esac
    done
    
    printf '%s' "$_result"
}

# This function performs text wrapping
# and returns the result as an RS-delimited string.
_lib_msg_wrap_text() {
    _text_to_wrap="$1"
    _max_width="$2"
    _max_wrap_length="${3:-0}"  # Optional third parameter, default 0 (unlimited)
    
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
    
    # Use the pure shell implementation (for optimal performance)
    _result=$(_lib_msg_wrap_text_sh "$_text_to_wrap" "$_max_width" "$_max_wrap_length")
    
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
    if [ -n "${LIB_MSG_FORCE_STDERR_TTY+x}" ] && { [ "$LIB_MSG_FORCE_STDERR_TTY" = "true" ] || [ "$LIB_MSG_FORCE_STDERR_TTY" = "0" ]; }; then
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

    # Convert space-separated list to semicolon-separated for SGR using pure shell
    _sgr_param=""
    _remaining="$_sgr_codes"
    _first=true
    
    # Process space-separated codes using parameter expansion
    while [ -n "$_remaining" ]; do
        case "$_remaining" in
            *" "*)
                _current="${_remaining%% *}"
                _remaining="${_remaining#* }"
                ;;
            *)
                _current="$_remaining"
                _remaining=""
                ;;
        esac
        
        if $_first; then
            _sgr_param="$_current"
            _first=false
        else
            _sgr_param="${_sgr_param};${_current}"
        fi
    done
    
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
# Args: $1 = text to wrap, $2 = max width (0 for terminal width), $3 = max wrap length (optional, 0 = unlimited)
# Returns: wrapped text with newlines
lib_msg_get_wrapped_text() {
    _text="$1"
    _width="$2"
    _max_wrap_length="${3:-0}"  # Optional third parameter, default 0 (unlimited)
    
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
    _wrapped_text=$(_lib_msg_wrap_text "$_text" "$_width" "$_max_wrap_length")
    
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

# Display a yes/no prompt and return the result via exit code
# Args: $1 = prompt text, $2 = prompt style (optional), $3 = default char (Y/y/N/n, mandatory)
# Returns: exit code 0 for yes, 1 for no
lib_msg_prompt_yn() {
    _prompt_text="$1"
    _prompt_style="${2:-}"
    _default_char="$3"
    
    # Validate that default_char is provided and valid
    case "$_default_char" in
        [YyNn]) : ;; # Valid input, continue
        *)
            # Invalid or missing default_char, show error and exit/return
            err "lib_msg_prompt_yn: Third argument (default_char) is mandatory and must be Y, y, N, or n"
            return 1
            ;;
    esac
    
    # Normalize default_char to determine actual default and display format
    case "$_default_char" in
        [Yy])
            _default="y"
            _display_format="[Y/n]"
            ;;
        [Nn])
            _default="n"
            _display_format="[y/N]"
            ;;
    esac
    
    # Create colored Q: prefix and apply style if specified
    _prefix_tag=$(_lib_msg_colorize "Q: " "$_LIB_MSG_CLR_MAGENTA" "$_LIB_MSG_STDOUT_IS_TTY")
    
    # Apply prompt style to the entire prompt text if style is provided
    if [ -n "$_prompt_style" ]; then
        case "$_prompt_style" in
            "bracketed")
                # Bracketed style: wrap prompt text in brackets
                _styled_prompt_text="[${_prompt_text}]"
                ;;
            "simple")
                # Simple style: use prompt text as-is (no brackets)
                _styled_prompt_text="$_prompt_text"
                ;;
            *)
                # Default/unknown style: use prompt text as-is
                _styled_prompt_text="$_prompt_text"
                ;;
        esac
    else
        # No style specified, use prompt text as-is
        _styled_prompt_text="$_prompt_text"
    fi
    
    # Construct the complete prompt message for text wrapping
    _complete_prompt_message="${_styled_prompt_text} ${_display_format}: "
    
    # Use _print_msg_core for consistent text wrapping with other functions
    # This ensures the prompt text wraps properly like err(), msg(), etc.
    _print_msg_core "$_complete_prompt_message" "${SCRIPT_NAME:-lib_msg.sh}: ${_prefix_tag}" "false" "true"
    
    # Read input directly
    read -r _answer
    
    # Convert to lowercase and trim using pure shell
    _answer=$(printf "%s" "$_answer")
    
    # Convert to lowercase using POSIX-compatible approach
    _lower_answer=""
    _remaining="$_answer"
    
    # Process character by character using POSIX parameter expansion
    while [ -n "$_remaining" ]; do
        # Extract first character
        _char="${_remaining%"${_remaining#?}"}"
        _remaining="${_remaining#?}"
        
        case "$_char" in
            [A-Z])
                # Convert uppercase to lowercase using case statement
                case "$_char" in
                    A) _char="a" ;; B) _char="b" ;; C) _char="c" ;; D) _char="d" ;;
                    E) _char="e" ;; F) _char="f" ;; G) _char="g" ;; H) _char="h" ;;
                    I) _char="i" ;; J) _char="j" ;; K) _char="k" ;; L) _char="l" ;;
                    M) _char="m" ;; N) _char="n" ;; O) _char="o" ;; P) _char="p" ;;
                    Q) _char="q" ;; R) _char="r" ;; S) _char="s" ;; T) _char="t" ;;
                    U) _char="u" ;; V) _char="v" ;; W) _char="w" ;; X) _char="x" ;;
                    Y) _char="y" ;; Z) _char="z" ;;
                esac
                ;;
        esac
        
        # Skip whitespace characters entirely
        case "$_char" in
            [[:space:]]) : ;; # Skip whitespace
            *) _lower_answer="${_lower_answer}${_char}" ;;
        esac
    done
    
    _answer="$_lower_answer"
    
    # Handle empty input with the mandatory default
    if [ -z "$_answer" ]; then
        _answer="$_default"
    fi
    
    # Check input and return appropriate exit code
    case "$_answer" in
        y|yes)
            return 0  # Success/yes
            ;;
        n|no)
            return 1  # No
            ;;
        *)
            # Invalid input, default to no
            return 1
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
    _width="${3:-0}"
    _filled_char="${4:-#}"
    _empty_char="${5:--}"
    
    # Validate inputs
    if [ "$_current" -lt 0 ]; then _current=0; fi
    if [ "$_max" -le 0 ]; then _max=1; fi
    if [ "$_current" -gt "$_max" ]; then _current="$_max"; fi
    if [ "$_width" -le 0 ]; then _width=20; fi
    
    # Calculate percentage
    _percent=$(( _current * 100 / _max ))
    
    # Calculate padding spaces for right-aligned percentage text
    # Always reserve 4 characters for "100%" and pad shorter percentages
    if [ "$_percent" -ge 100 ]; then
        _percent_padding=""     # 1 space for "100%"
    elif [ "$_percent" -ge 10 ]; then
        _percent_padding=" "    # 2 spaces for "10%" to "99%"
    else
        _percent_padding="  "   # 3 spaces for "0%" to "9%"
    fi
    
    # The width parameter specifies the total output width
    # Total output width will be content_width + 9 (for brackets, space, and percentage)
    _bar_content_width="$((_width - 9))"
    
    # Ensure minimum bar width
    if [ "$_bar_content_width" -lt 1 ]; then _bar_content_width=1; fi
    
    # Calculate filled portion based on adjusted width
    _filled_count=$(( _current * _bar_content_width / _max ))
    _empty_count=$(( _bar_content_width - _filled_count ))
    
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
    
    # Return formatted progress bar with right-aligned percentage
    printf "[%s] [%s%d%%]" "$_progress" "$_percent_padding" "$_percent"
}