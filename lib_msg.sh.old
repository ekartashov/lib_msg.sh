# shellcheck shell=sh

# --- lib_msg TTY and Width Detection (Initialize Once) ---
_LIB_MSG_STDOUT_IS_TTY="" # Unset initially
_LIB_MSG_STDERR_IS_TTY="" # Unset initially
_LIB_MSG_TERMINAL_WIDTH=0   # Default to 0 (no wrapping)

_lib_msg_init_detection() {
    # TTY detection - only run if not already set
    if [ -z "$_LIB_MSG_STDOUT_IS_TTY" ]; then
        # Allow overriding TTY detection via environment variables for testing
        if [ -n "$LIB_MSG_FORCE_STDOUT_TTY" ]; then
            _LIB_MSG_STDOUT_IS_TTY="$LIB_MSG_FORCE_STDOUT_TTY"
        elif [ -t 1 ]; then
            _LIB_MSG_STDOUT_IS_TTY="true"
        else
            _LIB_MSG_STDOUT_IS_TTY="false"
        fi

        if [ -n "$LIB_MSG_FORCE_STDERR_TTY" ]; then
            _LIB_MSG_STDERR_IS_TTY="$LIB_MSG_FORCE_STDERR_TTY"
        elif [ -t 2 ]; then
            _LIB_MSG_STDERR_IS_TTY="true"
        else
            _LIB_MSG_STDERR_IS_TTY="false"
        fi
    fi

    _LIB_MSG_TERMINAL_WIDTH=0
    if [ "$_LIB_MSG_STDOUT_IS_TTY" = "true" ] || [ "$_LIB_MSG_STDERR_IS_TTY" = "true" ]; then
        _temp_cols="${COLUMNS:-}"
        case "$_temp_cols" in
            ''|*[!0-9]*) _LIB_MSG_TERMINAL_WIDTH=0 ;;
            0) _LIB_MSG_TERMINAL_WIDTH=0 ;;
            0*) _LIB_MSG_TERMINAL_WIDTH=0 ;;
            *[0-9]) _LIB_MSG_TERMINAL_WIDTH="$_temp_cols" ;;
            *) _LIB_MSG_TERMINAL_WIDTH=0 ;;
        esac
    fi
}
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

_LIB_MSG_NL=$(printf '\n')
_LIB_MSG_ESC=$(printf '\033')
# --- End lib_msg TTY and Width Detection ---

# Global array to be populated by _lib_msg_wrap_text
lines=()

