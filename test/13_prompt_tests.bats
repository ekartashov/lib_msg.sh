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
    
    # For lib_msg_prompt, extract the return value from the last line
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

# Helper function specifically for lib_msg_prompt_yn that returns exit codes
test_prompt_yn_with_input() {
    local input="$1"
    shift
    
    # Run the function with input and capture its exit code
    printf "%s\n" "$input" | "$@" >/dev/null 2>&1
    local exit_code=$?
    return $exit_code
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

@test "lib_msg_prompt_yn(): responds with exit code 0 to 'y' input" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test 'y' response - should return exit code 0
    run test_prompt_yn_with_input "y" lib_msg_prompt_yn "Continue?" "" "y"
    [ "$status" -eq 0 ]
}

@test "lib_msg_prompt_yn(): responds with exit code 0 to 'yes' input" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test 'yes' response - should return exit code 0
    run test_prompt_yn_with_input "yes" lib_msg_prompt_yn "Continue?" "" "y"
    [ "$status" -eq 0 ]
}

@test "lib_msg_prompt_yn(): responds with exit code 0 to 'Y' input (case insensitive)" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test 'Y' response (uppercase) - should return exit code 0
    run test_prompt_yn_with_input "Y" lib_msg_prompt_yn "Continue?" "" "y"
    [ "$status" -eq 0 ]
}

@test "lib_msg_prompt_yn(): responds with exit code 0 to 'YES' input (case insensitive)" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test 'YES' response (uppercase) - should return exit code 0
    run test_prompt_yn_with_input "YES" lib_msg_prompt_yn "Continue?" "" "y"
    [ "$status" -eq 0 ]
}

@test "lib_msg_prompt_yn(): responds with exit code 1 to 'n' input" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test 'n' response - should return exit code 1
    run test_prompt_yn_with_input "n" lib_msg_prompt_yn "Continue?" "" "n"
    [ "$status" -eq 1 ]
}

@test "lib_msg_prompt_yn(): responds with exit code 1 to 'no' input" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test 'no' response - should return exit code 1
    run test_prompt_yn_with_input "no" lib_msg_prompt_yn "Continue?" "" "n"
    [ "$status" -eq 1 ]
}

@test "lib_msg_prompt_yn(): responds with exit code 1 to invalid input" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test invalid response - should return exit code 1
    run test_prompt_yn_with_input "invalid" lib_msg_prompt_yn "Continue?" "" "n"
    [ "$status" -eq 1 ]
}

@test "lib_msg_prompt_yn(): default to 'y' - empty input uses default (exit code 0)" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test empty input with 'y' default - should return exit code 0
    run test_prompt_yn_with_input "" lib_msg_prompt_yn "Continue?" "" "y"
    [ "$status" -eq 0 ]
}

@test "lib_msg_prompt_yn(): default to 'n' - empty input uses default (exit code 1)" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test empty input with 'n' default - should return exit code 1
    run test_prompt_yn_with_input "" lib_msg_prompt_yn "Continue?" "" "n"
    [ "$status" -eq 1 ]
}

@test "lib_msg_prompt_yn(): default to 'Y' - uppercase default (exit code 0)" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test empty input with 'Y' default (uppercase) - should return exit code 0
    run test_prompt_yn_with_input "" lib_msg_prompt_yn "Continue?" "" "Y"
    [ "$status" -eq 0 ]
}

@test "lib_msg_prompt_yn(): default to 'N' - uppercase default (exit code 1)" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test empty input with 'N' default (uppercase) - should return exit code 1
    run test_prompt_yn_with_input "" lib_msg_prompt_yn "Continue?" "" "N"
    [ "$status" -eq 1 ]
}

@test "lib_msg_prompt_yn(): invalid default value - should error" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test invalid default value - function should return error code
    run test_prompt_with_input "y" lib_msg_prompt_yn "Continue?" "" "invalid"
    
    [ "$status" -ne 0 ]  # Should fail with non-zero exit code
}

@test "lib_msg_prompt_yn(): whitespace handling - removes spaces from input (exit code 0)" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test input with spaces - should return exit code 0
    run test_prompt_yn_with_input "  y  " lib_msg_prompt_yn "Continue?" "" "y"
    [ "$status" -eq 0 ]
}

@test "lib_msg_prompt_yn(): responds with exit code 1 to 'N' input (case insensitive)" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test 'N' response (uppercase) - should return exit code 1
    run test_prompt_yn_with_input "N" lib_msg_prompt_yn "Continue?" "" "n"
    [ "$status" -eq 1 ]
}

@test "lib_msg_prompt_yn(): responds with exit code 1 to 'NO' input (case insensitive)" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test 'NO' response (uppercase) - should return exit code 1
    run test_prompt_yn_with_input "NO" lib_msg_prompt_yn "Continue?" "" "n"
    [ "$status" -eq 1 ]
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
        printf "n\n" | lib_msg_prompt_yn "Continue?" "" "N" || true
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
        printf "n\n" | lib_msg_prompt_yn "Continue?" "" "n" || true
    } > "$temp_file" 2>/dev/null
    
    # Check that the prompt contains [y/N]
    grep -q "\[y/N\]" "$temp_file"
    local format_check=$?
    
    rm -f "$temp_file"
    [ "$format_check" -eq 0 ]
}

@test "lib_msg_prompt_yn(): empty input with 'Y' default returns exit code 0" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test empty input with 'Y' default (uppercase) - should return exit code 0
    run test_prompt_yn_with_input "" lib_msg_prompt_yn "Continue?" "" "Y"
    [ "$status" -eq 0 ]
}

