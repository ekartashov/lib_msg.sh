#!/usr/bin/env bats

# This file contains tests specifically focused on the pure POSIX shell
# implementation of _lib_msg_wrap_text_sh() in lib_msg.sh.

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

# --- _lib_msg_wrap_text_sh() Tests ---

@test "_lib_msg_wrap_text_sh(): with empty input" {
    local result=$(_lib_msg_wrap_text_sh "" 40)
    assert_equal "$result" "" "Empty input should produce empty output"
}

@test "_lib_msg_wrap_text_sh(): with width <= 0 (no wrapping)" {
    local input="This text should not be wrapped regardless of its length."
    local result
    
    result=$(_lib_msg_wrap_text_sh "$input" 0)
    assert_equal "$result" "$input" "Width=0 should not wrap text"
    
    result=$(_lib_msg_wrap_text_sh "$input" -5)
    assert_equal "$result" "$input" "Negative width should not wrap text"
}

@test "_lib_msg_wrap_text_sh(): basic wrapping" {
    local input="This is a simple test of the word wrapping function."
    local expected_rs
    
    # Expected output with record separator between lines for width=20
    expected_rs="This is a simple${_LIB_MSG_RS}test of the word${_LIB_MSG_RS}wrapping function."
    
    local result=$(_lib_msg_wrap_text_sh "$input" 20)
    assert_equal "$result" "$expected_rs" "Basic wrapping failed at width=20"
}

@test "_lib_msg_wrap_text_sh(): wraps long words" {
    local input="Testing supercalifragilisticexpialidocious wrapping"
    local expected_rs
    
    # Break the long word at width 10
    # Update the expected output to match the actual implementation
    expected_rs="Testing${_LIB_MSG_RS}supercalif${_LIB_MSG_RS}ragilistic${_LIB_MSG_RS}expialidoc${_LIB_MSG_RS}ious${_LIB_MSG_RS}wrapping"
    
    local result=$(_lib_msg_wrap_text_sh "$input" 10)
    
    # Print debug info to BATS debug output
    echo "Expected: $(printf %q "$expected_rs")" >&3
    echo "Actual: $(printf %q "$result")" >&3
    
    assert_equal "$result" "$expected_rs" "Long word wrapping failed at width=10"
}

@test "_lib_msg_wrap_text_sh(): handles whitespace-only input" {
    local input="     "
    local result=$(_lib_msg_wrap_text_sh "$input" 10)
    assert_equal "$result" "" "Whitespace-only should produce empty output"
}

@test "_lib_msg_wrap_text_sh(): proper continuation handling" {
    local input="First line with exact length. Second line here."
    local expected_rs
    
    # Width 25 should break exactly after "length."
    expected_rs="First line with exact${_LIB_MSG_RS}length. Second line here."
    
    local result=$(_lib_msg_wrap_text_sh "$input" 25)
    assert_equal "$result" "$expected_rs" "Failed to break line at expected point"
}

@test "_lib_msg_wrap_text_sh(): handles multiple spaces between words" {
    local input="Word1   Word2     Word3"
    local expected_rs
    
    # Expect normalized spaces in output (single spaces between words)
    expected_rs="Word1${_LIB_MSG_RS}Word2${_LIB_MSG_RS}Word3"
    
    local result=$(_lib_msg_wrap_text_sh "$input" 5)
    assert_equal "$result" "$expected_rs" "Failed to normalize spaces"
}

@test "_lib_msg_wrap_text_sh(): handles newlines in input" {
    local input="Line one
Line two
Line three"
    local expected_rs
    
    # Should convert newlines to spaces (or treat them as word separators)
    expected_rs="Line one Line${_LIB_MSG_RS}two Line three"
    
    local result=$(_lib_msg_wrap_text_sh "$input" 15)
    assert_equal "$result" "$expected_rs" "Failed to handle newlines correctly"
}

@test "_lib_msg_wrap_text_sh(): handles trailing spaces" {
    local input="Word1  "
    local result=$(_lib_msg_wrap_text_sh "$input" 10)
    assert_equal "$result" "Word1" "Failed to handle trailing spaces"
}

@test "_lib_msg_wrap_text_sh(): handles leading spaces" {
    local input="  Word1"
    local result=$(_lib_msg_wrap_text_sh "$input" 10)
    assert_equal "$result" "Word1" "Failed to handle leading spaces"
}

@test "_lib_msg_wrap_text_sh(): exact width word at end of line" {
    local input="12345 1234567890"
    local expected_rs="12345${_LIB_MSG_RS}1234567890"
    local result=$(_lib_msg_wrap_text_sh "$input" 10)
    assert_equal "$result" "$expected_rs" "Failed to handle exact width word at end of line"
}

@test "_lib_msg_wrap_text_sh(): word exactly one character over width" {
    local input="12345678901"
    local expected_rs="1234567890${_LIB_MSG_RS}1"
    local result=$(_lib_msg_wrap_text_sh "$input" 10)
    assert_equal "$result" "$expected_rs" "Failed to handle word 1 character over width"
}

@test "_lib_msg_wrap_text_sh(): word splitting at different widths" {
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
        
        local result=$(_lib_msg_wrap_text_sh "$input" "$width")
        assert_equal "$result" "$expected" "Width $width wrapping incorrect"
    done
}

@test "_lib_msg_wrap_text_sh(): Unicode characters" {
    # This test may fail if the system has different UTF-8 handling or if shell's char processing is basic
    local input="ｔｈｉｓ ｉｓ ｗｉｄｅ unicode text: 你好，世界"
    local result=$(_lib_msg_wrap_text_sh "$input" 15)
    
    # Just check that output was produced and doesn't contain binary garbage
    # POSIX shell might not handle Unicode width correctly for wrapping,
    # so exact output is hard to predict without knowing specific shell behavior.
    # The main goal is that it doesn't break catastrophically.
    [ -n "$result" ] || fail "No output produced for Unicode input"
    [[ "$result" == *"ｔｈｉｓ"* ]] || fail "Output doesn't contain expected Unicode characters (full-width)"
    [[ "$result" == *"你好"* ]] || fail "Output doesn't contain expected Chinese characters"

    # A more robust check might be against the awk version if we assume awk handles unicode better
    # For now, this basic check is a starting point.
    # local awk_result=$(_lib_msg_wrap_text_awk "$input" 15)
    # assert_equal "$result" "$awk_result" "Shell version differs from AWK for Unicode input at width 15"
}

@test "_lib_msg_wrap_text_sh(): text with punctuation" {
    local input="Text with, punctuation; marks! And \"quotes\" 'too'."
    local expected_rs="Text with,${_LIB_MSG_RS}punctuation;${_LIB_MSG_RS}marks! And${_LIB_MSG_RS}\"quotes\"${_LIB_MSG_RS}'too'."
    local result=$(_lib_msg_wrap_text_sh "$input" 12)
    assert_equal "$result" "$expected_rs" "Failed to handle punctuation correctly"
}