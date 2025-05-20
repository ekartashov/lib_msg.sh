#!/usr/bin/env bash

# Helper functions for lib_msg.sh BATS tests

# Resets lib_msg.sh internal TTY state variables and re-runs detection and color initialization.
# This should be called after TTY conditions have been mocked (e.g., via simulate_tty_conditions).
_lib_msg_force_reinit() {
    _LIB_MSG_STDOUT_IS_TTY=""
    _LIB_MSG_STDERR_IS_TTY=""
    # COLUMNS should be set appropriately by the calling test if a specific width is needed.
    _lib_msg_init_detection
    _lib_msg_init_colors
}

# Simulates TTY conditions by setting environment variables to control lib_msg.sh TTY detection,
# then forces lib_msg.sh to re-initialize its TTY detection and color settings.
#
# Args:
#   $1: Exit code for stdout TTY check. 0 for TTY, 1 for not TTY.
#   $2: Exit code for stderr TTY check. 0 for TTY, 1 for not TTY.
#
# Example: simulate_tty_conditions 0 1  # stdout is TTY, stderr is not
simulate_tty_conditions() {
    local stdout_tty_exit_code="$1"
    local stderr_tty_exit_code="$2"

    # Convert exit codes to true/false strings
    if [ "$stdout_tty_exit_code" -eq 0 ]; then
        export LIB_MSG_FORCE_STDOUT_TTY="true"
    else
        export LIB_MSG_FORCE_STDOUT_TTY="false"
    fi

    if [ "$stderr_tty_exit_code" -eq 0 ]; then
        export LIB_MSG_FORCE_STDERR_TTY="true"
    else
        export LIB_MSG_FORCE_STDERR_TTY="false"
    fi

    # Force library to re-initialize with our settings
    _lib_msg_force_reinit
}

# Call this in teardown to ensure '[' is unstubbed.
# Note: The main test/lib_msg.bats teardown() already does this,
# but it's good practice if helpers were to manage their own stubs.
# For now, we rely on the global teardown.
# teardown_tty_simulation() {
#     unstub '[' 2>/dev/null
# }

# Helper to assert multiline output.
# Args:
#   $1: Expected output as a single string with newlines.
#   Global $output variable from BATS `run` is used.
assert_multiline_output() {
    local expected_output="$1"
    local i=0
    local expected_line
    local actual_line

    # Save and restore IFS
    local old_ifs="$IFS"
    IFS=$'\n'
    # shellcheck disable=SC2206 # Word splitting is desired here
    local expected_lines_array=($expected_output)
    # shellcheck disable=SC2206 # Word splitting is desired here
    local actual_lines_array=($output)
    IFS="$old_ifs"

    assert_equal "${#expected_lines_array[@]}" "${#actual_lines_array[@]}" "Number of output lines mismatch."

    for i in "${!expected_lines_array[@]}"; do
        expected_line="${expected_lines_array[$i]}"
        actual_line="${actual_lines_array[$i]}"
        assert_equal "$actual_line" "$expected_line" "Output mismatch on line $((i + 1))"
    done
}

# Helper to test _lib_msg_wrap_text directly with its RS-delimited output
# Args:
#   $1: Input text to wrap
#   $2: Width to wrap at
#   $3: Expected output as a single string with newlines
assert_wrap_text_rs() {
    local input_text="$1"
    local width="$2"
    local expected_output="$3"
    
    # Get the record separator character used by lib_msg.sh
    local rs=$(printf '\036') # Same as _LIB_MSG_RS in lib_msg.sh
    
    # Call _lib_msg_wrap_text directly and capture its output
    local wrapped_output=$(_lib_msg_wrap_text "$input_text" "$width")
    
    # Convert RS-delimited output to an array for comparison
    local actual_lines_array=()
    local remaining_input="$wrapped_output"
    
    while [ -n "$remaining_input" ]; do
        case "$remaining_input" in
            *"$rs"*)
                actual_lines_array+=("${remaining_input%%"$rs"*}")
                remaining_input="${remaining_input#*"$rs"}"
                ;;
            *)
                # Handle last line or single-line case
                actual_lines_array+=("$remaining_input")
                remaining_input=""
                ;;
        esac
    done
    
    # Special case for empty output - should produce a single empty line
    if [ -z "$wrapped_output" ] && [ -z "$expected_output" ]; then
        actual_lines_array=("")
    fi
    
    # Convert expected output to an array
    local expected_lines_array=()
    if [ -n "$expected_output" ]; then
        local old_ifs="$IFS"
        IFS=$'\n'
        # shellcheck disable=SC2206 # Word splitting is desired here
        expected_lines_array=($expected_output)
        IFS="$old_ifs"
    else
        # Handle empty expected output - should be a single empty line
        expected_lines_array=("")
    fi
    
    # For debugging
    echo "Expected lines: ${#expected_lines_array[@]}, Actual lines: ${#actual_lines_array[@]}" >&3
    for i in "${!expected_lines_array[@]}"; do
        echo "  Expected[$i]: '${expected_lines_array[$i]}'" >&3
    done
    for i in "${!actual_lines_array[@]}"; do
        echo "  Actual[$i]: '${actual_lines_array[$i]}'" >&3
    done
    
    assert_equal "${#expected_lines_array[@]}" "${#actual_lines_array[@]}" "Number of wrapped lines mismatch."
    
    for i in "${!expected_lines_array[@]}"; do
        expected_line="${expected_lines_array[$i]}"
        actual_line="${actual_lines_array[$i]}"
        assert_equal "$actual_line" "$expected_line" "Wrapped line $((i + 1)) mismatch."
    done
}