# Internal function to wrap text.
# Populates the global `lines` array.
# Usage: _lib_msg_wrap_text "message_content" "max_content_width"
_lib_msg_wrap_text() {
    _text_to_wrap="$1"
    _max_width="$2"
    lines=() # Initialize/clear global array

    _temp_text_for_check="$_text_to_wrap"
    _old_ifs_check="$IFS"
    IFS=' '
    # shellcheck disable=SC2086 # Word splitting is desired here for counting
    set -- $_temp_text_for_check
    _word_count=$#
    IFS="$_old_ifs_check"
    set -- # Clear positional params from check

    if [ "$_word_count" -eq 0 ]; then # Input was empty or all spaces
        lines+=("") # Represents a single empty line
        return
    fi

    if [ "$_max_width" -le 0 ]; then # No wrapping if width is 0 or less
        lines+=("$_text_to_wrap")
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
                    lines+=("$_chunk")
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
            lines+=("$_current_line")
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
                    lines+=("$_chunk")
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
        lines+=("$_current_line")
    elif [ $# -gt 0 ] && [ ${#lines[@]} -eq 0 ] && ! $_first_word_on_current_line ; then
        # This case handles if _text_to_wrap was a single word shorter than _max_width
        # and the loop finished with _current_line holding that word, but it wasn't added.
        # This should ideally be caught by `if [ -n "$_current_line" ]`
        # For safety, if loop ran ( $# > 0 ), lines is empty, but _current_line was processed.
        # This path is unlikely if the logic is correct.
        :
    fi
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

_lib_msg_strip_ansi_shell() {
    _input_str_to_strip="$1"
    _result_str=""
    _remaining_input="$_input_str_to_strip"

    while [ -n "$_remaining_input" ]; do
        case "$_remaining_input" in
            "$_LIB_MSG_ESC"*)
                _after_esc="${_remaining_input#"$_LIB_MSG_ESC"}"
                if [ "${_after_esc%"${_after_esc#?}"}" = "[" ]; then
                    _sequence_part="${_after_esc#?}"
                    _params_and_cmd="$_sequence_part"
                    _cmd_char=""
                    _loop_idx=0
                    _max_loop_idx=${#_params_and_cmd}

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
                                ;;
                            [a-zA-Z])
                                _cmd_char="$_current_param_char"
                                _temp_str_for_remainder="$_params_and_cmd"
                                _remainder_idx_iter=0
                                _num_chars_to_chop=$((_loop_idx + 1))
                                while [ "$_remainder_idx_iter" -lt "$_num_chars_to_chop" ]; do
                                    _temp_str_for_remainder="${_temp_str_for_remainder#?}"
                                    _remainder_idx_iter=$((_remainder_idx_iter + 1))
                                done
                                _remaining_input="$_temp_str_for_remainder"
                                break
                                ;;
                            *)
                                _cmd_char=""
                                _remaining_input=""
                                break
                                ;;
                        esac
                        _loop_idx=$((_loop_idx + 1))
                    done

                    if [ -z "$_cmd_char" ]; then
                         _result_str="${_result_str}${_LIB_MSG_ESC}["
                         _remaining_input="$_sequence_part"
                    fi
                else
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

_print_msg_core() {
    _message_content="$1"
    _prefix_str="$2"
    _is_stderr="$3"
    _no_final_newline="$4"

    _is_tty=$_LIB_MSG_STDOUT_IS_TTY
    if [ "$_is_stderr" = "true" ]; then
        _is_tty=$_LIB_MSG_STDERR_IS_TTY
    fi

    _stripped_prefix_for_len=$(_lib_msg_strip_ansi_shell "$_prefix_str")
    _visible_prefix_len=${#_stripped_prefix_for_len}
    _processed_output=""

    if [ "$_is_tty" = "true" ] && [ "$_LIB_MSG_TERMINAL_WIDTH" -gt 0 ]; then
        _text_wrap_width=$((_LIB_MSG_TERMINAL_WIDTH - _visible_prefix_len))

        if [ "$_text_wrap_width" -ge 5 ]; then
            _lib_msg_wrap_text "$_message_content" "$_text_wrap_width" # Populates global `lines`

            if [ ${#lines[@]} -eq 0 ] && [ -n "$_message_content" ]; then
                # Fallback if wrap_text produced no lines for non-empty content (should not happen)
                lines+=("$_message_content")
            elif [ ${#lines[@]} -eq 0 ] && [ -z "$_message_content" ]; then
                # if message content is empty, wrap_text should have lines=("")
                # This case should be covered by wrap_text's initial check.
                # For safety, if lines is empty and message was empty, ensure one empty line.
                 lines+=("")
            fi


            _first_line_in_loop=true
            _indent_spaces=$(printf "%*s" "$_visible_prefix_len" "")

            for _wrapped_line_content in "${lines[@]}"; do
                if $_first_line_in_loop; then
                    _processed_output="${_prefix_str}${_wrapped_line_content}"
                    _first_line_in_loop=false
                else
                    _processed_output="${_processed_output}${_LIB_MSG_NL}${_indent_spaces}${_wrapped_line_content}"
                fi
            done
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

    _prefix_tag=$(_lib_msg_colorize "E: " "$_LIB_MSG_CLR_RED" "$_LIB_MSG_STDERR_IS_TTY")
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
