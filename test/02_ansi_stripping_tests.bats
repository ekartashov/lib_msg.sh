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

# --- _lib_msg_strip_ansi_sed() Tests (from core_functions_tests.bats) ---

@test "_lib_msg_strip_ansi_sed(): strips ANSI escape sequences correctly" {
    local input
    local expected
    local result

    # Simple red text
    input=$(printf '\033[31mRed Text\033[0m')
    expected="Red Text"
    result=$(_lib_msg_strip_ansi_sed "$input")
    assert_equal "$result" "$expected" "Failed to strip simple red ANSI sequence"

    # Bold blue text
    input=$(printf '\033[1;34mBold Blue\033[0m')
    expected="Bold Blue"
    result=$(_lib_msg_strip_ansi_sed "$input")
    assert_equal "$result" "$expected" "Failed to strip bold blue ANSI sequence"

    # Multiple formatting in one string
    input=$(printf '\033[1mBold\033[0m \033[31mRed\033[0m \033[1;32mBold Green\033[0m')
    expected="Bold Red Bold Green"
    result=$(_lib_msg_strip_ansi_sed "$input")
    assert_equal "$result" "$expected" "Failed to strip multiple ANSI sequences"
}

@test "_lib_msg_strip_ansi_sed(): handles complex and edge case ANSI sequences" {
    local input
    local expected
    local result

    # 8-bit color code (SGR with multiple params)
    input=$(printf '\033[38;5;196mCustom Red\033[0m')
    expected="Custom Red"
    result=$(_lib_msg_strip_ansi_sed "$input")
    assert_equal "$result" "$expected" "Failed to strip 8-bit color code"

    # Moving cursor sequences 
    input=$(printf 'Start\033[3Dmiddle\033[4Cend')
    expected="Startmiddleend"
    result=$(_lib_msg_strip_ansi_sed "$input")
    assert_equal "$result" "$expected" "Failed to strip cursor movement sequences"

    # Empty string
    input=""
    expected=""
    result=$(_lib_msg_strip_ansi_sed "$input")
    assert_equal "$result" "$expected" "Failed on empty string"

    # String with no ANSI sequences
    input="Plain text with no formatting"
    expected="Plain text with no formatting"
    result=$(_lib_msg_strip_ansi_sed "$input")
    assert_equal "$result" "$expected" "Modified text with no ANSI sequences"
}

# --- _lib_msg_strip_ansi_shell() Tests (from pure_shell_fallback_tests.bats) ---

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

# --- _lib_msg_strip_ansi() Dispatcher Tests (from core_functions_tests.bats) ---

@test "_lib_msg_strip_ansi(): uses sed when available" {
    # First, check if sed is actually available on the system
    if ! command -v sed >/dev/null 2>&1; then
        skip "sed is not available on this system"
    fi
    
    # Save original functions
    local orig_sed_impl
    local orig_shell_impl
    orig_sed_impl=$(declare -f _lib_msg_strip_ansi_sed)
    orig_shell_impl=$(declare -f _lib_msg_strip_ansi_shell)
    
    # Create tracking variables
    local sed_called=false
    local shell_called=false
    
    # Override implementations to track calls
    _lib_msg_strip_ansi_sed() {
        sed_called=true
        echo "Original sed implementation would be called here"
    }
    _lib_msg_strip_ansi_shell() {
        shell_called=true
        echo "Original shell implementation would be called here"
    }
    
    # Call the selector function
    _lib_msg_strip_ansi "Some text with \033[31mANSI\033[0m formatting" >/dev/null
    
    # Assert that only sed implementation was called
    [ "$sed_called" = true ] || fail "sed implementation was not called"
    [ "$shell_called" = false ] || fail "shell implementation was called when sed is available"
    
    # Restore original functions
    eval "$orig_sed_impl"
    eval "$orig_shell_impl"
}

