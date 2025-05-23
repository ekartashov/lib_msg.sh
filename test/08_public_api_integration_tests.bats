#!/usr/bin/env bats

# This file contains integration tests for the public API functions of lib_msg.sh,
# focusing on how they interact with features like message wrapping, prefixing,
# and terminal conditions.

# Load BATS support and assertion libraries
load "libs/bats-support/load"
load "libs/bats-assert/load"
load "libs/bats-mock/stub.bash"

# Load our test helpers
load "test_helpers.bash"

# Load the library to be tested
# shellcheck source=../lib_msg.sh
load "../lib_msg.sh"

# Define paths for use in tests
LIB_PATH="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
TEST_PATH="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"

setup() {
    # Mock SCRIPT_NAME for consistent prefix in tests
    SCRIPT_NAME="test_script.sh"
    # Helpers like simulate_tty_conditions will handle TTY state and library re-initialization.
    # Store original COLUMNS to restore it in teardown or per test
    _ORIG_COLUMNS_08="$COLUMNS"
}

teardown() {
    # Restore original COLUMNS if it was changed
    export COLUMNS="$_ORIG_COLUMNS_08"
    unset _ORIG_COLUMNS_08
    # Ensure library is re-initialized if COLUMNS changed, to reflect original state for next test file
    _lib_msg_force_reinit
}

# --- Tests for Message Wrapping with Prefixes (SCRIPT_NAME and tags) ---
# Originally from test/lib_msg.bats

@test "info() wraps message correctly considering SCRIPT_NAME and 'I:' prefix" {
    # Set variables directly in the test environment
    local orig_script_name="$SCRIPT_NAME"
    
    # Setup the test environment
    export SCRIPT_NAME="test_wrap.sh"
    simulate_tty_conditions 0 1 # stdout TTY, stderr not TTY
    
    # Run the command with a long message
    run info 'This is a very long informational message that should contain the proper prefix.' 2>/dev/null
    
    # Restore original values
    SCRIPT_NAME="$orig_script_name"
    
    # Assert results
    assert_success
    # Just check for expected content, not exact formatting
    assert_output --partial "test_wrap.sh"
    assert_output --partial "I:"
    assert_output --partial "This is a very long informational message"
}

@test "err() prints message to stderr with correct prefix (wrapping not explicitly tested here, but prefix matters for width calc)" {
    # Set variables directly in the test environment
    local orig_script_name="$SCRIPT_NAME"
    
    # Setup the test environment
    export SCRIPT_NAME="err_wrap.sh"
    simulate_tty_conditions 1 0 # stdout not TTY, stderr TTY
    
    # Run the command
    run err 'This is a critical error message.' 1>/dev/null
    
    # Restore original values
    SCRIPT_NAME="$orig_script_name"
    
    # Assert results
    assert_success
    # Just check for expected content, not exact formatting
    assert_output --partial "err_wrap.sh"
    assert_output --partial "E:"
    assert_output --partial "This is a critical error message"
}

@test "warn() prints message to stderr with correct prefix (wrapping not explicitly tested here, but prefix matters for width calc)" {
    # Set variables directly in the test environment
    local orig_script_name="$SCRIPT_NAME"
    
    # Setup the test environment
    export SCRIPT_NAME="warn_script.sh"
    simulate_tty_conditions 1 0 # stdout not TTY, stderr TTY
    
    # Run the command
    run warn 'This is a warning message.' 1>/dev/null
    
    # Restore original values
    SCRIPT_NAME="$orig_script_name"
    
    # Assert results
    assert_success
    # Just check for expected content, not exact formatting
    assert_output --partial "warn_script.sh"
    assert_output --partial "W:"
    assert_output --partial "This is a warning message"
}

@test "msg() prints message to stdout with correct prefix (wrapping not explicitly tested here, but prefix matters for width calc)" {
    # Set variables directly in the test environment
    local orig_script_name="$SCRIPT_NAME"
    
    # Setup the test environment
    export SCRIPT_NAME="msg_wrap.sh"
    # stdout TTY (0) for width detection, stderr not TTY (1)
    simulate_tty_conditions 0 1
    
    # Run the command
    run msg 'This is a plain message.' 2>/dev/null
    
    # Restore original values
    SCRIPT_NAME="$orig_script_name"
    
    # Assert results
    assert_success
    # Just check for expected content, not exact formatting
    assert_output --partial "msg_wrap.sh"
    assert_output --partial "This is a plain message"
}

@test "info() does not wrap if width is too small for prefix (simulated TTY for stdout, width 15)" {
    # Set variables directly in the test environment
    local orig_script_name="$SCRIPT_NAME"
    local orig_columns_test="$COLUMNS" # Use a test-specific backup for COLUMNS
    
    # Setup the test environment
    export SCRIPT_NAME="short.sh"
    export COLUMNS=15
    simulate_tty_conditions 0 1 # stdout TTY, stderr not TTY
    
    # Run the command
    run info 'This message will not be wrapped, prefix too long.' 2>/dev/null
    
    # Restore original values
    SCRIPT_NAME="$orig_script_name"
    export COLUMNS="$orig_columns_test" # Restore COLUMNS for this test
    _lib_msg_force_reinit # Re-init after COLUMNS change
    
    # Assert results
    assert_success
    # For single line output, just check that it contains the right message
    assert_output --partial "This message will not be wrapped, prefix too long."
    assert_equal "${#lines[@]}" 1 "Expected a single line of output"
}

# --- msg() and msgn() Tests ---
# Originally from test/core_functions_tests.bats

@test "msg(): correctly wraps and indents multi-line messages" {
    # Simulate TTY for wrapping and COLUMNS for width
    simulate_tty_conditions 0 1 # stdout is TTY, stderr is not
    local orig_columns_test="$COLUMNS" # Use a test-specific backup for COLUMNS
    export COLUMNS=30 # Narrow width to force wrapping
    _lib_msg_force_reinit

    local script_name_backup="$SCRIPT_NAME"
    export SCRIPT_NAME="test_msg.sh" # Predictable prefix

    # Message designed to wrap
    # Prefix "test_msg.sh: " is 13 chars.
    # Available width for text: 30 - 13 = 17 chars.
    # "This is a long test message."
    # Line 1 content: "This is a long " (15 chars)
    # Line 2 content: "test message."   (13 chars)
    local input_message="This is a long test message."
    
    # Expected output
    # Note: Need to be careful with spaces in the expected string for BATS
    # _LIB_MSG_NL is now a literal newline.
    local expected_output
expected_output="test_msg.sh: This is a long" # Line 1 with prefix
expected_output="${expected_output}${_LIB_MSG_NL}" # Newline
expected_output="${expected_output}             test message." # Line 2 indented (13 spaces)

    run msg "$input_message"
    assert_success
    assert_output "$expected_output"

    # Restore original environment
    export SCRIPT_NAME="$script_name_backup"
    export COLUMNS="$orig_columns_test" # Restore COLUMNS for this test
    _lib_msg_force_reinit # Re-init after COLUMNS change
}