#!/usr/bin/env bats
# Tests for tr command alternatives in lib_msg.sh

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

# --- Tests for _lib_msg_tr_newline_to_space_shell() ---

@test "_lib_msg_tr_newline_to_space_shell(): converts newlines to spaces" {
    input="Line1
Line2
Line3"
    expected="Line1 Line2 Line3"
    result=$(_lib_msg_tr_newline_to_space_shell "$input")
    assert_equal "$result" "$expected"
}

@test "_lib_msg_tr_newline_to_space_shell(): handles empty input" {
    result=$(_lib_msg_tr_newline_to_space_shell "")
    assert_equal "$result" ""
}

@test "_lib_msg_tr_newline_to_space_shell(): handles input with only newlines" {
    input="

"
    expected="  "
    result=$(_lib_msg_tr_newline_to_space_shell "$input")
    assert_equal "$result" "$expected"
}

@test "_lib_msg_tr_newline_to_space_shell(): handles mixed content with special characters" {
    input="Line1 with *special* chars!
Line2 with \"quotes\" and $variables
Line3 with \\escapes\\"
    expected="Line1 with *special* chars! Line2 with \"quotes\" and $variables Line3 with \\escapes\\"
    result=$(_lib_msg_tr_newline_to_space_shell "$input")
    assert_equal "$result" "$expected"
}

# --- Tests for _lib_msg_tr_remove_whitespace_shell() ---

@test "_lib_msg_tr_remove_whitespace_shell(): removes all whitespace" {
    input="  This has spaces tabs	and
newlines  "
    expected="Thishasspacestabsandnewlines"
    result=$(_lib_msg_tr_remove_whitespace_shell "$input")
    assert_equal "$result" "$expected"
}

@test "_lib_msg_tr_remove_whitespace_shell(): handles empty input" {
    result=$(_lib_msg_tr_remove_whitespace_shell "")
    assert_equal "$result" ""
}

@test "_lib_msg_tr_remove_whitespace_shell(): handles input with only whitespace" {
    input="  	
 "
    expected=""
    result=$(_lib_msg_tr_remove_whitespace_shell "$input")
    assert_equal "$result" "$expected"
}

@test "_lib_msg_tr_remove_whitespace_shell(): handles input with special characters" {
    input="  Special *chars* and \"quotes\" with \$variables and \\escapes\\  "
    expected="Special*chars*and\"quotes\"with\$variablesand\\escapes\\"
    result=$(_lib_msg_tr_remove_whitespace_shell "$input")
    assert_equal "$result" "$expected"
}

# --- Tests for _lib_msg_tr_newline_to_space() ---

@test "_lib_msg_tr_newline_to_space(): uses tr when available" {
    # Create stub for tr command that adds a marker to verify it was called
    function tr() {
        echo "TR_CALLED:$*"
    }
    export -f tr

    # Mock _lib_msg_has_command to return true for tr
    function _lib_msg_has_command() {
        if [ "$1" = "tr" ]; then
            return 0
        fi
        return 1
    }
    export -f _lib_msg_has_command

    # Verify tr is called
    result=$(_lib_msg_tr_newline_to_space "test")
    assert_equal "$result" "TR_CALLED:\\n  "
}

@test "_lib_msg_tr_newline_to_space(): falls back to shell implementation when tr unavailable" {
    # Mock _lib_msg_has_command to return false for tr
    function _lib_msg_has_command() {
        if [ "$1" = "tr" ]; then
            return 1
        fi
        return 0
    }
    export -f _lib_msg_has_command

    # Create test function that will verify the shell implementation is called
    function _lib_msg_tr_newline_to_space_shell() {
        echo "SHELL_IMPL_CALLED:$*"
    }
    export -f _lib_msg_tr_newline_to_space_shell

    # Verify shell implementation is called
    result=$(_lib_msg_tr_newline_to_space "test")
    assert_equal "$result" "SHELL_IMPL_CALLED:test"
}

# --- Tests for _lib_msg_tr_remove_whitespace() ---

@test "_lib_msg_tr_remove_whitespace(): uses tr when available" {
    # Create stub for tr command that adds a marker to verify it was called
    function tr() {
        echo "TR_CALLED:$*"
    }
    export -f tr

    # Mock _lib_msg_has_command to return true for tr
    function _lib_msg_has_command() {
        if [ "$1" = "tr" ]; then
            return 0
        fi
        return 1
    }
    export -f _lib_msg_has_command

    # Verify tr is called
    result=$(_lib_msg_tr_remove_whitespace "test")
    assert_equal "$result" "TR_CALLED:-d [:space:]"
}

@test "_lib_msg_tr_remove_whitespace(): falls back to shell implementation when tr unavailable" {
    # Mock _lib_msg_has_command to return false for tr
    function _lib_msg_has_command() {
        if [ "$1" = "tr" ]; then
            return 1
        fi
        return 0
    }
    export -f _lib_msg_has_command

    # Create test function that will verify the shell implementation is called
    function _lib_msg_tr_remove_whitespace_shell() {
        echo "SHELL_IMPL_CALLED:$*"
    }
    export -f _lib_msg_tr_remove_whitespace_shell

    # Verify shell implementation is called
    result=$(_lib_msg_tr_remove_whitespace "test")
    assert_equal "$result" "SHELL_IMPL_CALLED:test"
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