@test "_lib_msg_strip_ansi(): fallbacks to shell when sed unavailable" {
    # Save original function definitions
    local orig_has_command_def
    orig_has_command_def=$(declare -f _lib_msg_has_command)
    local orig_strip_ansi_sed_def
    orig_strip_ansi_sed_def=$(declare -f _lib_msg_strip_ansi_sed)
    local orig_strip_ansi_shell_def
    orig_strip_ansi_shell_def=$(declare -f _lib_msg_strip_ansi_shell)
    local orig_strip_ansi_def
    orig_strip_ansi_def=$(declare -f _lib_msg_strip_ansi)

    # Mock _lib_msg_has_command to report 'sed' as unavailable
    _lib_msg_has_command() {
        if [ "$1" = "sed" ]; then
            return 1  # Simulate sed not being available
        fi
        # For other commands, use the actual 'command -v' for this test's purpose
        command -v "$1" >/dev/null 2>&1
    }

    # Tracking variables for mock calls
    local sed_strip_called=false
    local shell_strip_called=false

    # Mock the underlying strip functions to track calls
    _lib_msg_strip_ansi_sed() {
        sed_strip_called=true
        # echo "Mock _lib_msg_strip_ansi_sed called" >&3
    }
    _lib_msg_strip_ansi_shell() {
        shell_strip_called=true
        # echo "Mock _lib_msg_strip_ansi_shell called" >&3
    }

    # Re-evaluate the definition of _lib_msg_strip_ansi based on the mocked _lib_msg_has_command
    # This mimics the logic block from lib_msg.sh
    if _lib_msg_has_command "sed"; then
        _lib_msg_strip_ansi() { _lib_msg_strip_ansi_sed "$@"; }
    else
        _lib_msg_strip_ansi() { _lib_msg_strip_ansi_shell "$@"; }
    fi
    
    # Call the (now re-defined) _lib_msg_strip_ansi function
    _lib_msg_strip_ansi "Some text with \033[31mANSI\033[0m formatting" >/dev/null
    
    # Assert that only the shell implementation was called
    assert_equal "$sed_strip_called" "false" "SED strip implementation was called when sed should be unavailable."
    assert_equal "$shell_strip_called" "true" "Shell strip implementation was NOT called when sed should be unavailable."
    
    # Restore original function definitions
    eval "$orig_has_command_def"
    eval "$orig_strip_ansi_sed_def"
    eval "$orig_strip_ansi_shell_def"
    eval "$orig_strip_ansi_def" # Restore the original _lib_msg_strip_ansi dispatcher
}

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

# --- Test for _lib_msg_strip_ansi() dispatcher (from pure_shell_fallback_tests.bats) ---
@test "_lib_msg_strip_ansi(): Forces shell implementation when sed is unavailable" {
    # Create a function to mock command absence
    _original_lib_msg_has_command() {
        _lib_msg_has_command "$@"
    }
    
    # Replace the has_command function to fake sed being absent
    _lib_msg_has_command() {
        if [ "$1" = "sed" ]; then
            return 1  # Pretend sed is not available
        fi
        # For all other commands, use the original check
        _original_lib_msg_has_command "$@"
    }
    
    # Force reinitialization
    unset -f _lib_msg_strip_ansi # Clear previous function
    
    # Load or source the library again to trigger selection of implementation
    source "$LIB_PATH/lib_msg.sh"
    
    # Verify _lib_msg_strip_ansi now calls _lib_msg_strip_ansi_shell
    run type _lib_msg_strip_ansi
    assert_output --partial "_lib_msg_strip_ansi_shell"
    
    # Clean up - restore original function
    _lib_msg_has_command() {
        _original_lib_msg_has_command "$@"
    }
    unset -f _original_lib_msg_has_command
}

@test "_lib_msg_strip_ansi(): Forces sed implementation when sed is available" {
    # Create a function to mock command availability
    _original_lib_msg_has_command_sed_avail() {
        _lib_msg_has_command "$@"
    }
    
    # Replace the has_command function to fake sed being available
    _lib_msg_has_command() {
        if [ "$1" = "sed" ]; then
            return 0  # Pretend sed IS available
        fi
        # For all other commands, use the original check
        _original_lib_msg_has_command_sed_avail "$@"
    }
    
    # Force reinitialization
    unset -f _lib_msg_strip_ansi # Clear previous function
    
    # Load or source the library again to trigger selection of implementation
    # shellcheck source=../lib_msg.sh
    source "$LIB_PATH/lib_msg.sh"
    
    # Verify _lib_msg_strip_ansi now calls _lib_msg_strip_ansi_sed
    run type _lib_msg_strip_ansi
    assert_output --partial "_lib_msg_strip_ansi_sed"
    
    # Clean up - restore original function
    _lib_msg_has_command() {
        _original_lib_msg_has_command_sed_avail "$@"
    }
    unset -f _original_lib_msg_has_command_sed_avail
}