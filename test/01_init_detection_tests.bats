#!/usr/bin/env bats

# Load BATS support and assertion libraries
load "libs/bats-support/load"
load "libs/bats-assert/load"
load "libs/bats-mock/stub.bash" # For simulate_tty_conditions from helpers

# Load our test helpers
load "test_helpers.bash"

# Load the library to be tested
# shellcheck source=../lib_msg.sh
load "../lib_msg.sh"

# Define paths for use in tests (optional, but good practice if needed later)
LIB_PATH="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
TEST_PATH="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"

setup() {
    # Mock SCRIPT_NAME for consistent prefix in tests, though not critical for these init tests
    SCRIPT_NAME="test_init.sh"
    # Any other common setup for these tests
    # Ensure COLUMNS is reset if tests modify it locally and don't clean up.
    # However, these specific tests manage COLUMNS via local or export.
}

teardown() {
    # Clean up any environment variables set by tests if necessary
    unset LIB_MSG_FORCE_STDOUT_TTY
    unset LIB_MSG_FORCE_STDERR_TTY
    # COLUMNS is tricky; setup_file in 00_setup_teardown_tests.bats sets it to 80.
    # Individual tests here might override it. Best to ensure tests are self-contained or restore.
}

# --- Tests for _lib_msg_init_detection() ---

# The following two tests are ported from the original .worktree/test/colors_and_tty_tests.bats
# They test the TTY detection mechanisms more granularly.

@test "_lib_msg_init_detection(): correctly detects TTY state through LIB_MSG_FORCE_* environment variables" {
    # Save original library state if they were set (e.g., by a global setup or previous test)
    local orig_stdout_is_tty_val="$_LIB_MSG_STDOUT_IS_TTY"
    local orig_stderr_is_tty_val="$_LIB_MSG_STDERR_IS_TTY"
    
    # Test overriding with LIB_MSG_FORCE_* environment variables
    export LIB_MSG_FORCE_STDOUT_TTY="true" # true for is a TTY
    export LIB_MSG_FORCE_STDERR_TTY="false" # false for is not a TTY
    
    # Reset internal vars and re-run detection
    # These are global vars within lib_msg.sh, so we clear them to ensure _lib_msg_init_detection re-evaluates.
    _LIB_MSG_STDOUT_IS_TTY=""
    _LIB_MSG_STDERR_IS_TTY=""
    _lib_msg_init_detection # This function will set the _LIB_MSG_STDOUT_IS_TTY and _LIB_MSG_STDERR_IS_TTY vars
    
    assert_equal "$_LIB_MSG_STDOUT_IS_TTY" "true" "stdout TTY state not detected correctly when forced true"
    assert_equal "$_LIB_MSG_STDERR_IS_TTY" "false" "stderr TTY state not detected correctly when forced false"
    
    # Reverse the settings
    export LIB_MSG_FORCE_STDOUT_TTY="false" # false for not a TTY
    export LIB_MSG_FORCE_STDERR_TTY="true" # true for is a TTY
    
    # Reset and re-detect
    _LIB_MSG_STDOUT_IS_TTY=""
    _LIB_MSG_STDERR_IS_TTY=""
    _lib_msg_init_detection
    
    assert_equal "$_LIB_MSG_STDOUT_IS_TTY" "false" "stdout TTY state not detected correctly when forced false"
    assert_equal "$_LIB_MSG_STDERR_IS_TTY" "true" "stderr TTY state not detected correctly when forced true"
    
    # Restore original library state by re-setting to saved values and then re-initializing
    # This is important if other tests rely on a specific initial state.
    # However, the teardown() for this file already unsets the FORCE vars.
    # And _lib_msg_init_detection will run based on actual TTY or remaining FORCE vars.
    # For robustness within the test, explicitly restore and re-init.
    _LIB_MSG_STDOUT_IS_TTY="$orig_stdout_is_tty_val"
    _LIB_MSG_STDERR_IS_TTY="$orig_stderr_is_tty_val"
    # Unset the force vars so the final _lib_msg_init_detection in teardown (if any) or next test works as expected
    unset LIB_MSG_FORCE_STDOUT_TTY
    unset LIB_MSG_FORCE_STDERR_TTY
    _lib_msg_init_detection # Re-initialize based on actual TTYs or other prevailing conditions
}

