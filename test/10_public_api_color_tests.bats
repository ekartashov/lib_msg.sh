#!/usr/bin/env bats

# This file contains tests for the public API functions of lib_msg.sh,
# focusing on their colorization behavior based on TTY status and
# correct handling of Unicode characters with colors.

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
}

teardown() {
    # No specific teardown needed for these color tests beyond what simulate_tty_conditions handles.
    # Ensure lib_msg is in a known state if TTY settings were manipulated directly.
    _lib_msg_force_reinit
}

# --- Tests for Public Functions with Color ---
# Originally from test/colors_and_tty_tests.bats

@test "info() correctly applies blue color for 'I:' prefix when stdout is TTY" {
    # Set stdout to TTY, stderr to not TTY
    simulate_tty_conditions 0 1
    
    # Set script name
    SCRIPT_NAME="test_color.sh"
    
    # Execute
    run info "This is blue info" 2>/dev/null
    
    # Expected: output should contain blue color code
    [[ "$output" == *"$(printf '\033[0;34m')I: "* ]] || fail "Blue color code not found in info output"
    [[ "$output" == *"$(printf '\033[0m')"* ]] || fail "Reset color code not found in info output"
    
    # Check the content is present
    [[ "$output" == *"This is blue info"* ]] || fail "Message content not found in output"
}

@test "err() correctly applies red color for 'E:' prefix when stderr is TTY" {
    # Set stdout to not TTY, stderr to TTY
    simulate_tty_conditions 1 0
    
    # Set script name
    SCRIPT_NAME="test_color.sh"
    
    # Execute - note we're capturing stderr output
    run err "This is red error" 1>/dev/null
    
    # Expected: output should contain red color code
    [[ "$output" == *"$(printf '\033[0;31m')E: "* ]] || fail "Red color code not found in err output"
    [[ "$output" == *"$(printf '\033[0m')"* ]] || fail "Reset color code not found in err output"
    
    # Check the content is present
    [[ "$output" == *"This is red error"* ]] || fail "Message content not found in output"
}

@test "warn() correctly applies yellow color for 'W:' prefix when stderr is TTY" {
    # Set stdout to not TTY, stderr to TTY
    simulate_tty_conditions 1 0
    
    # Set script name
    SCRIPT_NAME="test_color.sh"
    
    # Execute - note we're capturing stderr output
    run warn "This is yellow warning" 1>/dev/null
    
    # Expected: output should contain yellow color code
    [[ "$output" == *"$(printf '\033[0;33m')W: "* ]] || fail "Yellow color code not found in warn output"
    [[ "$output" == *"$(printf '\033[0m')"* ]] || fail "Reset color code not found in warn output"
    
    # Check the content is present
    [[ "$output" == *"This is yellow warning"* ]] || fail "Message content not found in output"
}

@test "msg() does not apply color since it doesn't use any colors by default" {
    # Set stdout to TTY, stderr to not TTY
    simulate_tty_conditions 0 1
    
    # Set script name
    SCRIPT_NAME="test_color.sh"
    
    # Execute
    run msg "This is a plain message" 2>/dev/null
    
    # Expected: output should not contain any ANSI color codes
    [[ "$output" != *"$(printf '\033[')"* ]] || fail "Color code found in msg output when none should be used"
    
    # Check the content is present
    [[ "$output" == *"test_color.sh: This is a plain message"* ]] || fail "Message content not found in output"
}

