#!/usr/bin/env bats

# This file contains tests focused on TTY detection, color handling, and the 
# interaction between TTY state and formatting choices in lib_msg.sh

# Load BATS support and assertion libraries
load "libs/bats-support/load"
load "libs/bats-assert/load"
load "libs/bats-mock/stub.bash"

# Load our test helpers
load "helpers/lib_msg_test_helpers.bash"

# Load the library to be tested
# shellcheck source=../lib_msg.sh
load "../lib_msg.sh"

# Define paths for use in tests
LIB_PATH="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
TEST_PATH="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"

# --- TTY Detection and Environment Variable Override Tests ---

@test "_lib_msg_init_detection(): correctly detects TTY state through environment variables" {
    # Save original values
    local orig_stdout_is_tty="$_LIB_MSG_STDOUT_IS_TTY"
    local orig_stderr_is_tty="$_LIB_MSG_STDERR_IS_TTY"
    
    # Test overriding with LIB_MSG_FORCE_* environment variables
    export LIB_MSG_FORCE_STDOUT_TTY="true"
    export LIB_MSG_FORCE_STDERR_TTY="false"
    
    # Reset internal vars and re-run detection
    _LIB_MSG_STDOUT_IS_TTY=""
    _LIB_MSG_STDERR_IS_TTY=""
    _lib_msg_init_detection
    
    # Check detection results
    assert_equal "$_LIB_MSG_STDOUT_IS_TTY" "true" "stdout TTY state not detected correctly"
    assert_equal "$_LIB_MSG_STDERR_IS_TTY" "false" "stderr TTY state not detected correctly"
    
    # Reverse the settings
    export LIB_MSG_FORCE_STDOUT_TTY="false"
    export LIB_MSG_FORCE_STDERR_TTY="true"
    
    # Reset and re-detect
    _LIB_MSG_STDOUT_IS_TTY=""
    _LIB_MSG_STDERR_IS_TTY=""
    _lib_msg_init_detection
    
    # Check detection results again
    assert_equal "$_LIB_MSG_STDOUT_IS_TTY" "false" "stdout TTY state not detected correctly after change"
    assert_equal "$_LIB_MSG_STDERR_IS_TTY" "true" "stderr TTY state not detected correctly after change"
    
    # Restore original values
    _LIB_MSG_STDOUT_IS_TTY="$orig_stdout_is_tty"
    _LIB_MSG_STDERR_IS_TTY="$orig_stderr_is_tty"
    unset LIB_MSG_FORCE_STDOUT_TTY
    unset LIB_MSG_FORCE_STDERR_TTY
}

@test "_lib_msg_init_detection(): correctly falls back to test -t when environment variables not set" {
    # Save original values
    local orig_stdout_is_tty="$_LIB_MSG_STDOUT_IS_TTY"
    local orig_stderr_is_tty="$_LIB_MSG_STDERR_IS_TTY"
    local _LIB_MSG_TTY_TEST_MODE=0 # 0: default, 1: stdout=TTY/stderr=not, 2: stdout=not/stderr=TTY

    # Define a local 'test' function to override the builtin for this test case
    test() {
        echo "Local test() called with: [$*], _LIB_MSG_TTY_TEST_MODE=$_LIB_MSG_TTY_TEST_MODE" >&3
        if [ "$1" = "-t" ] && [ "$2" = "1" ]; then # Check for stdout TTY
            if [ "$_LIB_MSG_TTY_TEST_MODE" -eq 1 ]; then
                echo "Mocking 'test -t 1' to return 0 (true)" >&3
                return 0 # stdout is a TTY
            elif [ "$_LIB_MSG_TTY_TEST_MODE" -eq 2 ]; then
                echo "Mocking 'test -t 1' to return 1 (false)" >&3
                return 1 # stdout is NOT a TTY
            fi
        elif [ "$1" = "-t" ] && [ "$2" = "2" ]; then # Check for stderr TTY
            if [ "$_LIB_MSG_TTY_TEST_MODE" -eq 1 ]; then
                echo "Mocking 'test -t 2' to return 1 (false)" >&3
                return 1 # stderr is NOT a TTY
            elif [ "$_LIB_MSG_TTY_TEST_MODE" -eq 2 ]; then
                echo "Mocking 'test -t 2' to return 0 (true)" >&3
                return 0 # stderr is a TTY
            fi
        fi
        # Fallback to the original 'test' builtin if no specific mock matches
        echo "Local test() falling back to 'command test $*'" >&3
        command test "$@"
    }
    
    # Unset environment variables to force fallback to 'test -t'
    unset LIB_MSG_FORCE_STDOUT_TTY
    unset LIB_MSG_FORCE_STDERR_TTY
    
    # --- Scenario 1: stdout is TTY, stderr is NOT TTY ---
    _LIB_MSG_TTY_TEST_MODE=1
    _LIB_MSG_STDOUT_IS_TTY="" # Reset internal lib vars
    _LIB_MSG_STDERR_IS_TTY=""
    _lib_msg_init_detection
    
    assert_equal "$_LIB_MSG_STDOUT_IS_TTY" "true" "stdout TTY state not detected correctly (mode 1)"
    assert_equal "$_LIB_MSG_STDERR_IS_TTY" "false" "stderr TTY state not detected correctly (mode 1)"
    
    # --- Scenario 2: stdout is NOT TTY, stderr is TTY ---
    _LIB_MSG_TTY_TEST_MODE=2
    _LIB_MSG_STDOUT_IS_TTY="" # Reset internal lib vars
    _LIB_MSG_STDERR_IS_TTY=""
    _lib_msg_init_detection
    
    assert_equal "$_LIB_MSG_STDOUT_IS_TTY" "false" "stdout TTY state not detected correctly (mode 2)"
    assert_equal "$_LIB_MSG_STDERR_IS_TTY" "true" "stderr TTY state not detected correctly (mode 2)"
    
    # Clean up: remove the local 'test' function override
    unset -f test
    
    # Restore original library TTY states
    _LIB_MSG_STDOUT_IS_TTY="$orig_stdout_is_tty"
    _LIB_MSG_STDERR_IS_TTY="$orig_stderr_is_tty"
    # Re-run detection to restore to actual environment state if needed by other tests,
    # or rely on LIB_MSG_FORCE_ vars if they were set globally for testing.
    # For safety, let's re-init based on any global LIB_MSG_FORCE_ vars or actual TTYs.
    _lib_msg_init_detection
}

