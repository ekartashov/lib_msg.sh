#!/usr/bin/env bats

# This file contains tests for the _lib_msg_wrap_text() dispatcher function
# in lib_msg.sh, which chooses between AWK and pure shell implementations.

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
        
        # Use our new helper to test _lib_msg_wrap_text with its RS-delimited string output
        # This will use the default dispatcher logic (AWK if available, else shell)
        assert_wrap_text_rs "$input_text" "$width" "$expected_output"
    done
}
# --- _lib_msg_wrap_text() Dispatcher Tests ---

@test "_lib_msg_wrap_text(): dispatcher chooses awk implementation when awk is available" {
    if ! command -v awk >/dev/null 2>&1; then
        skip "awk command is not available, cannot test awk dispatch"
    fi

    # Define unique markers for stub calls
    local awk_marker="AWK_STUB_CALLED_MARKER_UNIQUE_STRING"
    local shell_marker="SHELL_STUB_CALLED_MARKER_UNIQUE_STRING"

    # Save original functions
    local original_awk_func
    original_awk_func=$(declare -f _lib_msg_wrap_text_awk)
    local original_sh_func
    original_sh_func=$(declare -f _lib_msg_wrap_text_sh)

    # Override the implementation functions directly
    _lib_msg_wrap_text_awk() {
        echo "DEBUG Test1: awk_func CALLED DIRECTLY" >&2
        echo "$awk_marker"
    }
    
    _lib_msg_wrap_text_sh() {
        echo "DEBUG Test1: shell_func CALLED DIRECTLY (UNEXPECTED)" >&2
        echo "$shell_marker"
    }
    
    # Force the dispatcher to choose the awk implementation
    export _LIB_MSG_FORCE_TEXT_WRAP_IMPL="awk"
    
    echo "DEBUG Test1: Before _lib_msg_wrap_text call. awk_marker='$awk_marker', shell_marker='$shell_marker'" >&2
    local dispatcher_output
    dispatcher_output=$(_lib_msg_wrap_text "Test text for awk dispatch" 10)
    local exit_status=$?
    echo "DEBUG Test1: After _lib_msg_wrap_text call. Exit status: $exit_status. dispatcher_output: [$dispatcher_output]" >&2

    # Restore original functions
    eval "$original_awk_func"
    eval "$original_sh_func"
    
    # Clean up environment variable
    unset _LIB_MSG_FORCE_TEXT_WRAP_IMPL
    
    # Test expectations - use direct string comparison instead of assert_output
    assert_equal "$dispatcher_output" "$awk_marker" "AWK implementation should be called with _LIB_MSG_FORCE_TEXT_WRAP_IMPL=awk"
    [ "$dispatcher_output" != "$shell_marker" ] || fail "SHELL implementation should NOT be called with _LIB_MSG_FORCE_TEXT_WRAP_IMPL=awk"
}

@test "_lib_msg_wrap_text(): dispatcher chooses shell implementation when awk is unavailable" {
    # Define unique markers for stub calls
    local awk_marker="AWK_STUB_CALLED_MARKER_UNIQUE_STRING_NOAWK" # Different marker for clarity
    local shell_marker="SHELL_STUB_CALLED_MARKER_UNIQUE_STRING_NOAWK"

    # Save original functions
    local original_awk_func
    original_awk_func=$(declare -f _lib_msg_wrap_text_awk)
    local original_sh_func
    original_sh_func=$(declare -f _lib_msg_wrap_text_sh)

    # Override the implementation functions directly
    _lib_msg_wrap_text_awk() {
        echo "DEBUG Test2: awk_func CALLED DIRECTLY (UNEXPECTED)" >&2
        echo "$awk_marker"
    }
    
    _lib_msg_wrap_text_sh() {
        echo "DEBUG Test2: shell_func CALLED DIRECTLY" >&2
        echo "$shell_marker"
    }
    
    # Force the dispatcher to choose the shell implementation
    export _LIB_MSG_FORCE_TEXT_WRAP_IMPL="sh"
    
    # Verify the environment variable is set correctly
    echo "DEBUG Test2: Environment var check: _LIB_MSG_FORCE_TEXT_WRAP_IMPL=${_LIB_MSG_FORCE_TEXT_WRAP_IMPL}" >&2
    
    echo "DEBUG Test2: Before _lib_msg_wrap_text call. awk_marker='$awk_marker', shell_marker='$shell_marker'" >&2
    local dispatcher_output
    dispatcher_output=$(_lib_msg_wrap_text "Test text for shell dispatch" 10)
    local exit_status=$?
    echo "DEBUG Test2: After _lib_msg_wrap_text call. Exit status: $exit_status. dispatcher_output: [$dispatcher_output]" >&2

    # Restore original functions
    eval "$original_awk_func"
    eval "$original_sh_func"
    
    # Clean up environment variable
    unset _LIB_MSG_FORCE_TEXT_WRAP_IMPL
    
    # Test expectations - use direct string comparison instead of assert_output
    assert_equal "$dispatcher_output" "$shell_marker" "SHELL implementation should be called with _LIB_MSG_FORCE_TEXT_WRAP_IMPL=sh"
    [ "$dispatcher_output" != "$awk_marker" ] || fail "AWK implementation should NOT be called with _LIB_MSG_FORCE_TEXT_WRAP_IMPL=sh"
}

@test "_lib_msg_wrap_text(): Shell and AWK implementations produce identical results" {
    # Skip this test if awk is not available, as we need both for comparison
    if ! command -v awk >/dev/null 2>&1; then
        skip "awk command is not available, cannot compare implementations"
    fi

    # Test cases to compare both implementations
    local test_cases=(
        "Simple text with no wrapping needed"
        "This is a longer text that will require wrapping at reasonable terminal widths"
        "Supercalifragilisticexpialidocious is a very long word that needs splitting"
        "Text with   multiple   spaces   between words"
        "Short words a b c d e f g h i j k l m n o p"
        "Text with special characters: !@#\$%^&*()_+{}[]|\\:;\"'<>,.?/"
        "Multi-line
input
with existing
line breaks"
    )
    
    local shell_output
    local awk_output

    for input_case_text in "${test_cases[@]}"; do
        for width in 10 20 40 80; do
            # Get output directly from each implementation
            shell_output=$(_lib_msg_wrap_text_sh "$input_case_text" "$width")
            awk_output=$(_lib_msg_wrap_text_awk "$input_case_text" "$width")
            
            assert_equal "$shell_output" "$awk_output" "Direct outputs differ: Shell vs AWK for input '$input_case_text' at width $width. Shell: '$shell_output', AWK: '$awk_output'"
        done
    done
    # No restoration needed as we are calling the functions directly and not modifying shared state for this test.
}