@test "die() correctly applies red color for 'E:' prefix when stderr is TTY" {
    # Create a script to test die() with TTY
    cat > "$BATS_TEST_TMPDIR/test_die_color.sh" << EOF
#!/usr/bin/env bash
# Script expects: $1 = LIB_PATH, $2 = TEST_PATH

echo "TMP SCRIPT DEBUG: Received \$# arguments." >&2
echo "TMP SCRIPT DEBUG: \$0 (script name): '\$0'" >&2
echo "TMP SCRIPT DEBUG: \$1 (LIB_PATH candidate): '\$1'" >&2
echo "TMP SCRIPT DEBUG: \$2 (TEST_PATH candidate): '\$2'" >&2
echo "TMP SCRIPT DEBUG: \$3 (unused in this script): '\$3'" >&2

# Source lib_msg.sh first, then test_helpers.bash
if [ -z "\$1" ]; then
    echo "TMP SCRIPT ERROR: Argument \$1 (LIB_PATH) is empty!" >&2
    exit 128
fi
if [ ! -f "\$1/lib_msg.sh" ]; then
    echo "TMP SCRIPT ERROR: lib_msg.sh not found at \"\$1/lib_msg.sh\". Value of \$1 was: '\$1'" >&2
    exit 129
fi
source "\$1/lib_msg.sh"
echo "TMP SCRIPT DEBUG: Sourced lib_msg.sh from \$1" >&2

if [ -z "\$2" ]; then
    echo "TMP SCRIPT ERROR: Argument \$2 (TEST_PATH) is empty!" >&2
    exit 127
fi

if [ -f "\$2/test_helpers.bash" ]; then
    # shellcheck source=../test_helpers.bash
    source "\$2/test_helpers.bash"
    echo "TMP SCRIPT DEBUG: Sourced test_helpers.bash from \$2" >&2
else
    echo "Error: test_helpers.bash not found at \"\$2/test_helpers.bash\". Value of \$2 was: '\$2'" >&2
    exit 125
fi

# lib_msg.sh should now be sourced directly above.
# test_helpers.bash also sources lib_msg.sh; this double sourcing should be harmless
# if lib_msg.sh is idempotent (it is for function definitions).
# if [ -f "\$1/lib_msg.sh" ]; then
#     # shellcheck source=../../lib_msg.sh
#     source "$1/lib_msg.sh"
# else
#     echo "Error: lib_msg.sh not found at $1/lib_msg.sh" >&2
#     exit 126
# fi

# Set TTY conditions (0 for TTY, 1 for non-TTY)
export LIB_MSG_FORCE_STDOUT_TTY="1" # stdout is not TTY
export LIB_MSG_FORCE_STDERR_TTY="0" # stderr is TTY

# Reinitialize with our settings
_lib_msg_force_reinit

# Set script name
SCRIPT_NAME="test_die.sh"

# Call die
die 42 "Fatal error with red prefix"
EOF
    chmod +x "$BATS_TEST_TMPDIR/test_die_color.sh"
    
    # Debugging paths before run
    echo "BATS DEBUG (die test): TEST_PATH before run: '$TEST_PATH'" >&2
    echo "BATS DEBUG (die test): LIB_PATH before run: '$LIB_PATH'" >&2
    if [ -z "$TEST_PATH" ]; then
        echo "BATS ERROR (die test): TEST_PATH is empty or unset before run command!" >&2
    fi
    if [ -z "$LIB_PATH" ]; then
        echo "BATS ERROR (die test): LIB_PATH is empty or unset before run command!" >&2
    fi

    # Run the script
    run "$BATS_TEST_TMPDIR/test_die_color.sh" "$LIB_PATH" "$TEST_PATH" 1>/dev/null
    
    # Expected: exit code 42 and red prefix
    assert_failure 42
    [[ "$output" == *"$(printf '\033[0;31m')E: "* ]] || fail "Red color code not found in die output"
    [[ "$output" == *"$(printf '\033[0m')"* ]] || fail "Reset color code not found in die output"
    [[ "$output" == *"Fatal error with red prefix"* ]] || fail "Message content not found in output"
}

@test "public functions don't use color when TTY is false" {
    # Set both stdout and stderr to not TTY
    simulate_tty_conditions 1 1
    
    # Set script name
    SCRIPT_NAME="test_no_color.sh"
    
    # Test each function
    run info "Info without color" 2>/dev/null
    [[ "$output" != *"$(printf '\033[')"* ]] || fail "info() used color when TTY is false"
    [[ "$output" == *"test_no_color.sh: I: Info without color"* ]] || fail "Info message content incorrect"
    
    run err "Error without color" 1>/dev/null
    [[ "$output" != *"$(printf '\033[')"* ]] || fail "err() used color when TTY is false"
    [[ "$output" == *"test_no_color.sh: E: Error without color"* ]] || fail "Error message content incorrect"
    
    run warn "Warning without color" 1>/dev/null
    [[ "$output" != *"$(printf '\033[')"* ]] || fail "warn() used color when TTY is false"
    [[ "$output" == *"test_no_color.sh: W: Warning without color"* ]] || fail "Warning message content incorrect"
}

# --- Color functions with Unicode Text ---
# Originally from test/colors_and_tty_tests.bats

@test "Color functions work correctly with Unicode text" {
    # Set both stdout and stderr to TTY
    simulate_tty_conditions 0 0
    
    # Set script name
    SCRIPT_NAME="unicode_test.sh"
    
    # Test with Unicode text
    run info "Unicode text: こんにちは 你好 Привет" 2>/dev/null
    [[ "$output" == *"こんにちは 你好 Привет"* ]] || fail "Unicode text not preserved in info() output"
    
    run err "Unicode error: ошибка 错误 エラー" 1>/dev/null
    [[ "$output" == *"ошибка 错误 エラー"* ]] || fail "Unicode text not preserved in err() output"
}