@test "_lib_msg_init_detection(): terminal width detection depends on COLUMNS environment variable" {
    # Save original values
    local orig_terminal_width="$_LIB_MSG_TERMINAL_WIDTH"
    local orig_columns="$COLUMNS"
    
    # Set both outputs to TTY
    export LIB_MSG_FORCE_STDOUT_TTY="true"
    export LIB_MSG_FORCE_STDERR_TTY="true"
    
    # Test with COLUMNS set to valid value
    export COLUMNS=120
    _LIB_MSG_TERMINAL_WIDTH=0
    _lib_msg_init_detection
    assert_equal "$_LIB_MSG_TERMINAL_WIDTH" 120 "Terminal width not set correctly from COLUMNS"
    
    # Test with COLUMNS set to 0 (should result in 0 width)
    export COLUMNS=0
    _LIB_MSG_TERMINAL_WIDTH=42 # Set to non-zero value to verify change
    _lib_msg_init_detection
    assert_equal "$_LIB_MSG_TERMINAL_WIDTH" 0 "Terminal width should be 0 when COLUMNS=0"
    
    # Test with COLUMNS having invalid value (should result in 0 width)
    export COLUMNS="not a number"
    _LIB_MSG_TERMINAL_WIDTH=42 # Reset to non-zero value
    _lib_msg_init_detection
    assert_equal "$_LIB_MSG_TERMINAL_WIDTH" 0 "Terminal width should be 0 when COLUMNS is invalid"
    
    # Test with COLUMNS unset (should result in 0 width)
    unset COLUMNS
    _LIB_MSG_TERMINAL_WIDTH=42 # Reset to non-zero value
    _lib_msg_init_detection
    assert_equal "$_LIB_MSG_TERMINAL_WIDTH" 0 "Terminal width should be 0 when COLUMNS is unset"
    
    # Test with both outputs not TTY (should result in 0 width regardless of COLUMNS)
    export LIB_MSG_FORCE_STDOUT_TTY="false"
    export LIB_MSG_FORCE_STDERR_TTY="false"
    export COLUMNS=120
    # Reset internal TTY flags before this specific check
    _LIB_MSG_STDOUT_IS_TTY=""
    _LIB_MSG_STDERR_IS_TTY=""
    _LIB_MSG_TERMINAL_WIDTH=0 # Also reset width, though init_detection should handle it
    _lib_msg_init_detection
    
    # The test should expect the actual behavior
    assert_equal "$_LIB_MSG_TERMINAL_WIDTH" 0 "Terminal width should be 0 when no TTYs detected"
    
    # Restore original values
    _LIB_MSG_TERMINAL_WIDTH="$orig_terminal_width"
    if [ -n "${orig_columns+x}" ]; then
        export COLUMNS="$orig_columns"
    else
        unset COLUMNS
    fi
    unset LIB_MSG_FORCE_STDOUT_TTY
    unset LIB_MSG_FORCE_STDERR_TTY
}

# --- Color Initialization Tests ---

@test "_lib_msg_init_colors(): initializes color variables when stdout is TTY" {
    # Set stdout to TTY
    export LIB_MSG_FORCE_STDOUT_TTY="true"
    export LIB_MSG_FORCE_STDERR_TTY="false"
    
    # Reset TTY detection first (which also calls _lib_msg_init_colors)
    _lib_msg_force_reinit
    
    # Check that color variables are set
    assert_equal "$_LIB_MSG_CLR_RED" "$(printf '\033[0;31m')" "Red color code not initialized"
    assert_equal "$_LIB_MSG_CLR_GREEN" "$(printf '\033[0;32m')" "Green color code not initialized"
    assert_equal "$_LIB_MSG_CLR_RESET" "$(printf '\033[0m')" "Reset color code not initialized"
    
    # Cleanup
    unset LIB_MSG_FORCE_STDOUT_TTY
    unset LIB_MSG_FORCE_STDERR_TTY
}

