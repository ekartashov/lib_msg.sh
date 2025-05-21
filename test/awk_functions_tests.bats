#!/usr/bin/env bats

# This file contains tests specifically focused on the AWK implementations
# in lib_msg.sh, particularly _lib_msg_wrap_text_awk().

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

# Skip all tests if awk is not available
setup() {
    if ! command -v awk >/dev/null 2>&1; then
        skip "awk command is not available"
    fi
}

# --- _lib_msg_wrap_text_awk() Tests ---

@test "_lib_msg_wrap_text_awk(): with empty input" {
    local result=$(_lib_msg_wrap_text_awk "" 40)
    assert_equal "$result" "" "Empty input should produce empty output"
}

@test "_lib_msg_wrap_text_awk(): with width <= 0 (no wrapping)" {
    local input="This text should not be wrapped regardless of its length."
    local result
    
    result=$(_lib_msg_wrap_text_awk "$input" 0)
    assert_equal "$result" "$input" "Width=0 should not wrap text"
    
    result=$(_lib_msg_wrap_text_awk "$input" -5)
    assert_equal "$result" "$input" "Negative width should not wrap text"
}

@test "_lib_msg_wrap_text_awk(): basic wrapping" {
    local input="This is a simple test of the word wrapping function."
    local expected_rs
    
    # Expected output with record separator between lines for width=20
    expected_rs="This is a simple${_LIB_MSG_RS}test of the word${_LIB_MSG_RS}wrapping function."
    
    local result=$(_lib_msg_wrap_text_awk "$input" 20)
    assert_equal "$result" "$expected_rs" "Basic wrapping failed at width=20"
}

@test "_lib_msg_wrap_text_awk(): wraps long words" {
    local input="Testing supercalifragilisticexpialidocious wrapping"
    local expected_rs
    
    # Break the long word at width 10
    expected_rs="Testing${_LIB_MSG_RS}supercalif${_LIB_MSG_RS}ragilistic${_LIB_MSG_RS}expialidoc${_LIB_MSG_RS}ious${_LIB_MSG_RS}wrapping"
    
    local result=$(_lib_msg_wrap_text_awk "$input" 10)
    
    # Print debug info to BATS debug output
    echo "Expected: $(printf %q "$expected_rs")" >&3
    echo "Actual: $(printf %q "$result")" >&3
    
    assert_equal "$result" "$expected_rs" "Long word wrapping failed at width=10"
}

@test "_lib_msg_wrap_text_awk(): handles whitespace-only input" {
    local input="     "
    local result=$(_lib_msg_wrap_text_awk "$input" 10)
    assert_equal "$result" "" "Whitespace-only should produce empty output"
}

@test "_lib_msg_wrap_text_awk(): proper continuation handling" {
    local input="First line with exact length. Second line here."
    local expected_rs
    
    # Width 25 should break exactly after "length."
    expected_rs="First line with exact${_LIB_MSG_RS}length. Second line here."
    
    local result=$(_lib_msg_wrap_text_awk "$input" 25)
    assert_equal "$result" "$expected_rs" "Failed to break line at expected point"
}

@test "_lib_msg_wrap_text_awk(): handles multiple spaces between words" {
    local input="Word1   Word2     Word3"
    local expected_rs
    
    # Expect normalized spaces in output (single spaces between words)
    expected_rs="Word1${_LIB_MSG_RS}Word2${_LIB_MSG_RS}Word3"
    
    local result=$(_lib_msg_wrap_text_awk "$input" 5)
    assert_equal "$result" "$expected_rs" "Failed to normalize spaces"
}

@test "_lib_msg_wrap_text_awk(): handles newlines in input" {
    local input="Line one
Line two
Line three"
    local expected_rs
    
    # Should convert newlines to spaces per line 363 in implementation
    expected_rs="Line one Line${_LIB_MSG_RS}two Line three"
    
    local result=$(_lib_msg_wrap_text_awk "$input" 15)
    assert_equal "$result" "$expected_rs" "Failed to handle newlines correctly"
}

@test "_lib_msg_wrap_text_awk(): handles trailing spaces" {
    local input="Word1  "
    local result=$(_lib_msg_wrap_text_awk "$input" 10)
    assert_equal "$result" "Word1" "Failed to handle trailing spaces"
}

@test "_lib_msg_wrap_text_awk(): handles leading spaces" {
    local input="  Word1"
    local result=$(_lib_msg_wrap_text_awk "$input" 10)
    assert_equal "$result" "Word1" "Failed to handle leading spaces"
}

@test "_lib_msg_wrap_text_awk(): exact width word at end of line" {
    local input="12345 1234567890"
    local expected_rs="12345${_LIB_MSG_RS}1234567890"
    local result=$(_lib_msg_wrap_text_awk "$input" 10)
    assert_equal "$result" "$expected_rs" "Failed to handle exact width word at end of line"
}

@test "_lib_msg_wrap_text_awk(): word exactly one character over width" {
    local input="12345678901"
    local expected_rs="1234567890${_LIB_MSG_RS}1"
    local result=$(_lib_msg_wrap_text_awk "$input" 10)
    assert_equal "$result" "$expected_rs" "Failed to handle word 1 character over width"
}

@test "_lib_msg_wrap_text_awk(): empty words" {
    local input="Word1  Word2"
    local expected_rs="Word1${_LIB_MSG_RS}Word2"
    local result=$(_lib_msg_wrap_text_awk "$input" 10)
    assert_equal "$result" "$expected_rs" "Failed to handle empty words (multiple spaces)"
}

