#!/usr/bin/env bats
# Tests for text transformation functions in lib_msg.sh

# Load BATS support and assertion libraries
load "libs/bats-support/load"
load "libs/bats-assert/load"
load "libs/bats-mock/stub.bash"

# Load our test helpers
load "test_helpers.bash"

# Load the library to be tested
load "../lib_msg.sh"

# Define paths for use in tests
LIB_PATH="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
TEST_PATH="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"

setup() {
    SCRIPT_NAME="test_tr_alternatives.sh"
}

teardown() {
    # Clean up env vars that might be set by tests
    unset LIB_MSG_FORCE_STDOUT_TTY LIB_MSG_FORCE_STDERR_TTY
}

# --- Tests for _lib_msg_tr_newline_to_space() ---

@test "_lib_msg_tr_newline_to_space(): converts newlines to spaces" {
    input="Line1
Line2
Line3"
    expected="Line1 Line2 Line3"
    result=$(_lib_msg_tr_newline_to_space "$input")
    assert_equal "$result" "$expected"
}

@test "_lib_msg_tr_newline_to_space(): handles empty input" {
    result=$(_lib_msg_tr_newline_to_space "")
    assert_equal "$result" ""
}

@test "_lib_msg_tr_newline_to_space(): handles input with only newlines" {
    input="

"
    expected="  "
    result=$(_lib_msg_tr_newline_to_space "$input")
    assert_equal "$result" "$expected"
}

@test "_lib_msg_tr_newline_to_space(): handles mixed content with special characters" {
    input="Line1 with *special* chars!
Line2 with \"quotes\" and $variables
Line3 with \\escapes\\"
    expected="Line1 with *special* chars! Line2 with \"quotes\" and $variables Line3 with \\escapes\\"
    result=$(_lib_msg_tr_newline_to_space "$input")
    assert_equal "$result" "$expected"
}

@test "_lib_msg_tr_newline_to_space(): handles fast path with no newlines" {
    input="Line with no newlines"
    result=$(_lib_msg_tr_newline_to_space "$input")
    assert_equal "$result" "$input"
}

# --- Tests for _lib_msg_tr_remove_whitespace() ---

@test "_lib_msg_tr_remove_whitespace(): removes all whitespace" {
    input="  This has spaces tabs	and
newlines  "
    expected="Thishasspacestabsandnewlines"
    result=$(_lib_msg_tr_remove_whitespace "$input")
    assert_equal "$result" "$expected"
}

@test "_lib_msg_tr_remove_whitespace(): handles empty input" {
    result=$(_lib_msg_tr_remove_whitespace "")
    assert_equal "$result" ""
}

@test "_lib_msg_tr_remove_whitespace(): handles input with only whitespace" {
    input="  	
 "
    expected=""
    result=$(_lib_msg_tr_remove_whitespace "$input")
    assert_equal "$result" "$expected"
}

@test "_lib_msg_tr_remove_whitespace(): handles input with special characters" {
    input="  Special *chars* and \"quotes\" with \$variables and \\escapes\\  "
    expected="Special*chars*and\"quotes\"with\$variablesand\\escapes\\"
    result=$(_lib_msg_tr_remove_whitespace "$input")
    assert_equal "$result" "$expected"
}

@test "_lib_msg_tr_remove_whitespace(): handles fast path with no whitespace" {
    input="NoWhitespaceHere"
    result=$(_lib_msg_tr_remove_whitespace "$input")
    assert_equal "$result" "$input"
}

# --- Integration tests ---

@test "_lib_msg_wrap_text_sh(): uses _lib_msg_tr_newline_to_space() for newline conversion" {
    # Save original function
    eval "original_tr_func() { $(declare -f _lib_msg_tr_newline_to_space); }"

    # Create tracking function to verify it's called
    _lib_msg_tr_newline_to_space() {
        echo "TRACKER:$*"
    }

    # Call the function that should use our replacement
    result=$(_lib_msg_wrap_text_sh "Test input" 80)
    
    # Restore original function
    eval "_lib_msg_tr_newline_to_space() { $(declare -f original_tr_func); }"
    
    # Verify our tracking function was called
    assert_equal "$result" "TRACKER:Test input"
}

@test "_lib_msg_wrap_text(): handles whitespace-only input correctly" {
    # Direct test of the behavior with whitespace input
    # No need to track function calls, just verify end result
    result=$(_lib_msg_wrap_text "  " 80)
    
    # When input is only whitespace, the result should be empty
    assert_equal "$result" ""
}