@test "_lib_msg_init_detection(): correctly falls back to 'test -t' when LIB_MSG_FORCE_* variables not set" {
    # Save original library state
    local orig_stdout_is_tty_val="$_LIB_MSG_STDOUT_IS_TTY"
    local orig_stderr_is_tty_val="$_LIB_MSG_STDERR_IS_TTY"
    
    # This variable will control the mock 'test' function's behavior
    local _MOCK_TEST_MODE=0 # 1: stdout=TTY/stderr=not, 2: stdout=not/stderr=TTY

    # Define a local 'test' function to override the builtin for this test case
    # This mock is specific to this @test block.
    test() {
        # echo "Mock test() called with: [$*], _MOCK_TEST_MODE=$_MOCK_TEST_MODE" >&3 # Debug
        if [ "$1" = "-t" ] && [ "$2" = "1" ]; then # Check for stdout TTY
            if [ "$_MOCK_TEST_MODE" -eq 1 ]; then
                # echo "Mocking 'test -t 1' to return 0 (true)" >&3 # Debug
                return 0 # stdout is a TTY
            elif [ "$_MOCK_TEST_MODE" -eq 2 ]; then
                # echo "Mocking 'test -t 1' to return 1 (false)" >&3 # Debug
                return 1 # stdout is NOT a TTY
            fi
        elif [ "$1" = "-t" ] && [ "$2" = "2" ]; then # Check for stderr TTY
            if [ "$_MOCK_TEST_MODE" -eq 1 ]; then
                # echo "Mocking 'test -t 2' to return 1 (false)" >&3 # Debug
                return 1 # stderr is NOT a TTY
            elif [ "$_MOCK_TEST_MODE" -eq 2 ]; then
                # echo "Mocking 'test -t 2' to return 0 (true)" >&3 # Debug
                return 0 # stderr is a TTY
            fi
        fi
        # Fallback to the original 'test' builtin if no specific mock matches
        # echo "Mock test() falling back to 'command test $*'" >&3 # Debug
        command test "$@"
    }
    
    # Ensure LIB_MSG_FORCE_* variables are unset to force fallback to 'test -t'
    unset LIB_MSG_FORCE_STDOUT_TTY
    unset LIB_MSG_FORCE_STDERR_TTY
    
    # --- Scenario 1: stdout is TTY, stderr is NOT TTY (mocked by test function) ---
    _MOCK_TEST_MODE=1
    _LIB_MSG_STDOUT_IS_TTY="" # Reset internal lib vars
    _LIB_MSG_STDERR_IS_TTY=""
    _lib_msg_init_detection
    
    assert_equal "$_LIB_MSG_STDOUT_IS_TTY" "true" "stdout TTY not detected correctly via 'test -t' (mock mode 1)"
    assert_equal "$_LIB_MSG_STDERR_IS_TTY" "false" "stderr TTY not detected correctly via 'test -t' (mock mode 1)"
    
    # --- Scenario 2: stdout is NOT TTY, stderr is TTY (mocked by test function) ---
    _MOCK_TEST_MODE=2
    _LIB_MSG_STDOUT_IS_TTY="" # Reset internal lib vars
    _LIB_MSG_STDERR_IS_TTY=""
    _lib_msg_init_detection
    
    assert_equal "$_LIB_MSG_STDOUT_IS_TTY" "false" "stdout TTY not detected correctly via 'test -t' (mock mode 2)"
    assert_equal "$_LIB_MSG_STDERR_IS_TTY" "true" "stderr TTY not detected correctly via 'test -t' (mock mode 2)"
    
    # Clean up: remove the local 'test' function override
    unset -f test
    
    # Restore original library TTY states and re-initialize
    _LIB_MSG_STDOUT_IS_TTY="$orig_stdout_is_tty_val"
    _LIB_MSG_STDERR_IS_TTY="$orig_stderr_is_tty_val"
    _lib_msg_init_detection # Re-initialize to actual environment state
}

# These existing tests verify the outcome of _lib_msg_init_detection based on various COLUMNS values
# and TTY states (which are themselves forced by LIB_MSG_FORCE_* vars for these specific tests).
@test "_lib_msg_init_detection(): detects no TTYs and COLUMNS=60" {
    # Use environment variables to simulate TTY detection
    export LIB_MSG_FORCE_STDOUT_TTY="false" # Both false
    export LIB_MSG_FORCE_STDERR_TTY="false"
    
    # Set COLUMNS and call detection
    COLUMNS=60 # Explicitly set for this test
    _LIB_MSG_STDOUT_IS_TTY="" # Manually clear before direct call
    _LIB_MSG_STDERR_IS_TTY="" # Manually clear before direct call
    _lib_msg_init_detection

    assert_equal "$_LIB_MSG_STDOUT_IS_TTY" "false" "stdout TTY flag"
    assert_equal "$_LIB_MSG_STDERR_IS_TTY" "false" "stderr TTY flag"
    assert_equal "$_LIB_MSG_TERMINAL_WIDTH" 0 "Terminal width should be 0 when no TTY"
    # Stubs consumed by _lib_msg_init_detection (if any were used, not in this direct call version)
}

