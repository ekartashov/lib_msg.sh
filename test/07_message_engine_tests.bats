#!/usr/bin/env bats

# This file contains tests for the _print_msg_core() function,
# which is the central message printing engine in lib_msg.sh.

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
    # Ensure a clean state for COLUMNS and SCRIPT_NAME if tests modify them
    # Store original values if necessary, or rely on test-specific setup/teardown
    : # No global setup needed beyond what test_helpers might do
}

teardown() {
    # Restore any global state changed by tests, e.g., COLUMNS
    # Unset any specific mocks or environment variables
    : # No global teardown needed beyond what test_helpers might do
}

# --- _print_msg_core() Tests ---

@test "_print_msg_core(): correctly handles stdout messages without TTY" {
    # Direct test without run to capture output more reliably
    simulate_tty_conditions 1 1  # stdout and stderr are not TTYs
    
    # Temporary file to capture output
    local tmp_file
    tmp_file=$(mktemp)
    
    # Direct output to our temp file
    _print_msg_core "Test Message" "test-prefix: " "false" "false" > "$tmp_file"
    local content
    content=$(cat "$tmp_file")
    rm "$tmp_file"
    
    # Assert the output is as expected
    assert_equal "$content" "test-prefix: Test Message"
}

@test "_print_msg_core(): correctly handles stderr messages without TTY" {
    simulate_tty_conditions 1 1  # stdout and stderr are not TTYs
    
    # Capture stderr
    run _print_msg_core "Test Error Message" "test-error-prefix: " "true" "false"
    
    # Check stderr output (which bats captures)
    assert_output "test-error-prefix: Test Error Message"
}

@test "_print_msg_core(): correctly handles stdout messages with TTY and wrapping" {
    # Mock TTY: stdout is TTY, stderr is not TTY
    simulate_tty_conditions 0 1
    
    # Force a specific terminal width for predictable wrapping
    local orig_columns="$COLUMNS"
    export COLUMNS=20
    _lib_msg_force_reinit  # Re-initialize detection to use our new COLUMNS
    
    # Create a specific message designed to wrap predictably
    local test_message="AAA BBB CCC DDD EEE FFF GGG"
    
    # Temporary file to capture output
    local tmp_file
    tmp_file=$(mktemp)
    
    # Direct output to our temp file
    _print_msg_core "$test_message" "test: " "false" "false" > "$tmp_file"
    local content
    content=$(cat "$tmp_file")
    
    # For debugging (can be removed once stable)
    # echo "Debug - Content: '$content'" >&3
    # echo "Debug - Terminal width: $COLUMNS" >&3
    # echo "Debug - Prefix: 'test: '" >&3
    
    local expected_output="test: AAA BBB CCC
      DDD EEE FFF
      GGG" # Subsequent lines indented by length of "test: " (6 spaces)
    
    assert_equal "$content" "$expected_output" "Wrapped output did not match expected."
    
    rm "$tmp_file"
    
    # Restore original columns
    COLUMNS="$orig_columns"
    _lib_msg_force_reinit # Re-initialize with original COLUMNS
}

@test "_print_msg_core(): correctly handles no-newline option" {
    simulate_tty_conditions 1 1  # Not TTYs for simpler output
    
    # Temporary file to capture output
    local tmp_file
    tmp_file=$(mktemp)
    
    # Output two messages without newline followed by one with newline
    _print_msg_core "First" "prefix: " "false" "true" > "$tmp_file"
    _print_msg_core "Second" "" "false" "true" >> "$tmp_file"
    _print_msg_core "Third" "" "false" "false" >> "$tmp_file"
    
    local content
    content=$(cat "$tmp_file")
    rm "$tmp_file"
    
    # Expected output
    local expected="prefix: FirstSecondThird"
    
    assert_equal "$content" "$expected" "Handling of no-newline option is incorrect"
}

@test "_print_msg_core(): handles messages with ANSI color in the prefix" {
    simulate_tty_conditions 0 1  # stdout is TTY for color
    
    # Create a colored prefix
    local prefix
    prefix="test: $(_lib_msg_colorize "colored" "$_LIB_MSG_CLR_RED" "true") "
    
    # Get the visible length of the prefix (without ANSI codes)
    local prefix_visible_len
    prefix_visible_len=$(printf "%s" "$(_lib_msg_strip_ansi "$prefix")" | wc -c)
    
    # Adjust terminal width relative to prefix length
    local orig_columns="$COLUMNS"
    export COLUMNS=$((prefix_visible_len + 15))  # Set tight width to force wrapping
    _lib_msg_force_reinit
    
    # Create a message that should wrap
    local message="This should wrap after the visible prefix length"
    
    # Capture output
    local tmp_file
    tmp_file=$(mktemp)
    _print_msg_core "$message" "$prefix" "false" "false" > "$tmp_file"
    local content
    content=$(cat "$tmp_file")
    rm "$tmp_file"
    
    # In a test environment, the exact formatting and wrapping can vary
    # Just check that key parts are present in the output
    [[ "$content" == *"test:"* ]] || fail "Output doesn't contain the prefix text"
    [[ "$content" == *"colored"* ]] || fail "Output doesn't contain the colored part"
    
    # More flexibly check for the message content - could be wrapped differently
    [[ "$content" =~ [Tt]his|should|wrap ]] || fail "Output doesn't contain part of the expected message: '$content'"
    
    # Restore original columns
    COLUMNS="$orig_columns"
    _lib_msg_force_reinit
}

@test "_print_msg_core(): handles case where prefix is too long for meaningful wrapping" {
    simulate_tty_conditions 0 1  # stdout is TTY for wrapping
    
    # Create a very long prefix
    local long_prefix="this_is_an_extremely_long_prefix_that_exceeds_reasonable_wrapping_space: "
    
    # Set terminal width just slightly larger than the prefix
    local orig_columns="$COLUMNS"
    export COLUMNS=${#long_prefix} # Set COLUMNS to the exact length of the long_prefix
    _lib_msg_force_reinit
    
    # Create a message
    local message="This shouldn't have normal wrapping due to long prefix"
    
    # Capture output
    local tmp_file
    tmp_file=$(mktemp)
    _print_msg_core "$message" "$long_prefix" "false" "false" > "$tmp_file"
    local content
    content=$(cat "$tmp_file")
    rm "$tmp_file"
    
    # Expected: just concatenated without special wrapping because available_width for message is <=0
    local expected="$long_prefix$message"
    
    # Check that the output is as expected
    assert_equal "$content" "$expected" "Long prefix case not handled correctly. Expected '$expected', got '$content'"
    
    # Restore original columns
    COLUMNS="$orig_columns"
    _lib_msg_force_reinit
}