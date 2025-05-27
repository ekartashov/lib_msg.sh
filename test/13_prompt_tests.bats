#!/usr/bin/env bats

# Test suite for lib_msg.sh prompt functions
# This file tests lib_msg_prompt() and lib_msg_prompt_yn() functions

# Load BATS support and assertion libraries
load "libs/bats-support/load"
load "libs/bats-assert/load"

# Load our test helpers
load "test_helpers.bash"

setup() {
    # Source the library
    source "$BATS_TEST_DIRNAME/../lib_msg.sh"
    
    # Ensure clean environment
    unset LIB_MSG_FORCE_STDOUT_TTY LIB_MSG_FORCE_STDERR_TTY
    unset SCRIPT_NAME
    
    # Force reinitialization to ensure clean state
    _lib_msg_force_reinit
    
    # Set script name for consistent output
    SCRIPT_NAME="test_script.sh"
}

teardown() {
    # Clean up any temporary files
    rm -f "$BATS_TMPDIR"/test_input_* 2>/dev/null || true
    
    # Reset environment
    unset LIB_MSG_FORCE_STDOUT_TTY LIB_MSG_FORCE_STDERR_TTY
    unset SCRIPT_NAME
    _lib_msg_force_reinit
}

# Helper function to test prompt functions with simulated input
# This approach uses a subshell with exec redirection to separate prompt display from return value
test_prompt_with_input() {
    local input="$1"
    shift
    
    # Use a more sophisticated approach to separate prompt output from return value
    # We'll capture the function output and extract only the last line (the return value)
    local temp_file=$(mktemp)
    local result
    local exit_code
    
    # Run the function with input, capture all output and exit code
    # Store exit code in a separate variable to handle early validation failures
    {
        printf "%s\n" "$input" | "$@"
        echo $? > "${temp_file}.exit"
    } > "$temp_file" 2>/dev/null
    exit_code=$(cat "${temp_file}.exit" 2>/dev/null || echo "0")
    
    # The return value should be the last line that doesn't contain ': ' (prompt indicator)
    # For lib_msg_prompt, the output is: "prompt_text: return_value"
    # For lib_msg_prompt_yn, the output is: "test_script.sh: Q: prompt_text [Y/n]: return_value"
    # Handle both formats: extract after ]: (for yn) or after final : (for regular prompt)
    result=$(tail -n 1 "$temp_file" | sed 's/.*]: *//; t; s/.*: *//')
    
    # Clean up and return result
    rm -f "$temp_file" "${temp_file}.exit"
    
    # If this helper is being called with 'run', we need to exit with the proper code
    # Otherwise just return the result
    if [ -n "${BATS_TEST_NAME:-}" ]; then
        printf "%s" "$result"
        return "$exit_code"
    else
        printf "%s" "$result"
    fi
}

# ========================================================================
# --- lib_msg_prompt() Tests ---
# ========================================================================

@test "lib_msg_prompt(): basic prompt with user input" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test basic prompt functionality
    result=$(test_prompt_with_input "test_value" lib_msg_prompt "Enter value")
    
    # Debug: Show what we actually captured
    echo "DEBUG: result='$result'" >&3
    echo "DEBUG: length=${#result}" >&3
    
    [ "$result" = "test_value" ]
}

@test "lib_msg_prompt(): prompt with default value - user provides input" {
    # Set up TTY simulation  
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test prompt with default but user overrides
    result=$(test_prompt_with_input "override_value" lib_msg_prompt "Enter value" "default_val")
    
    [ "$result" = "override_value" ]
}

@test "lib_msg_prompt(): prompt with default value - user provides empty input" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test prompt with default and empty user input
    result=$(test_prompt_with_input "" lib_msg_prompt "Enter value" "default_val")
    
    [ "$result" = "default_val" ]
}

@test "lib_msg_prompt(): prompt with styling" {
    # Set up TTY simulation for colors
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test prompt with styling
    local style_seq
    style_seq=$(lib_msg_build_style_sequence "$_LIB_MSG_SGR_BOLD" "$_LIB_MSG_SGR_FG_BLUE")
    
    result=$(test_prompt_with_input "styled_input" lib_msg_prompt "Enter value" "$style_seq")
    
    [ "$result" = "styled_input" ]
}

@test "lib_msg_prompt(): prompt with empty prompt text" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test prompt with empty prompt text
    result=$(test_prompt_with_input "empty_prompt_test" lib_msg_prompt "")
    
    [ "$result" = "empty_prompt_test" ]
}