@test "_lib_msg_init_detection(): detects stdout TTY, stderr not TTY, COLUMNS=120" {
    # Use environment variables to simulate TTY detection
    export LIB_MSG_FORCE_STDOUT_TTY="true" # stdout true, stderr false
    export LIB_MSG_FORCE_STDERR_TTY="false"

    COLUMNS=120 # Explicitly set
    _LIB_MSG_STDOUT_IS_TTY="" # Manually clear
    _LIB_MSG_STDERR_IS_TTY="" # Manually clear
    _lib_msg_init_detection

    assert_equal "$_LIB_MSG_STDOUT_IS_TTY" "true" "stdout TTY flag"
    assert_equal "$_LIB_MSG_STDERR_IS_TTY" "false" "stderr TTY flag"
    assert_equal "$_LIB_MSG_TERMINAL_WIDTH" 120 "Terminal width"
}

@test "_lib_msg_init_detection(): detects stdout not TTY, stderr TTY, COLUMNS undefined" {
    # Use environment variables to simulate TTY detection
    export LIB_MSG_FORCE_STDOUT_TTY="false" # stdout false, stderr true
    export LIB_MSG_FORCE_STDERR_TTY="true"

    local original_cols_val # To store and restore COLUMNS if it was set
    [ -n "${COLUMNS+x}" ] && original_cols_val="$COLUMNS"
    unset COLUMNS # Ensure COLUMNS is not set for this specific test
    
    _LIB_MSG_STDOUT_IS_TTY="" # Manually clear
    _LIB_MSG_STDERR_IS_TTY="" # Manually clear
    _lib_msg_init_detection

    assert_equal "$_LIB_MSG_STDOUT_IS_TTY" "false" "stdout TTY flag"
    assert_equal "$_LIB_MSG_STDERR_IS_TTY" "true" "stderr TTY flag"
    assert_equal "$_LIB_MSG_TERMINAL_WIDTH" 0 "Terminal width should be 0 when COLUMNS undefined"
    
    # Restore COLUMNS
    [ -n "${original_cols_val+x}" ] && export COLUMNS="$original_cols_val" || unset COLUMNS
}

@test "_lib_msg_init_detection(): detects both TTYs, COLUMNS=80 (default)" {
    # Use environment variables to simulate TTY detection
    export LIB_MSG_FORCE_STDOUT_TTY="true" # Both true
    export LIB_MSG_FORCE_STDERR_TTY="true"

    COLUMNS=80 # Explicitly set to default for clarity
    _LIB_MSG_STDOUT_IS_TTY="" # Manually clear
    _LIB_MSG_STDERR_IS_TTY="" # Manually clear
    _lib_msg_init_detection

    assert_equal "$_LIB_MSG_STDOUT_IS_TTY" "true" "stdout TTY flag"
    assert_equal "$_LIB_MSG_STDERR_IS_TTY" "true" "stderr TTY flag"
    assert_equal "$_LIB_MSG_TERMINAL_WIDTH" 80 "Terminal width"
}

@test "_lib_msg_init_detection(): detects both TTYs, COLUMNS invalid" {
    # Use environment variables to simulate TTY detection
    export LIB_MSG_FORCE_STDOUT_TTY="true" # Both true
    export LIB_MSG_FORCE_STDERR_TTY="true"

    COLUMNS="abc" # Invalid value
    _LIB_MSG_STDOUT_IS_TTY="" # Manually clear
    _LIB_MSG_STDERR_IS_TTY="" # Manually clear
    _lib_msg_init_detection

    assert_equal "$_LIB_MSG_STDOUT_IS_TTY" "true" "stdout TTY flag"
    assert_equal "$_LIB_MSG_STDERR_IS_TTY" "true" "stderr TTY flag"
    assert_equal "$_LIB_MSG_TERMINAL_WIDTH" 0 "Terminal width should be 0 for invalid COLUMNS"
}

# --- Tests for _lib_msg_init_colors() ---

@test "_lib_msg_init_colors(): enables colors if stdout is TTY (simulated)" {
    # stdout TTY (0), stderr not TTY (1)
    simulate_tty_conditions 0 1
    # simulate_tty_conditions already calls _lib_msg_init_detection and _lib_msg_init_colors

    assert_equal "$_LIB_MSG_CLR_RED" "$(printf '\033[0;31m')" "Red color code"
    assert_equal "$_LIB_MSG_CLR_RESET" "$(printf '\033[0m')" "Reset color code"
    # simulate_tty_conditions stubs are one-shot and handled by helper
}

@test "_lib_msg_init_colors(): enables colors if stderr is TTY (simulated)" {
    # stdout not TTY (1), stderr TTY (0)
    simulate_tty_conditions 1 0

    assert_equal "$_LIB_MSG_CLR_YELLOW" "$(printf '\033[0;33m')" "Yellow color code"
    assert_equal "$_LIB_MSG_CLR_RESET" "$(printf '\033[0m')" "Reset color code"
}

@test "_lib_msg_init_colors(): disables colors if no TTY (simulated)" {
    # No TTYs: stdout not TTY (1), stderr not TTY (1)
    simulate_tty_conditions 1 1
    
    assert_equal "$_LIB_MSG_CLR_GREEN" "" "Green color code should be empty"
    assert_equal "$_LIB_MSG_CLR_RESET" "" "Reset color code should be empty"
}