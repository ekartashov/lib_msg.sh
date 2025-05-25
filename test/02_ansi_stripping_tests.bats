#!/usr/bin/env bats

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
    SCRIPT_NAME="test_ansi_script.sh"
    # simulate_tty_conditions in colorize tests will handle TTY state and library re-init.
}

teardown() {
    # Unstub 'test' if it was stubbed by any test directly or via helpers.
    # Generally, stubs used by helpers like simulate_tty_conditions are managed by the helper itself.
    # Individual tests using 'stub' should use 'unstub' directly.
    # Clean up env vars that might be set by tests
    unset LIB_MSG_FORCE_STDOUT_TTY LIB_MSG_FORCE_STDERR_TTY
}


# --- ANSI Stripping Tests ---

@test "_lib_msg_strip_ansi_shell(): strips simple ANSI escape sequences" {
    local input
    local expected
    local result

    # Simple red text
    input=$(printf '\033[31mRed Text\033[0m')
    expected="Red Text"
    result=$(_lib_msg_strip_ansi_shell "$input")
    assert_equal "$result" "$expected" "Failed to strip simple red ANSI sequence"

    # Bold blue text
    input=$(printf '\033[1;34mBold Blue\033[0m')
    expected="Bold Blue"
    result=$(_lib_msg_strip_ansi_shell "$input")
    assert_equal "$result" "$expected" "Failed to strip bold blue ANSI sequence"
}

@test "_lib_msg_strip_ansi_shell(): handles complex and multiple ANSI sequences" {
    local input
    local expected
    local result

    # Multiple formatting in one string
    input=$(printf '\033[1mBold\033[0m \033[31mRed\033[0m \033[1;32mBold Green\033[0m')
    expected="Bold Red Bold Green"
    result=$(_lib_msg_strip_ansi_shell "$input")
    assert_equal "$result" "$expected" "Failed to strip multiple ANSI sequences"

    # Text with cursor movement (still should be stripped)
    input=$(printf 'Start\033[3Dmiddle\033[4Cend')
    expected="Startmiddleend"
    result=$(_lib_msg_strip_ansi_shell "$input")
    assert_equal "$result" "$expected" "Failed to strip cursor movement sequences"
}

@test "_lib_msg_strip_ansi_shell(): handles edge cases" {
    local input
    local expected
    local result

    # Empty string
    input=""
    expected=""
    result=$(_lib_msg_strip_ansi_shell "$input")
    assert_equal "$result" "$expected" "Failed on empty string"

    # String with no ANSI sequences
    input="Plain text with no formatting"
    expected="Plain text with no formatting"
    result=$(_lib_msg_strip_ansi_shell "$input")
    assert_equal "$result" "$expected" "Modified text with no ANSI sequences"
    
    input="Plain text with no ANSI"
    expected="Plain text with no ANSI"
    result=$(_lib_msg_strip_ansi_shell "$input")
    assert_equal "$result" "$expected" "Should not modify text with no ANSI sequences"
}

@test "_lib_msg_strip_ansi_shell(): processes complex ANSI SGR sequences" {
    local input
    local expected
    local result

    # Multiple parameters
    input=$(printf '\033[38;5;196mCustom Red\033[0m')
    expected="Custom Red"
    result=$(_lib_msg_strip_ansi_shell "$input")
    assert_equal "$result" "$expected" "Failed to strip complex SGR sequence with multiple parameters"

    # Sequence with colon separator (used in some terminals)
    input=$(printf '\033[38:2:255:0:0mTrue Red\033[0m')
    expected="True Red"
    result=$(_lib_msg_strip_ansi_shell "$input")
    assert_equal "$result" "$expected" "Failed to strip SGR sequence with colon separators"

    # Unicode text with formatting
    input=$(printf '\033[1mÜñíçødê テキスト\033[0m')
    expected="Üñíçødê テキスト"
    result=$(_lib_msg_strip_ansi_shell "$input")
    assert_equal "$result" "$expected" "Failed with Unicode text"
}

# --- Colorize Tests ---

# --- Tests for _lib_msg_colorize (from lib_msg.bats) ---
@test "_lib_msg_colorize: no color if not TTY (simulated)" {
    # stdout not TTY (1), stderr not TTY (1)
    simulate_tty_conditions 1 1
    # simulate_tty_conditions ensures color vars are empty

    run _lib_msg_colorize "text" "$_LIB_MSG_CLR_RED" "$_LIB_MSG_STDOUT_IS_TTY"
    assert_success
    assert_output "text"
}

@test "_lib_msg_colorize: no color if color code is empty (simulated TTY)" {
    # stdout TTY (0), stderr not TTY (1)
    simulate_tty_conditions 0 1
    # Colors will be initialized by simulate_tty_conditions, but we pass an empty one to _lib_msg_colorize

    run _lib_msg_colorize "text" "" "$_LIB_MSG_STDOUT_IS_TTY"
    assert_success
    assert_output "text"
}

@test "_lib_msg_colorize: applies color if TTY and color code provided (simulated TTY)" {
    # stdout TTY (0), stderr not TTY (1)
    simulate_tty_conditions 0 1
    # This will populate _LIB_MSG_CLR_GREEN and _LIB_MSG_CLR_RESET via simulate_tty_conditions

    run _lib_msg_colorize "text" "$_LIB_MSG_CLR_GREEN" "$_LIB_MSG_STDOUT_IS_TTY"
    assert_success
    local expected_color_output
    printf -v expected_color_output "\033[0;32mtext\033[0m"
    assert_output "$expected_color_output"
}

# --- Test for _lib_msg_strip_ansi() implementation ---
@test "_lib_msg_strip_ansi(): Always uses optimized shell implementation" {
    # Force reinitialization
    unset -f _lib_msg_strip_ansi # Clear previous function
    
    # Load or source the library again
    source "$LIB_PATH/lib_msg.sh"
    
    # Verify _lib_msg_strip_ansi now calls _lib_msg_strip_ansi_shell
    run type _lib_msg_strip_ansi
    assert_output --partial "_lib_msg_strip_ansi_shell"
    
    # Verify the implementation is correct with a simple test
    local input
    local expected
    local result
    
    # Simple red text
    input=$(printf '\033[31mRed Text\033[0m')
    expected="Red Text"
    result=$(lib_msg_strip_ansi "$input")
    assert_equal "$result" "$expected" "Dispatcher should correctly strip ANSI sequences"
}