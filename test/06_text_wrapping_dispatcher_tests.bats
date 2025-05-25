#!/usr/bin/env bats

# This file contains tests for the _lib_msg_wrap_text() function
# in lib_msg.sh, which now uses the pure shell implementation directly.

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

@test "_lib_msg_wrap_text: parameterized tests using assert_wrap_text_rs" {
    # Define test cases: "description;input_text;width;expected_line1;expected_line2;..."
    # Note: An empty expected line should be represented by an empty field (e.g., ...;expected_line1;;expected_line3;...)
    local wrap_text_test_cases=(
        "No wrapping if width is 0;This is a test sentence.;0;This is a test sentence."
        "No wrapping if text is shorter than width;Short text.;20;Short text."
        "Wraps simple text;This is a slightly longer sentence that should wrap.;20;This is a slightly;longer sentence that;should wrap."
        "Handles empty string input;;20;" # Empty input should produce one empty line
        "Handles long word that needs splitting;Thisisaverylongwordthatcannotfit;10;Thisisaver;ylongwordt;hatcannotf;it"
        "Handles long word at start of new line after wrap;Short then Thisisaverylongwordthatcannotfit;10;Short then;Thisisaver;ylongwordt;hatcannotf;it"
        "Handles multiple spaces between words;Word1  Word2   Word3;10;Word1;Word2;Word3" # Current POSIX-compliant behavior skips extra spaces
        "Diagnostic test message;Diagnostic test message;20;Diagnostic test;message"
        "Width exactly fits a word;fit;3;fit"
        "Width one less than a word;toolong;6;toolon;g"
        "Text with leading/trailing spaces;  leading and trailing spaces  ;20;leading and trailing;spaces" # read in _lib_msg_wrap_text trims these
        "Text with only spaces;     ;10;" # Empty input effectively - should produce one empty line
    )

    local test_idx=0
    for test_case_str in "${wrap_text_test_cases[@]}"; do
        test_idx=$((test_idx + 1))
        # Parse the test case string
        local old_ifs="$IFS"
        IFS=';'
        # shellcheck disable=SC2206 # Word splitting is desired here
        local params=($test_case_str)
        IFS="$old_ifs"

        local description="${params[0]}"
        local input_text="${params[1]}"
        local width="${params[2]}"

        # Build expected output string with newlines
        local expected_output=""
        # Loop from index 3 to the end of params array for expected lines
        if [ "${#params[@]}" -gt 3 ]; then
            for (( i=3; i<${#params[@]}; i++ )); do
                if [ -n "$expected_output" ]; then
                    expected_output="${expected_output}
${params[i]}"
                else
                    expected_output="${params[i]}"
                fi
            done
        elif [ "${#params[@]}" -eq 3 ] && [[ "$test_case_str" == *\; ]]; then
            # Case like "description;input;width;" expecting one empty line
            expected_output=""
        fi

        echo "Test Case $test_idx ('$description'): Testing _lib_msg_wrap_text with assert_wrap_text_rs" >&3
        
        # Use our helper to test _lib_msg_wrap_text with its RS-delimited string output
        assert_wrap_text_rs "$input_text" "$width" "$expected_output"
    done
}

@test "_lib_msg_wrap_text(): uses shell implementation" {
    # Define markers for stub calls
    local shell_marker="SHELL_STUB_CALLED_MARKER_UNIQUE_STRING"

    # Save original function
    local original_sh_func
    original_sh_func=$(declare -f _lib_msg_wrap_text_sh)

    # Override the implementation function directly
    _lib_msg_wrap_text_sh() {
        echo "DEBUG: shell_func CALLED DIRECTLY" >&2
        echo "$shell_marker"
    }
    
    local func_output
    func_output=$(_lib_msg_wrap_text "Test text" 10)
    local exit_status=$?
    
    # Restore original function
    eval "$original_sh_func"
    
    # Test expectations
    assert_equal "$func_output" "$shell_marker" "Shell implementation should always be called"
    [ $exit_status -eq 0 ] || fail "_lib_msg_wrap_text() should return exit code 0"
}