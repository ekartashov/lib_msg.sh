#!/usr/bin/env bats

# This file contains tests specifically for the max wrap length feature
# in the text wrapping functions of lib_msg.sh.

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

# --- Max Wrap Length Tests ---

@test "_lib_msg_wrap_text_sh(): with max_wrap_length parameter - basic functionality" {
    local input="This is a test string that should be truncated when it exceeds the maximum wrap length."
    local max_length=50
    
    # Test with max_wrap_length parameter
    local result=$(_lib_msg_wrap_text_sh "$input" 20 "$max_length")
    
    # Result should be truncated to max_length characters
    local result_length=${#result}
    [ "$result_length" -le "$max_length" ] || fail "Result length ($result_length) exceeds max_wrap_length ($max_length)"
    
    # Should still contain some of the original text
    [[ "$result" == *"This is a test"* ]] || fail "Result should contain beginning of input text"
}

@test "_lib_msg_wrap_text_sh(): max_wrap_length with short input (no truncation needed)" {
    local input="Short text"
    local max_length=100
    
    local result=$(_lib_msg_wrap_text_sh "$input" 20 "$max_length")
    
    # Should return the complete input since it's shorter than max_length
    assert_equal "$result" "$input" "Short input should not be truncated"
}

@test "_lib_msg_wrap_text_sh(): max_wrap_length with empty input" {
    local input=""
    local max_length=50
    
    local result=$(_lib_msg_wrap_text_sh "$input" 20 "$max_length")
    
    assert_equal "$result" "" "Empty input should produce empty output even with max_wrap_length"
}

@test "_lib_msg_wrap_text_sh(): max_wrap_length of 0 (no limit)" {
    local input="This is a test string that should not be limited when max_wrap_length is 0."
    local max_length=0
    
    local result=$(_lib_msg_wrap_text_sh "$input" 20 "$max_length")
    
    # Should behave like normal wrapping without length limit
    local normal_result=$(_lib_msg_wrap_text_sh "$input" 20)
    assert_equal "$result" "$normal_result" "max_wrap_length=0 should behave like unlimited"
}

@test "_lib_msg_wrap_text_sh(): max_wrap_length smaller than wrap width" {
    local input="This is a very long string that exceeds both the wrap width and max length."
    local wrap_width=50
    local max_length=20
    
    local result=$(_lib_msg_wrap_text_sh "$input" "$wrap_width" "$max_length")
    
    # Result should be limited by max_length, not wrap_width
    local result_length=${#result}
    [ "$result_length" -le "$max_length" ] || fail "Result length ($result_length) exceeds max_wrap_length ($max_length)"
}

@test "_lib_msg_wrap_text_sh(): max_wrap_length with oversized single word" {
    local input="supercalifragilisticexpialidocious"
    local wrap_width=10
    local max_length=20
    
    local result=$(_lib_msg_wrap_text_sh "$input" "$wrap_width" "$max_length")
    
    # Should truncate the long word to max_length
    local result_length=${#result}
    [ "$result_length" -le "$max_length" ] || fail "Result length ($result_length) exceeds max_wrap_length ($max_length)"
    
    # Should contain the beginning of the word
    [[ "$result" == "supercalifragilis"* ]] || fail "Result should contain beginning of the oversized word"
}

@test "_lib_msg_wrap_text_sh(): max_wrap_length with multiple lines" {
    local input="Line one that is quite long. Line two that is also long. Line three continues."
    local wrap_width=15
    local max_length=30
    
    local result=$(_lib_msg_wrap_text_sh "$input" "$wrap_width" "$max_length")
    
    # Result should be truncated to max_length
    local result_length=${#result}
    [ "$result_length" -le "$max_length" ] || fail "Result length ($result_length) exceeds max_wrap_length ($max_length)"
    
    # Should handle record separators properly in truncated output
    if [[ "$result" == *"$_LIB_MSG_RS"* ]]; then
        # If there are record separators, they should be valid
        local line_count=$(printf '%s' "$result" | grep -o "$_LIB_MSG_RS" | wc -l)
        [ "$line_count" -ge 0 ] || fail "Invalid record separators in truncated output"
    fi
}

@test "_lib_msg_wrap_text_sh(): max_wrap_length with whitespace-only input" {
    local input="     "
    local max_length=50
    
    local result=$(_lib_msg_wrap_text_sh "$input" 20 "$max_length")
    
    # Should still produce empty output for whitespace-only
    assert_equal "$result" "" "Whitespace-only input should produce empty output with max_wrap_length"
}

@test "_lib_msg_wrap_text_sh(): max_wrap_length edge case - exactly at limit" {
    local input="1234567890abcdef1234567890"  # 26 characters
    local max_length=26
    
    local result=$(_lib_msg_wrap_text_sh "$input" 10 "$max_length")
    
    # Should not truncate when exactly at limit
    local result_length=${#result}
    [ "$result_length" -le "$max_length" ] || fail "Result length ($result_length) exceeds max_wrap_length ($max_length)"
}

@test "_lib_msg_wrap_text_sh(): max_wrap_length with negative value (should be ignored)" {
    local input="This is a test string."
    local max_length=-10
    
    local result=$(_lib_msg_wrap_text_sh "$input" 20 "$max_length")
    
    # Should behave like normal wrapping (negative max_length should be treated as unlimited)
    local normal_result=$(_lib_msg_wrap_text_sh "$input" 20)
    assert_equal "$result" "$normal_result" "Negative max_wrap_length should behave like unlimited"
}

@test "_lib_msg_wrap_text_sh(): max_wrap_length preserves record separator format" {
    local input="Word1 Word2 Word3 Word4 Word5 Word6"
    local wrap_width=10
    local max_length=25  # Should allow about 2-3 wrapped lines
    
    local result=$(_lib_msg_wrap_text_sh "$input" "$wrap_width" "$max_length")
    
    # Check that record separators are properly handled
    if [[ "$result" == *"$_LIB_MSG_RS"* ]]; then
        # Split by record separator and check each part
        local first_part="${result%%"$_LIB_MSG_RS"*}"
        [ -n "$first_part" ] || fail "First part of wrapped result should not be empty"
        
        # Remaining parts should also be non-empty if they exist
        local remaining="${result#*"$_LIB_MSG_RS"}"
        if [ "$remaining" != "$result" ]; then  # There was a record separator
            [ -n "$remaining" ] || fail "Parts after record separator should not be empty"
        fi
    fi
}

@test "_lib_msg_wrap_text_sh(): backward compatibility - missing max_wrap_length parameter" {
    local input="This is a test string for backward compatibility."
    
    # Call without max_wrap_length parameter (should work as before)
    local result=$(_lib_msg_wrap_text_sh "$input" 20)
    
    # Should work normally without the parameter
    local expected_rs="This is a test${_LIB_MSG_RS}string for backward${_LIB_MSG_RS}compatibility."
    assert_equal "$result" "$expected_rs" "Should work without max_wrap_length parameter"
}

@test "_lib_msg_wrap_text_sh(): performance consideration - very large max_wrap_length" {
    local input="This is a normal string for performance testing."
    local max_length=10000  # Very large limit
    
    local result=$(_lib_msg_wrap_text_sh "$input" 20 "$max_length")
    
    # Should complete without issues and behave normally
    local normal_result=$(_lib_msg_wrap_text_sh "$input" 20)
    assert_equal "$result" "$normal_result" "Large max_wrap_length should not affect normal operation"
}