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