@test "lib_msg_prompt(): prompt handles whitespace in input" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test prompt with whitespace in input (read -r trims leading/trailing whitespace)
    result=$(test_prompt_with_input "  test value  " lib_msg_prompt "Enter value")
    
    [ "$result" = "test value" ]
}

@test "lib_msg_prompt(): prompt with long default value" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test prompt with long default value
    result=$(test_prompt_with_input "" lib_msg_prompt "Enter value" "this_is_a_very_long_default_value_for_testing")
    
    [ "$result" = "this_is_a_very_long_default_value_for_testing" ]
}

# ========================================================================
# --- lib_msg_prompt_yn() Tests ---
# ========================================================================

@test "lib_msg_prompt_yn(): responds 'true' to 'y' input" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test 'y' response
    result=$(test_prompt_with_input "y" lib_msg_prompt_yn "Continue?" "" "y")
    
    [ "$result" = "true" ]
}

@test "lib_msg_prompt_yn(): responds 'true' to 'yes' input" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test 'yes' response
    result=$(test_prompt_with_input "yes" lib_msg_prompt_yn "Continue?" "" "y")
    
    [ "$result" = "true" ]
}

@test "lib_msg_prompt_yn(): responds 'true' to 'Y' input (case insensitive)" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test 'Y' response (uppercase)
    result=$(test_prompt_with_input "Y" lib_msg_prompt_yn "Continue?" "" "y")
    
    [ "$result" = "true" ]
}

@test "lib_msg_prompt_yn(): responds 'true' to 'YES' input (case insensitive)" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test 'YES' response (uppercase)
    result=$(test_prompt_with_input "YES" lib_msg_prompt_yn "Continue?" "" "y")
    
    [ "$result" = "true" ]
}

@test "lib_msg_prompt_yn(): responds 'false' to 'n' input" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test 'n' response
    result=$(test_prompt_with_input "n" lib_msg_prompt_yn "Continue?" "" "n")
    
    [ "$result" = "false" ]
}

@test "lib_msg_prompt_yn(): responds 'false' to 'no' input" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test 'no' response
    result=$(test_prompt_with_input "no" lib_msg_prompt_yn "Continue?" "" "n")
    
    [ "$result" = "false" ]
}

@test "lib_msg_prompt_yn(): responds 'false' to invalid input" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test invalid response
    result=$(test_prompt_with_input "invalid" lib_msg_prompt_yn "Continue?" "" "n")
    
    [ "$result" = "false" ]
}

@test "lib_msg_prompt_yn(): default to 'y' - empty input uses default" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test empty input with 'y' default
    result=$(test_prompt_with_input "" lib_msg_prompt_yn "Continue?" "" "y")
    
    [ "$result" = "true" ]
}

@test "lib_msg_prompt_yn(): default to 'n' - empty input uses default" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test empty input with 'n' default
    result=$(test_prompt_with_input "" lib_msg_prompt_yn "Continue?" "" "n")
    
    [ "$result" = "false" ]
}

@test "lib_msg_prompt_yn(): default to 'Y' - uppercase default" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test empty input with 'Y' default (uppercase)
    result=$(test_prompt_with_input "" lib_msg_prompt_yn "Continue?" "" "Y")
    
    [ "$result" = "true" ]
}

@test "lib_msg_prompt_yn(): default to 'N' - uppercase default" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test empty input with 'N' default (uppercase)
    result=$(test_prompt_with_input "" lib_msg_prompt_yn "Continue?" "" "N")
    
    [ "$result" = "false" ]
}

@test "lib_msg_prompt_yn(): invalid default value - should error" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test invalid default value - function should return error code
    run test_prompt_with_input "y" lib_msg_prompt_yn "Continue?" "" "invalid"
    
    [ "$status" -ne 0 ]  # Should fail with non-zero exit code
}

@test "lib_msg_prompt_yn(): whitespace handling - removes spaces from input" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test input with spaces
    result=$(test_prompt_with_input "  y  " lib_msg_prompt_yn "Continue?" "" "y")
    
    [ "$result" = "true" ]
}

@test "lib_msg_prompt_yn(): responds 'false' to 'N' input (case insensitive)" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test 'N' response (uppercase)
    result=$(test_prompt_with_input "N" lib_msg_prompt_yn "Continue?" "" "n")
    
    [ "$result" = "false" ]
}

@test "lib_msg_prompt_yn(): responds 'false' to 'NO' input (case insensitive)" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test 'NO' response (uppercase)
    result=$(test_prompt_with_input "NO" lib_msg_prompt_yn "Continue?" "" "n")
    
    [ "$result" = "false" ]
}