@test "_lib_msg_wrap_text_awk(): word splitting at different widths" {
    local input="The quick brown fox jumps over the lazy dog."
    local expected_widths=(
        "5:The${_LIB_MSG_RS}quick${_LIB_MSG_RS}brown${_LIB_MSG_RS}fox${_LIB_MSG_RS}jumps${_LIB_MSG_RS}over${_LIB_MSG_RS}the${_LIB_MSG_RS}lazy${_LIB_MSG_RS}dog."
        "10:The quick${_LIB_MSG_RS}brown fox${_LIB_MSG_RS}jumps over${_LIB_MSG_RS}the lazy${_LIB_MSG_RS}dog."
        "15:The quick brown${_LIB_MSG_RS}fox jumps over${_LIB_MSG_RS}the lazy dog."
        "20:The quick brown fox${_LIB_MSG_RS}jumps over the lazy${_LIB_MSG_RS}dog."
        "30:The quick brown fox jumps over${_LIB_MSG_RS}the lazy dog."
    )
    
    for test_case in "${expected_widths[@]}"; do
        # Split test case by colon into width and expected result
        local width="${test_case%%:*}"
        local expected="${test_case#*:}"
        
        local result=$(_lib_msg_wrap_text_awk "$input" "$width")
        assert_equal "$result" "$expected" "Width $width wrapping incorrect"
    done
}

@test "_lib_msg_wrap_text_awk(): Unicode characters" {
    # This test may fail if the system has different UTF-8 handling
    local input="ｔｈｉｓ ｉｓ ｗｉｄｅ unicode text: 你好，世界"
    local result=$(_lib_msg_wrap_text_awk "$input" 15)
    
    # Just check that output was produced and doesn't contain binary garbage
    [ -n "$result" ] || fail "No output produced for Unicode input"
    [[ "$result" == *"ｔｈｉｓ"* ]] || fail "Output doesn't contain expected Unicode characters"
    [[ "$result" == *"你好"* ]] || fail "Output doesn't contain expected Chinese characters"
}

@test "_lib_msg_wrap_text_awk(): text with punctuation" {
    local input="Text with, punctuation; marks! And \"quotes\" 'too'."
    local expected_rs="Text with,${_LIB_MSG_RS}punctuation;${_LIB_MSG_RS}marks! And${_LIB_MSG_RS}\"quotes\"${_LIB_MSG_RS}'too'."
    local result=$(_lib_msg_wrap_text_awk "$input" 12)
    assert_equal "$result" "$expected_rs" "Failed to handle punctuation correctly"
}

@test "_lib_msg_wrap_text_awk(): awk version has identical line breaking as shell version (with complex input)" {
    # Skip if awk is not available
    command -v awk >/dev/null 2>&1 || skip "awk is not available"
    
    # Set of edge case inputs
    local test_cases=(
        "A simple 'quoted string' with punctuation.... testing?"
        "This   has   multiple   spaces   between   words."
        "Thisis averylongwordthatneeds tobebrokendifferently."
        "Mixed- -content with- -dashes and "quoted" text."
        "Line 1
         Line 2
         Line 3 with a verylongwordthatgoespastthewidth"
        "Word. Another. Again. More words with periods."
    )
    
    # Test each input at different widths
    for input in "${test_cases[@]}"; do
        for width in 8 10 15 20 25 30 40; do
            local shell_result=$(_lib_msg_wrap_text_sh "$input" "$width")
            local awk_result=$(_lib_msg_wrap_text_awk "$input" "$width")
            
            assert_equal "$awk_result" "$shell_result" "Shell and AWK implementations differ for input '$input' at width $width"
        done
    done
}

@test "_lib_msg_wrap_text(): forcing awk implementation through setting command availability" {
    # Save original functions
    local orig_has_command
    local orig_awk_impl
    local orig_shell_impl
    orig_has_command=$(declare -f _lib_msg_has_command)
    orig_awk_impl=$(declare -f _lib_msg_wrap_text_awk)
    orig_shell_impl=$(declare -f _lib_msg_wrap_text_sh)
    
    # Create temporary file to track function calls
    local tracking_file="${BATS_TEST_TMPDIR}/function_called.txt"
    echo "none" > "$tracking_file"
    
    # Replace the has_command function to force awk to be detected
    _lib_msg_has_command() {
        if [ "$1" = "awk" ]; then
            return 0  # awk is available
        fi
        # For other commands, return false by default to avoid other issues
        return 1
    }
    
    # Override implementations to track calls using file
    _lib_msg_wrap_text_awk() {
        echo "awk" > "$tracking_file"
        echo "Dummy awk implementation called"
    }
    
    _lib_msg_wrap_text_sh() {
        echo "shell" > "$tracking_file"
        echo "Dummy shell implementation called"
    }
    
    # Call _lib_msg_wrap_text and check which implementation was used
    _lib_msg_wrap_text "Test text" 10 >/dev/null
    
    # Read tracking file to see which was called
    local called
    called=$(cat "$tracking_file")
    
    # Assert awk implementation was used
    [ "$called" = "awk" ] || fail "awk implementation was not called, got: $called"
    
    # Restore original functions
    eval "$orig_has_command"
    eval "$orig_awk_impl"
    eval "$orig_shell_impl"
    
    rm -f "$tracking_file"
}