@test "_lib_msg_init_colors(): initializes color variables when stderr is TTY" {
    # Set stderr to TTY
    export LIB_MSG_FORCE_STDOUT_TTY="false"
    export LIB_MSG_FORCE_STDERR_TTY="true"
    
    # Reset TTY detection first (which also calls _lib_msg_init_colors)
    _lib_msg_force_reinit
    
    # Check that color variables are set
    assert_equal "$_LIB_MSG_CLR_RED" "$(printf '\033[0;31m')" "Red color code not initialized"
    assert_equal "$_LIB_MSG_CLR_GREEN" "$(printf '\033[0;32m')" "Green color code not initialized"
    assert_equal "$_LIB_MSG_CLR_RESET" "$(printf '\033[0m')" "Reset color code not initialized"
    
    # Cleanup
    unset LIB_MSG_FORCE_STDOUT_TTY
    unset LIB_MSG_FORCE_STDERR_TTY
}

@test "_lib_msg_init_colors(): does not initialize color variables when neither is TTY" {
    # Set both to not TTY
    export LIB_MSG_FORCE_STDOUT_TTY="false"
    export LIB_MSG_FORCE_STDERR_TTY="false"
    
    # Reset TTY detection first (which also calls _lib_msg_init_colors)
    _lib_msg_force_reinit
    
    # Check that color variables are not set
    assert_equal "$_LIB_MSG_CLR_RED" "" "Red color code should not be initialized"
    assert_equal "$_LIB_MSG_CLR_GREEN" "" "Green color code should not be initialized"
    assert_equal "$_LIB_MSG_CLR_RESET" "" "Reset color code should not be initialized"
    
    # Cleanup
    unset LIB_MSG_FORCE_STDOUT_TTY
    unset LIB_MSG_FORCE_STDERR_TTY
}

# --- Colorize Function Tests ---

@test "_lib_msg_colorize(): applies color when TTY is true and color code provided" {
    # Setup
    local text="Hello, colored world!"
    local color_code="$(printf '\033[0;34m')" # Blue
    local reset_code="$(printf '\033[0m')"
    local is_tty="true"
    
    # Execute and capture output
    run _lib_msg_colorize "$text" "$color_code" "$is_tty"
    
    # Expected: colored text with reset code
    local expected="${color_code}${text}${reset_code}"
    
    # Assert
    assert_equal "$output" "$expected" "Color was not applied correctly"
}

@test "_lib_msg_colorize(): does not apply color when TTY is false" {
    # Setup
    local text="Hello, plain world!"
    local color_code="$(printf '\033[0;34m')" # Blue
    local is_tty="false"
    
    # Execute and capture output
    run _lib_msg_colorize "$text" "$color_code" "$is_tty"
    
    # Expected: plain text without color
    local expected="$text"
    
    # Assert
    assert_equal "$output" "$expected" "Color should not be applied when TTY is false"
}

@test "_lib_msg_colorize(): does not apply color when color code is empty" {
    # Setup
    local text="Hello, no color defined!"
    local color_code=""
    local is_tty="true"
    
    # Execute and capture output
    run _lib_msg_colorize "$text" "$color_code" "$is_tty"
    
    # Expected: plain text without color
    local expected="$text"
    
    # Assert
    assert_equal "$output" "$expected" "Color should not be applied when color code is empty"
}

@test "_lib_msg_colorize(): does not apply color when reset code is empty" {
    # Set reset code to empty, save original
    local original_reset="$_LIB_MSG_CLR_RESET"
    _LIB_MSG_CLR_RESET=""
    
    # Setup
    local text="Hello, no reset code!"
    local color_code="$(printf '\033[0;34m')" # Blue
    local is_tty="true"
    
    # Execute and capture output
    run _lib_msg_colorize "$text" "$color_code" "$is_tty"
    
    # Expected: plain text without color since reset code is required
    local expected="$text"
    
    # Assert
    assert_equal "$output" "$expected" "Color should not be applied when reset code is empty"
    
    # Restore reset code
    _LIB_MSG_CLR_RESET="$original_reset"
}

# --- Tests for Public Functions with Color ---

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
    cat > "$BATS_TEST_TMPDIR/test_die.sh" << 'EOF'
#!/usr/bin/env bash
# Load the library
source "$1/lib_msg.sh"

# Set TTY conditions
export LIB_MSG_FORCE_STDOUT_TTY="false"
export LIB_MSG_FORCE_STDERR_TTY="true"

# Reinitialize with our settings
_lib_msg_force_reinit

# Set script name
SCRIPT_NAME="test_die.sh"

# Call die
die 42 "Fatal error with red prefix"
EOF
    chmod +x "$BATS_TEST_TMPDIR/test_die.sh"
    
    # Run the script
    run "$BATS_TEST_TMPDIR/test_die.sh" "$LIB_PATH" 1>/dev/null
    
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