# ========================================================================
# --- New Default Parameter Tests ---
# ========================================================================

@test "lib_msg_prompt_yn(): missing default parameter - should error" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test missing 4th parameter - function should return error code
    run test_prompt_with_input "y" lib_msg_prompt_yn "Continue?"
    
    [ "$status" -ne 0 ]  # Should fail with non-zero exit code
}

@test "lib_msg_prompt_yn(): default 'Y' shows [Y/n] format" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Capture the full prompt output to verify format
    local temp_file=$(mktemp)
    {
        printf "y\n" | lib_msg_prompt_yn "Continue?" "" "Y"
    } > "$temp_file" 2>/dev/null
    
    # Check that the prompt contains [Y/n]
    grep -q "\[Y/n\]" "$temp_file"
    local format_check=$?
    
    rm -f "$temp_file"
    [ "$format_check" -eq 0 ]
}

@test "lib_msg_prompt_yn(): default 'y' shows [Y/n] format" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Capture the full prompt output to verify format
    local temp_file=$(mktemp)
    {
        printf "y\n" | lib_msg_prompt_yn "Continue?" "" "y"
    } > "$temp_file" 2>/dev/null
    
    # Check that the prompt contains [Y/n]
    grep -q "\[Y/n\]" "$temp_file"
    local format_check=$?
    
    rm -f "$temp_file"
    [ "$format_check" -eq 0 ]
}

@test "lib_msg_prompt_yn(): default 'N' shows [y/N] format" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Capture the full prompt output to verify format
    local temp_file=$(mktemp)
    {
        printf "n\n" | lib_msg_prompt_yn "Continue?" "" "N"
    } > "$temp_file" 2>/dev/null
    
    # Check that the prompt contains [y/N]
    grep -q "\[y/N\]" "$temp_file"
    local format_check=$?
    
    rm -f "$temp_file"
    [ "$format_check" -eq 0 ]
}

@test "lib_msg_prompt_yn(): default 'n' shows [y/N] format" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Capture the full prompt output to verify format
    local temp_file=$(mktemp)
    {
        printf "n\n" | lib_msg_prompt_yn "Continue?" "" "n"
    } > "$temp_file" 2>/dev/null
    
    # Check that the prompt contains [y/N]
    grep -q "\[y/N\]" "$temp_file"
    local format_check=$?
    
    rm -f "$temp_file"
    [ "$format_check" -eq 0 ]
}

@test "lib_msg_prompt_yn(): empty input with 'Y' default returns true" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test empty input with 'Y' default (uppercase)
    result=$(test_prompt_with_input "" lib_msg_prompt_yn "Continue?" "" "Y")
    
    [ "$result" = "true" ]
}

@test "lib_msg_prompt_yn(): empty input with 'N' default returns false" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test empty input with 'N' default (uppercase)
    result=$(test_prompt_with_input "" lib_msg_prompt_yn "Continue?" "" "N")
    
    [ "$result" = "false" ]
}

@test "lib_msg_prompt_yn(): user input overrides default" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test user typing 'n' when default is 'Y'
    result=$(test_prompt_with_input "n" lib_msg_prompt_yn "Continue?" "" "Y")
    
    [ "$result" = "false" ]
}

@test "lib_msg_prompt_yn(): user input overrides default (opposite case)" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test user typing 'y' when default is 'N'
    result=$(test_prompt_with_input "y" lib_msg_prompt_yn "Continue?" "" "N")
    
    [ "$result" = "true" ]
}

@test "lib_msg_prompt_yn(): prompt includes script name prefix" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Capture the full prompt output to verify script name prefix
    local temp_file=$(mktemp)
    {
        printf "y\n" | lib_msg_prompt_yn "Continue?" "" "y"
    } > "$temp_file" 2>/dev/null
    
    # Check that the prompt contains the script name prefix
    grep -q "test_script.sh:" "$temp_file"
    local prefix_check=$?
    
    rm -f "$temp_file"
    [ "$prefix_check" -eq 0 ]
}

@test "lib_msg_prompt_yn(): prompt includes purple Q: tag" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Capture the full prompt output to verify colored Q: tag
    local temp_file=$(mktemp)
    {
        printf "y\n" | lib_msg_prompt_yn "Continue?" "" "y"
    } > "$temp_file" 2>/dev/null
    
    # Check that the prompt contains the Q: tag (may have ANSI color codes)
    grep -q "Q:" "$temp_file"
    local tag_check=$?
    
    rm -f "$temp_file"
    [ "$tag_check" -eq 0 ]
}