# --- Terminal Size Management Helpers ---

# Save current terminal settings in global variables
# Returns 0 if successful, 1 if not
_lib_msg_test_save_terminal_settings() {
    # Initialize result variables
    _bats_saved_stty_cols=""
    _bats_saved_columns_env=""
    
    # Save original COLUMNS env var if set
    if [ -n "${COLUMNS+x}" ]; then # Check if COLUMNS is set (even if empty)
        _bats_saved_columns_env="$COLUMNS"
    fi
    
    # Check if the test is simulating stty being unavailable via mock
    if [ "${LIB_MSG_TEST_STTY_UNAVAILABLE:-}" = "true" ]; then
        return 1
    fi
    
    # Check if stty is available
    local stty_exists_code
    command -v stty >/dev/null
    stty_exists_code=$?
    
    # Use environment variables for TTY checks, controlled by the test
    local stdin_is_tty="false"
    local stdout_is_tty="false"
    
    if [ "$_BATS_TEST_STDIN_IS_TTY" = "true" ]; then
        stdin_is_tty="true"
    fi
    
    if [ "$_BATS_TEST_STDOUT_IS_TTY" = "true" ]; then
        stdout_is_tty="true"
    fi
    
    # Only get stty settings if available and relevant TTYs are detected
    if [ "$stty_exists_code" -eq 0 ] && [ "$stdin_is_tty" = "true" ] && [ "$stdout_is_tty" = "true" ]; then
        # Check if we have a mock value defined
        if [ -n "${LIB_MSG_TEST_STTY_SIZE_OUTPUT+x}" ]; then
            # Note the +x syntax tests if the variable is set, not if it's non-empty
            # Use mock output for stty size, which might be empty on purpose
            _bats_saved_stty_cols="${LIB_MSG_TEST_STTY_SIZE_OUTPUT}"
            return 0
        fi
        
        # Not mocked, try real stty
        local _stty_output
        _stty_output=$(stty size 2>/dev/null) # Capture stty size output
        
        if [ -n "$_stty_output" ]; then
            _bats_saved_stty_cols=${_stty_output##* }
            return 0
        fi
    fi
    
    # Return 1 if stty settings couldn't be saved
    return 1
}

# Set terminal width using stty and COLUMNS
# Args:
#   $1: Width to set (defaults to 80 if not provided)
_lib_msg_test_set_terminal_width() {
    local width="${1:-80}"
    
    # Check if the test is simulating stty being unavailable via mock
    if [ "${LIB_MSG_TEST_STTY_UNAVAILABLE:-}" = "true" ]; then
        # Only set COLUMNS, don't try to use stty
        export COLUMNS="$width"
        return 0
    fi
    
    # Check if stty is available
    local stty_exists_code
    command -v stty >/dev/null
    stty_exists_code=$?
    
    # Use environment variables for TTY checks
    local stdin_is_tty="false"
    local stdout_is_tty="false"
    
    if [ "$_BATS_TEST_STDIN_IS_TTY" = "true" ]; then
        stdin_is_tty="true"
    fi
    
    if [ "$_BATS_TEST_STDOUT_IS_TTY" = "true" ]; then
        stdout_is_tty="true"
    fi
    
    # Set stty columns if conditions allow
    if [ "$stty_exists_code" -eq 0 ] && [ "$stdin_is_tty" = "true" ] && [ "$stdout_is_tty" = "true" ]; then
        stty cols "$width" 2>/dev/null || true  # Don't fail if stty not available or fails
    fi
    
    # Always set COLUMNS environment variable for consistency
    export COLUMNS="$width"
}

# Restore previously saved terminal settings
_lib_msg_test_restore_terminal_settings() {
    # Check if stty is available
    local stty_exists_code
    command -v stty >/dev/null
    stty_exists_code=$?
    
    # Use environment variables for TTY checks
    local stdin_is_tty="false"
    local stdout_is_tty="false"
    
    if [ "$_BATS_TEST_STDIN_IS_TTY" = "true" ]; then
        stdin_is_tty="true"
    fi
    
    if [ "$_BATS_TEST_STDOUT_IS_TTY" = "true" ]; then
        stdout_is_tty="true"
    fi
    
    # Restore stty columns if possible
    if [ -n "$_bats_saved_stty_cols" ] && [ "$stty_exists_code" -eq 0 ] && [ "$stdin_is_tty" = "true" ] && [ "$stdout_is_tty" = "true" ]; then
        stty cols "$_bats_saved_stty_cols" 2>/dev/null
    fi
    
    # Restore original COLUMNS env var
    if [ -n "${_bats_saved_columns_env+x}" ]; then # Check if original was set
        export COLUMNS="$_bats_saved_columns_env"
    else
        unset COLUMNS # If it wasn't set originally, unset it
    fi
    
    # Clear saved values
    _bats_saved_stty_cols=""
    _bats_saved_columns_env=""
}