@test "lib_msg_prompt_yn(): empty input with 'N' default returns exit code 1" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test empty input with 'N' default (uppercase) - should return exit code 1
    run test_prompt_yn_with_input "" lib_msg_prompt_yn "Continue?" "" "N"
    [ "$status" -eq 1 ]
}

@test "lib_msg_prompt_yn(): user input overrides default (n when default is Y)" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test user typing 'n' when default is 'Y' - should return exit code 1
    run test_prompt_yn_with_input "n" lib_msg_prompt_yn "Continue?" "" "Y"
    [ "$status" -eq 1 ]
}

@test "lib_msg_prompt_yn(): user input overrides default (y when default is N)" {
    # Set up TTY simulation
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    
    # Test user typing 'y' when default is 'N' - should return exit code 0
    run test_prompt_yn_with_input "y" lib_msg_prompt_yn "Continue?" "" "N"
    [ "$status" -eq 0 ]
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
# ========================================================================
# --- Text Wrapping Tests ---
# ========================================================================

@test "lib_msg_prompt_yn(): long text wraps with proper indentation like other functions" {
    # Set up TTY simulation with narrow terminal width
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    export COLUMNS=80
    _lib_msg_force_reinit  # Reinitialize to pick up new COLUMNS
    
    # Long text that should wrap
    local long_text="Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book."
    
    # Capture output from lib_msg_prompt_yn
    local temp_file=$(mktemp)
    {
        printf "n\n" | lib_msg_prompt_yn "$long_text" "" "n" || true
    } > "$temp_file" 2>/dev/null
    
    # Check that output contains line breaks (indicating wrapping occurred)
    local line_count=$(wc -l < "$temp_file")
    
    # Also check that subsequent lines are properly indented
    # Look for lines that start with whitespace (indicating continuation lines)
    local indented_lines=$(grep -c "^[[:space:]]\+" "$temp_file" || echo "0")
    
    rm -f "$temp_file"
    
    # Should have multiple lines due to wrapping
    [ "$line_count" -gt 1 ]
    
    # Should have indented continuation lines
    [ "$indented_lines" -gt 0 ]
}

@test "lib_msg_prompt_yn(): wrapping behavior matches err() function pattern" {
    # Set up TTY simulation with narrow terminal width
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    export COLUMNS=80
    _lib_msg_force_reinit  # Reinitialize to pick up new COLUMNS
    
    # Long text that should wrap
    local long_text="Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text."
    
    # Capture output from both functions
    local prompt_file=$(mktemp)
    local err_file=$(mktemp)
    
    {
        printf "n\n" | lib_msg_prompt_yn "$long_text" "" "n" || true
    } > "$prompt_file" 2>/dev/null
    
    {
        err "$long_text"
    } > "$err_file" 2>&1
    
    # Extract indentation pattern from both files
    # Both should show similar indentation for continuation lines
    local prompt_indent=$(grep "^[[:space:]]\+" "$prompt_file" | head -1 | sed 's/[^[:space:]].*//' | wc -c)
    local err_indent=$(grep "^[[:space:]]\+" "$err_file" | head -1 | sed 's/[^[:space:]].*//' | wc -c)
    
    rm -f "$prompt_file" "$err_file"
    
    # Both should use similar indentation (within a few characters due to different prefixes)
    local indent_diff=$((prompt_indent > err_indent ? prompt_indent - err_indent : err_indent - prompt_indent))
    [ "$indent_diff" -le 5 ]  # Allow small differences due to different prefix lengths
}

@test "lib_msg_prompt_yn(): no wrapping when not TTY" {
    # Set up non-TTY environment (no wrapping should occur)
    simulate_tty_conditions 1 1  # Neither stdout nor stderr are TTY
    export COLUMNS=80
    _lib_msg_force_reinit
    
    # Long text
    local long_text="Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text."
    
    # Capture output
    local temp_file=$(mktemp)
    {
        printf "n\n" | lib_msg_prompt_yn "$long_text" "" "n" || true
    } > "$temp_file" 2>/dev/null
    
    # Should be on a single line when not TTY
    # Note: wc -l counts newlines, not lines. Since prompt doesn't end with newline,
    # we need to check if there are 0 newlines (meaning single line) OR 1 newline
    local line_count=$(wc -l < "$temp_file")
    local has_content=$(test -s "$temp_file" && echo "1" || echo "0")
    
    rm -f "$temp_file"
    
    # Should have content but no internal line breaks (0 or 1 newlines max)
    [ "$has_content" -eq 1 ] && [ "$line_count" -le 1 ]
}

@test "lib_msg_prompt_yn(): preserves exit code behavior after wrapping fix" {
    # Set up TTY simulation with wrapping conditions
    simulate_tty_conditions 0 0  # Both stdout and stderr are TTY
    export COLUMNS=80
    _lib_msg_force_reinit
    
    # Long text that will wrap
    local long_text="Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text."
    
    # Test that exit codes still work correctly with wrapping
    run test_prompt_yn_with_input "y" lib_msg_prompt_yn "$long_text" "" "n"
    [ "$status" -eq 0 ]  # Should return 0 for 'y' input
    
    run test_prompt_yn_with_input "n" lib_msg_prompt_yn "$long_text" "" "y"
    [ "$status" -eq 1 ]  # Should return 1 for 'n' input
}