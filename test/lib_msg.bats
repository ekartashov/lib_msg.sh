#!/usr/bin/env bats

# BATS file-level setup and teardown for terminal width management
_bats_original_cols_env="" # To store original COLUMNS env var
_bats_original_stty_cols="" # To store original stty reported columns

setup_file() {
    # Store original COLUMNS env var if set
    if [ -n "${COLUMNS+x}" ]; then # Check if COLUMNS is set (even if empty)
        _bats_original_cols_env="$COLUMNS"
    fi

    # Attempt to set and get stty columns, but defensively
    if command -v stty >/dev/null && [ -t 0 ] && [ -t 1 ]; then # Check if stty exists and we have a TTY
        local _stty_output
        _stty_output=$(stty size 2>/dev/null)
        if [ -n "$_stty_output" ]; then
            _bats_original_stty_cols=${_stty_output##* }
            stty cols 80 2>/dev/null # Attempt to set to a default for tests
        fi
    fi
    # Ensure COLUMNS is set to a default for tests, overriding stty if necessary for consistency
    export COLUMNS=80
}

teardown_file() {
    # Restore original stty columns if they were captured and stty is available
    if [ -n "$_bats_original_stty_cols" ] && command -v stty >/dev/null && [ -t 0 ] && [ -t 1 ]; then
        stty cols "$_bats_original_stty_cols" 2>/dev/null
    fi

    # Restore original COLUMNS env var
    if [ -n "${_bats_original_cols_env+x}" ]; then # Check if original was set
        export COLUMNS="$_bats_original_cols_env"
    else
        unset COLUMNS # If it wasn't set originally, unset it
    fi
    unset _bats_original_cols_env
    unset _bats_original_stty_cols
}

# --- Tests for setup_file and teardown_file stty/COLUMNS logic ---

@test "setup_file/teardown_file: stty available, stty size provides columns" {
    # Local context for this test
    local _bats_original_stty_cols_local=""
    local _bats_original_cols_env_local=""
    local original_columns_value="99" # Simulate pre-existing COLUMNS

    # Assign to global vars that setup_file/teardown_file use
    _bats_original_stty_cols="$_bats_original_stty_cols_local"
    _bats_original_cols_env="$_bats_original_cols_env_local"
    export COLUMNS="$original_columns_value"

    stub command "-v stty : exit 0" # stty is available
    stub '[' \
        "-t 0 : exit 0" \        # is a TTY
        "-t 1 : exit 0"          # is a TTY

    stub stty \
        "size : echo 'ignored_rows 120'" \
        "cols 80 : true" \
        "cols 120 : true"

    setup_file

    assert_equal "$_bats_original_stty_cols" "120" "Original stty cols should be captured"
    assert_equal "$_bats_original_cols_env" "$original_columns_value" "Original COLUMNS env should be captured"
    assert_equal "$COLUMNS" "80" "COLUMNS should be set to 80 by setup_file"

    # Now test teardown_file
    teardown_file

    assert_equal "$COLUMNS" "$original_columns_value" "COLUMNS should be restored"
    # _bats_original_stty_cols and _bats_original_cols_env are unset by teardown_file
    assert_equal "$_bats_original_stty_cols" "" "_bats_original_stty_cols should be unset"
    assert_equal "$_bats_original_cols_env" "" "_bats_original_cols_env should be unset"

    unstub command
    unstub '['
    unstub stty
    # Restore COLUMNS just in case, though teardown_file should handle it
    if [ -n "${original_columns_value+x}" ]; then export COLUMNS="$original_columns_value"; else unset COLUMNS; fi
}

@test "setup_file/teardown_file: stty available, stty size returns empty" {
    _bats_original_stty_cols=""
    _bats_original_cols_env=""
    export COLUMNS="99" # Pre-existing

    stub command "-v stty : exit 0"
    stub '[' "-t 0 : exit 0" "-t 1 : exit 0"
    stub stty "size : echo ''" # stty size returns nothing

    setup_file

    assert_equal "$_bats_original_stty_cols" "" "Original stty cols should be empty"
    assert_equal "$_bats_original_cols_env" "99"
    assert_equal "$COLUMNS" "80"

    # Teardown should not call 'stty cols ""'
    # We ensure no 'stty cols' with a non-empty arg was defined in the stub for restoration
    # If 'stty cols ""' were called, it would be an error or require a specific stub.
    # The existing 'stty' stub only has "size : echo ''". If other 'stty' calls happen, the test fails.
    teardown_file

    assert_equal "$COLUMNS" "99"
    assert_equal "$_bats_original_stty_cols" ""
    assert_equal "$_bats_original_cols_env" ""

    unstub command
    unstub '['
    unstub stty
    export COLUMNS="99"
}

@test "setup_file/teardown_file: stty command not available" {
    _bats_original_stty_cols=""
    _bats_original_cols_env=""
    export COLUMNS="99"

    stub command "-v stty : exit 1" # stty not available
    # '[' and 'stty' stubs not needed as the condition for them won't be met

    setup_file

    assert_equal "$_bats_original_stty_cols" "" "Original stty cols should be empty"
    assert_equal "$_bats_original_cols_env" "99"
    assert_equal "$COLUMNS" "80"

    teardown_file # Should not attempt stty operations

    assert_equal "$COLUMNS" "99"
    assert_equal "$_bats_original_stty_cols" ""
    assert_equal "$_bats_original_cols_env" ""

    unstub command
    export COLUMNS="99"
}

@test "setup_file/teardown_file: not a TTY" {
    _bats_original_stty_cols=""
    _bats_original_cols_env=""
    export COLUMNS="99"

    stub command "-v stty : exit 0" # stty is available
    stub '[' \
        "-t 0 : exit 1" \        # Not a TTY (stdin)
        "-t 1 : exit 0"          # stdout is TTY (doesn't matter if first fails)
    # Or: stub '[' "-t 0 : exit 0" "-t 1 : exit 1"

    setup_file

    assert_equal "$_bats_original_stty_cols" "" "Original stty cols should be empty as not a TTY"
    assert_equal "$_bats_original_cols_env" "99"
    assert_equal "$COLUMNS" "80"

    teardown_file # Should not attempt stty operations

    assert_equal "$COLUMNS" "99"
    assert_equal "$_bats_original_stty_cols" ""
    assert_equal "$_bats_original_cols_env" ""

    unstub command
    unstub '['
    export COLUMNS="99"
}

# Load BATS support and assertion libraries
load 'libs/bats-support/load'
load 'libs/bats-assert/load'
load 'libs/bats-mock/stub.bash'
load 'helpers/lib_msg_test_helpers.bash'

# Load the library to be tested
# BATS_TEST_DIRNAME is the directory where the .bats file is located.
# shellcheck source=../lib_msg.sh
load '../lib_msg.sh'

setup() {
    # Mock SCRIPT_NAME for consistent prefix in tests
    SCRIPT_NAME="test_script.sh"
    # Helpers like simulate_tty_conditions will handle TTY state and library re-initialization.
}

teardown() {
    unset -f script_to_run_die_return 2>/dev/null
    unset -f script_to_run_die_return_no_code 2>/dev/null
    unset -f script_to_run_die_return_invalid_code 2>/dev/null
    unstub '[' 2>/dev/null # Ensure '[' is unstubbed if used
}

@test "err() prints message to stderr with colored 'E:' prefix and newline (simulated TTY for stderr)" {
    # stdout not TTY (exit 1), stderr is TTY (exit 0)
    simulate_tty_conditions 1 0

    run err 'This is an error message' 1>/dev/null

    assert_success
    assert_line --index 0 "test_script.sh: $(printf '\e')[0;31mE:$(printf '\e')[0m This is an error message"
    unstub '['
}

@test "err() prints plain message to stderr if not TTY (simulated no TTY for stderr)" {
    # stdout not TTY (exit 1), stderr not TTY (exit 1)
    simulate_tty_conditions 1 1

    run err 'Plain error' 1>/dev/null
    assert_success
    assert_line --index 0 "test_script.sh: E: Plain error"
    unstub '['
}

@test "errn() prints message to stderr with colored 'E:' prefix and no newline (simulated TTY for stderr)" {
    # stdout not TTY (exit 1), stderr is TTY (exit 0)
    simulate_tty_conditions 1 0

    run errn 'Error no newline' 1>/dev/null
    assert_success
    assert_output "test_script.sh: $(printf '\e')[0;31mE:$(printf '\e')[0m Error no newline"
    unstub '['
}

@test "warn() prints message to stderr with colored 'W:' prefix and newline (simulated TTY for stderr)" {
    # stdout not TTY (exit 1), stderr is TTY (exit 0)
    simulate_tty_conditions 1 0

    run warn 'This is a warning message' 1>/dev/null
    assert_success
    assert_line --index 0 "test_script.sh: $(printf '\e')[0;33mW:$(printf '\e')[0m This is a warning message"
    unstub '['
}

@test "warn() prints plain message to stderr if not TTY (simulated no TTY for stderr)" {
    # stdout not TTY (exit 1), stderr not TTY (exit 1)
    simulate_tty_conditions 1 1

    run warn 'Plain warning' 1>/dev/null
    assert_success
    assert_line --index 0 "test_script.sh: W: Plain warning"
    unstub '['
}

@test "warnn() prints message to stderr with colored 'W:' prefix and no newline (simulated TTY for stderr)" {
    # stdout not TTY (exit 1), stderr is TTY (exit 0)
    simulate_tty_conditions 1 0

    run warnn 'Warning no newline' 1>/dev/null
    assert_success
    assert_output "test_script.sh: $(printf '\e')[0;33mW:$(printf '\e')[0m Warning no newline"
    unstub '['
}

@test "msg() prints message to stdout with prefix and newline (simulated no TTY for stdout)" {
    # stdout not TTY (exit 1), stderr not TTY (exit 1)
    simulate_tty_conditions 1 1

    run msg 'This is a general message' 2>/dev/null
    assert_success
    assert_line --index 0 "test_script.sh: This is a general message"
    unstub '['
}

@test "msgn() prints message to stdout with prefix and no newline (simulated no TTY for stdout)" {
    # stdout not TTY (exit 1), stderr not TTY (exit 1)
    simulate_tty_conditions 1 1

    run msgn 'This is a general message without newline' 2>/dev/null
    assert_success
    assert_output "test_script.sh: This is a general message without newline"
    unstub '['
}

@test "info() prints message to stdout with colored 'I:' prefix and newline (simulated TTY for stdout)" {
    # stdout is TTY (exit 0), stderr not TTY (exit 1)
    simulate_tty_conditions 0 1

    run info 'This is an info message' 2>/dev/null
    assert_success
    assert_line --index 0 "test_script.sh: $(printf '\e')[0;34mI:$(printf '\e')[0m This is an info message"
    unstub '['
}

@test "info() prints plain message to stdout if not TTY (simulated no TTY for stdout)" {
    # stdout not TTY (exit 1), stderr not TTY (exit 1)
    simulate_tty_conditions 1 1

    run info 'Plain info' 2>/dev/null
    assert_success
    assert_line --index 0 "test_script.sh: I: Plain info"
    unstub '['
}

@test "infon() prints message to stdout with colored 'I:' prefix and no newline (simulated TTY for stdout)" {
    # stdout is TTY (exit 0), stderr not TTY (exit 1)
    simulate_tty_conditions 0 1

    run infon 'Info no newline' 2>/dev/null
    assert_success
    assert_output "test_script.sh: $(printf '\e')[0;34mI:$(printf '\e')[0m Info no newline"
    unstub '['
}

@test "die() prints message to stderr, colored 'E:', and exits with given code (when not sourced, simulated TTY)" {
    # Mock TTY: stderr is TTY
    stub '[' "-t 2 : exit 0"
    run bash -c "source ./lib_msg.sh; SCRIPT_NAME='test_script.sh'; _LIB_MSG_STDERR_IS_TTY=''; _lib_msg_init_detection; _lib_msg_init_colors; die 123 'Fatal error, exiting' 1>/dev/null"
    assert_failure 123
    assert_line --index 0 "test_script.sh: $(printf '\e')[0;31mE:$(printf '\e')[0m Fatal error, exiting"
    unstub '['
}

@test "die() prints message to stderr, plain 'E:', and exits with given code (when not sourced, simulated no TTY)" {
    # Mock TTY: stderr is not TTY
    stub '[' "-t 2 : exit 1"
    run bash -c "source ./lib_msg.sh; SCRIPT_NAME='test_script.sh'; _LIB_MSG_STDERR_IS_TTY=''; _lib_msg_init_detection; _lib_msg_init_colors; die 123 'Fatal error, exiting plain' 1>/dev/null"
    assert_failure 123
    assert_line --index 0 "test_script.sh: E: Fatal error, exiting plain"
    unstub '['
}

@test "die() prints message and exits with 1 if no code provided (when not sourced, simulated TTY)" {
    stub '[' "-t 2 : exit 0"
    run bash -c "source ./lib_msg.sh; SCRIPT_NAME='test_script.sh'; _LIB_MSG_STDERR_IS_TTY=''; _lib_msg_init_detection; _lib_msg_init_colors; die 'Implicit error code' 1>/dev/null"
    assert_failure 1
    assert_line --index 0 "test_script.sh: $(printf '\e')[0;31mE:$(printf '\e')[0m Implicit error code"
    unstub '['
}

@test "die() prints message and exits with 1 if invalid code 'invalid' provided (when not sourced, simulated TTY)" {
    stub '[' "-t 2 : exit 0"
    run bash -c "source ./lib_msg.sh; SCRIPT_NAME='test_script.sh'; _LIB_MSG_STDERR_IS_TTY=''; _lib_msg_init_detection; _lib_msg_init_colors; die 'invalid' 'Error with invalid code' 1>/dev/null"
    assert_failure 1
    assert_line --index 0 "test_script.sh: $(printf '\e')[0;31mE:$(printf '\e')[0m invalid Error with invalid code"
    unstub '['
}

@test "die() prints message and exits with 1 if invalid code '-5' provided (when not sourced, simulated TTY)" {
    stub '[' "-t 2 : exit 0"
    run bash -c "source ./lib_msg.sh; SCRIPT_NAME='test_script.sh'; _LIB_MSG_STDERR_IS_TTY=''; _lib_msg_init_detection; _lib_msg_init_colors; die '-5' 'Error with negative code' 1>/dev/null"
    assert_failure 1
    assert_line --index 0 "test_script.sh: $(printf '\e')[0;31mE:$(printf '\e')[0m -5 Error with negative code"
    unstub '['
}

@test "die() prints message to stderr, colored 'E:', and returns with given code (when sourced/in function, simulated TTY)" {
    # Note: simulate_tty_conditions will handle stubbing '['
    script_to_run_die_return() {
        source ./lib_msg.sh # Source the main library
        # shellcheck source=./helpers/lib_msg_test_helpers.bash
        source "${BATS_TEST_DIRNAME}/helpers/lib_msg_test_helpers.bash" # Source helpers for simulate_tty_conditions

        SCRIPT_NAME="test_script.sh"
        simulate_tty_conditions 1 0 # stdout not TTY, stderr is TTY

        my_func() {
            die 77 "Returning from function"
            local _die_status=$?
            echo "my_func status: $_die_status" >&3
            return "$_die_status"
        }
        my_func
        return $?
    }
    export -f script_to_run_die_return
    run bash -c "script_to_run_die_return 1>/dev/null"

    assert_failure 77
    assert_line --index 0 "test_script.sh: $(printf '\e')[0;31mE:$(printf '\e')[0m Returning from function"
    unstub '[' # simulate_tty_conditions stubs '[', so we unstub it here
}

@test "die() returns 1 if no code provided (when sourced/in function, simulated TTY)" {
    script_to_run_die_return_no_code() {
        source ./lib_msg.sh
        # shellcheck source=./helpers/lib_msg_test_helpers.bash
        source "${BATS_TEST_DIRNAME}/helpers/lib_msg_test_helpers.bash"

        SCRIPT_NAME="test_script.sh"
        simulate_tty_conditions 1 0 # stdout not TTY, stderr is TTY

        my_func_no_code() {
            die "Returning with implicit code"
        }
        my_func_no_code
        return $?
    }
    export -f script_to_run_die_return_no_code
    run bash -c "script_to_run_die_return_no_code 1>/dev/null"
    assert_failure 1
    assert_line --index 0 "test_script.sh: $(printf '\e')[0;31mE:$(printf '\e')[0m Returning with implicit code"
    unstub '['
}

@test "die() returns 1 if invalid code 'invalid' provided (when sourced/in function, simulated TTY)" {
    script_to_run_die_return_invalid_code() {
        source ./lib_msg.sh
        # shellcheck source=./helpers/lib_msg_test_helpers.bash
        source "${BATS_TEST_DIRNAME}/helpers/lib_msg_test_helpers.bash"

        SCRIPT_NAME="test_script.sh"
        simulate_tty_conditions 1 0 # stdout not TTY, stderr is TTY

        my_func_invalid_code() {
            die "invalid" "Returning with invalid code"
        }
        my_func_invalid_code
        return $?
    }
    export -f script_to_run_die_return_invalid_code
    run bash -c "script_to_run_die_return_invalid_code 1>/dev/null"
    assert_failure 1
    assert_line --index 0 "test_script.sh: $(printf '\e')[0;31mE:$(printf '\e')[0m invalid Returning with invalid code"
    unstub '['
}

@test "Prefix uses 'lib_msg.sh' if SCRIPT_NAME is unset (simulated no TTY)" {
    # Mock TTY: stdout not TTY, stderr not TTY
    stub '[' \
        "-t 1 : exit 1" \
        "-t 2 : exit 1"

    # Force re-initialization of TTY detection and colors with mocked environment
    # SCRIPT_NAME is unset inside the bash -c command
    run bash -c "source ./lib_msg.sh; unset SCRIPT_NAME; _LIB_MSG_STDOUT_IS_TTY=''; _LIB_MSG_STDERR_IS_TTY=''; _lib_msg_init_detection; _lib_msg_init_colors; msg 'Testing SCRIPT_NAME fallback' 2>/dev/null"
    assert_success
    assert_line --index 0 "lib_msg.sh: Testing SCRIPT_NAME fallback"
    unstub '['
}

# --- Tests for Internal Library Functions ---

@test "_lib_msg_init_detection(): detects no TTYs and COLUMNS=60" {
    # Mock '[' behavior:
    # First call for `[ -t 1 ]` (stdout) -> fail (not a TTY)
    # Second call for `[ -t 2 ]` (stderr) -> fail (not a TTY)
    stub '[' \
        "-t 1 : exit 1" \
        "-t 2 : exit 1"

    # Set COLUMNS and call detection
    COLUMNS=60 # Explicitly set for this test
    _lib_msg_init_detection

    assert_equal "$_LIB_MSG_STDOUT_IS_TTY" "false" "stdout TTY flag"
    assert_equal "$_LIB_MSG_STDERR_IS_TTY" "false" "stderr TTY flag"
    assert_equal "$_LIB_MSG_TERMINAL_WIDTH" 0 "Terminal width should be 0 when no TTY"
    unstub '['
}

@test "_lib_msg_init_detection(): detects stdout TTY, stderr not TTY, COLUMNS=120" {
    stub '[' \
        "-t 1 : exit 0" \
        "-t 2 : exit 1"

    COLUMNS=120 # Explicitly set
    _lib_msg_init_detection

    assert_equal "$_LIB_MSG_STDOUT_IS_TTY" "true" "stdout TTY flag"
    assert_equal "$_LIB_MSG_STDERR_IS_TTY" "false" "stderr TTY flag"
    assert_equal "$_LIB_MSG_TERMINAL_WIDTH" 120 "Terminal width"
    unstub '['
}

@test "_lib_msg_init_detection(): detects stdout not TTY, stderr TTY, COLUMNS undefined" {
    stub '[' \
        "-t 1 : exit 1" \
        "-t 2 : exit 0"

    local original_cols_setup_file="$COLUMNS" # Preserve file-level default
    unset COLUMNS # Ensure COLUMNS is not set for this specific test
    _lib_msg_init_detection

    assert_equal "$_LIB_MSG_STDOUT_IS_TTY" "false" "stdout TTY flag"
    assert_equal "$_LIB_MSG_STDERR_IS_TTY" "true" "stderr TTY flag"
    assert_equal "$_LIB_MSG_TERMINAL_WIDTH" 0 "Terminal width should be 0 when COLUMNS undefined"
    unstub '['
    export COLUMNS="$original_cols_setup_file" # Restore file-level default
}

@test "_lib_msg_init_detection(): detects both TTYs, COLUMNS=80 (default)" {
    stub '[' \
        "-t 1 : exit 0" \
        "-t 2 : exit 0"

    COLUMNS=80 # Explicitly set to default for clarity
    _lib_msg_init_detection

    assert_equal "$_LIB_MSG_STDOUT_IS_TTY" "true" "stdout TTY flag"
    assert_equal "$_LIB_MSG_STDERR_IS_TTY" "true" "stderr TTY flag"
    assert_equal "$_LIB_MSG_TERMINAL_WIDTH" 80 "Terminal width"
    unstub '['
}

@test "_lib_msg_init_detection(): detects both TTYs, COLUMNS invalid" {
    stub '[' \
        "-t 1 : exit 0" \
        "-t 2 : exit 0"

    COLUMNS="abc" # Invalid value
    _lib_msg_init_detection

    assert_equal "$_LIB_MSG_STDOUT_IS_TTY" "true" "stdout TTY flag"
    assert_equal "$_LIB_MSG_STDERR_IS_TTY" "true" "stderr TTY flag"
    assert_equal "$_LIB_MSG_TERMINAL_WIDTH" 0 "Terminal width should be 0 for invalid COLUMNS"
    unstub '['
}

@test "_lib_msg_init_colors(): enables colors if stdout is TTY (simulated)" {
    # stdout TTY (0), stderr not TTY (1)
    simulate_tty_conditions 0 1
    # simulate_tty_conditions already calls _lib_msg_init_detection and _lib_msg_init_colors

    # We need to ensure _LIB_MSG_CLR_RED was set by _lib_msg_init_colors
    # If it was cleared before simulate_tty_conditions, it should now be populated.
    # For robustness, let's check its expected value directly.
    assert_equal "$_LIB_MSG_CLR_RED" "$(printf '\033[0;31m')" "Red color code"
    assert_equal "$_LIB_MSG_CLR_RESET" "$(printf '\033[0m')" "Reset color code"
    unstub '['
}

@test "_lib_msg_init_colors(): enables colors if stderr is TTY (simulated)" {
    # stdout not TTY (1), stderr TTY (0)
    simulate_tty_conditions 1 0

    assert_equal "$_LIB_MSG_CLR_YELLOW" "$(printf '\033[0;33m')" "Yellow color code"
    assert_equal "$_LIB_MSG_CLR_RESET" "$(printf '\033[0m')" "Reset color code"
    unstub '['
}

@test "_lib_msg_init_colors(): disables colors if no TTY (simulated)" {
    # No TTYs: stdout not TTY (1), stderr not TTY (1)
    simulate_tty_conditions 1 1
    
    # Explicitly set to dummy values before calling simulate_tty_conditions to ensure it clears them
    # This is tricky because simulate_tty_conditions does its own init.
    # Instead, we just check that they are empty after simulate_tty_conditions runs.
    assert_equal "$_LIB_MSG_CLR_GREEN" "" "Green color code should be empty"
    assert_equal "$_LIB_MSG_CLR_RESET" "" "Reset color code should be empty"
    unstub '['
}

# --- Tests for _lib_msg_colorize ---
@test "_lib_msg_colorize: no color if not TTY (simulated)" {
    # stdout not TTY (1), stderr not TTY (1)
    simulate_tty_conditions 1 1
    # simulate_tty_conditions ensures color vars are empty

    run _lib_msg_colorize "text" "$_LIB_MSG_CLR_RED" "$_LIB_MSG_STDOUT_IS_TTY"
    assert_success
    assert_output "text"
    unstub '['
}

@test "_lib_msg_colorize: no color if color code is empty (simulated TTY)" {
    # stdout TTY (0), stderr not TTY (1)
    simulate_tty_conditions 0 1
    # Colors will be initialized by simulate_tty_conditions, but we pass an empty one to _lib_msg_colorize

    run _lib_msg_colorize "text" "" "$_LIB_MSG_STDOUT_IS_TTY"
    assert_success
    assert_output "text"
    unstub '['
}

@test "_lib_msg_colorize: applies color if TTY and color code provided (simulated TTY)" {
    # stdout TTY (0), stderr not TTY (1)
    simulate_tty_conditions 0 1
    # This will populate _LIB_MSG_CLR_GREEN and _LIB_MSG_CLR_RESET via simulate_tty_conditions

    run _lib_msg_colorize "text" "$_LIB_MSG_CLR_GREEN" "$_LIB_MSG_STDOUT_IS_TTY"
    assert_success
    assert_output "$(printf '\e')[0;32mtext$(printf '\e')[0m"
    unstub '['
}

# --- Tests for _lib_msg_wrap_text (Direct Text Wrapping Logic) ---
@test "_lib_msg_wrap_text: parameterized tests" {
    # Define test cases: "description;input_text;width;expected_line1;expected_line2;..."
    # Note: An empty expected line should be represented by an empty field (e.g., ...;expected_line1;;expected_line3;...)
    local wrap_text_test_cases=(
        "No wrapping if width is 0;This is a test sentence.;0;This is a test sentence."
        "No wrapping if text is shorter than width;Short text.;20;Short text."
        "Wraps simple text;This is a slightly longer sentence that should wrap.;20;This is a slightly;longer sentence that;should wrap."
        "Handles empty string input;;20;" # Expected: one empty line
        "Handles long word that needs splitting;Thisisaverylongwordthatcannotfit;10;Thisisaver;ylongwordt;hatcannotf;it"
        "Handles long word at start of new line after wrap;Short then Thisisaverylongwordthatcannotfit;10;Short then;Thisisaver;ylongwordt;hatcannotf;it"
        "Handles multiple spaces between words;Word1  Word2   Word3;10;Word1;Word2;Word3" # Current POSIX-compliant behavior skips extra spaces
        "Diagnostic test message;Diagnostic test message;20;Diagnostic test;message"
        "Width exactly fits a word;fit;3;fit"
        "Width one less than a word;toolong;6;toolon;g"
        "Text with leading/trailing spaces;  leading and trailing spaces  ;20;leading and trailing;spaces" # read in _lib_msg_wrap_text trims these
        "Text with only spaces;     ;10;" # read in _lib_msg_wrap_text results in empty input effectively
    )

    local test_idx=0
    for test_case_str in "${wrap_text_test_cases[@]}"; do
        ((test_idx++))
        # Parse the test case string
        local old_ifs="$IFS"
        IFS=';'
        # shellcheck disable=SC2206 # Word splitting is desired here
        local params=($test_case_str)
        IFS="$old_ifs"

        local description="${params[0]}"
        local input_text="${params[1]}"
        local width="${params[2]}"

        local expected_lines_array=()
        # Loop from index 3 to the end of params array for expected lines
        if [ "${#params[@]}" -gt 3 ]; then
            for (( i=3; i<${#params[@]}; i++ )); do
                expected_lines_array+=("${params[i]}")
            done
        elif [ "${#params[@]}" -eq 3 ]; then # Case like "description;input;width;" expecting one empty line
             # This case is actually covered if the string is "desc;in;w;" -> params[3] is empty string
             # If string is "desc;in;w" -> #params is 3, means no expected lines listed, which is an error in test case def.
             # For safety, let's assume if #params is 3, it means the test case string was like "desc;in;width" (missing trailing ;)
             # and it implies a single line output equal to input_text if width is 0, or an error in test case.
             # The current test cases always provide at least one expected line field (even if empty).
             # "Handles empty string input;;20;" -> params[3] is "", so expected_lines_array gets one empty string. Correct.
             # "Text with only spaces;     ;10;" -> params[3] is "", expected_lines_array gets one empty string. Correct.
             : # Covered by the loop logic if params[3] exists (even if empty)
        fi


        # Run the function under test. It populates the global 'lines' array.
        # The `run` command is not used here as we are testing a shell function directly
        # and inspecting an array it populates, not its stdout.
        _lib_msg_wrap_text "$input_text" "$width"
        # `_lib_msg_wrap_text` sets the `lines` array globally.

        assert_equal "${#lines[@]}" "${#expected_lines_array[@]}" "Test Case $test_idx ('$description'): Number of lines mismatch. Expected ${#expected_lines_array[@]}, Got ${#lines[@]}"

        for i in $(seq 0 $((${#expected_lines_array[@]} - 1))); do
            assert_equal "${lines[$i]}" "${expected_lines_array[$i]}" "Test Case $test_idx ('$description'): Line $((i+1)) mismatch. Expected '${expected_lines_array[$i]}', Got '${lines[$i]}'"
        done
    done
}

# --- Tests for Message Wrapping with Prefixes (SCRIPT_NAME and tags) ---

@test "info() wraps message correctly considering SCRIPT_NAME and 'I:' prefix (simulated TTY for stdout, width 40)" {
    ( # Start subshell to localize SCRIPT_NAME and COLUMNS changes
        SCRIPT_NAME="test_wrap.sh"
        export COLUMNS=40
        simulate_tty_conditions 0 1 # stdout TTY, stderr not TTY

        run info 'This is a long informational message that should definitely wrap onto multiple lines.' 2>/dev/null
        
        assert_success
        local pfx="test_wrap.sh: $(printf '\e')[0;34mI:$(printf '\e')[0m "
        local expected_output="${pfx}This is a long
                 informational message
                 that should definitely
                 wrap onto multiple
                 lines."
        assert_multiline_output "$expected_output"
    )
    unstub '['
}

@test "err() wraps message correctly considering SCRIPT_NAME and 'E:' prefix (simulated TTY for stderr, width 35)" {
    (
        SCRIPT_NAME="err_wrap.sh"
        export COLUMNS=35
        simulate_tty_conditions 1 0 # stdout not TTY, stderr TTY

        run err 'This is a critical error that must wrap appropriately.' 1>/dev/null
        
        assert_success
        local pfx="err_wrap.sh: $(printf '\e')[0;31mE:$(printf '\e')[0m "
        local expected_output="${pfx}This is a critical
                error that must
                wrap appropriately."
        assert_multiline_output "$expected_output"
    )
    unstub '['
}

@test "warn() wraps message correctly considering SCRIPT_NAME and 'W:' prefix (simulated TTY for stderr, width 50)" {
    (
        SCRIPT_NAME="warn_script_long_name.sh"
        export COLUMNS=50
        simulate_tty_conditions 1 0 # stdout not TTY, stderr TTY

        run warn 'A somewhat lengthy warning message to test the wrapping functionality with prefixes.' 1>/dev/null
        
        assert_success
        local pfx="warn_script_long_name.sh: $(printf '\e')[0;33mW:$(printf '\e')[0m "
        local expected_output="${pfx}A somewhat lengthy
                             warning message to
                             test the wrapping
                             functionality with
                             prefixes."
        assert_multiline_output "$expected_output"
    )
    unstub '['
}

@test "msg() wraps message correctly considering SCRIPT_NAME (simulated TTY for stdout, width 30, no specific tag)" {
    (
        SCRIPT_NAME="msg_wrap.sh"
        export COLUMNS=30
        # stdout TTY (0) for width detection, stderr not TTY (1)
        simulate_tty_conditions 0 1

        run msg 'Plain message testing wrapping with script name only.' 2>/dev/null
        
        assert_success
        local pfx="msg_wrap.sh: "
        local expected_output="${pfx}Plain message
             testing wrapping
             with script name
             only."
        assert_multiline_output "$expected_output"
    )
    unstub '['
}

@test "info() does not wrap if width is too small for prefix (simulated TTY for stdout, width 15)" {
    (
        SCRIPT_NAME="short.sh"
        export COLUMNS=15
        simulate_tty_conditions 0 1 # stdout TTY, stderr not TTY

        run info 'This message will not be wrapped, prefix too long.' 2>/dev/null
        
        assert_success
        local pfx="short.sh: $(printf '\e')[0;34mI:$(printf '\e')[0m "
        # For single line output, assert_line is fine, or assert_multiline_output with a single line
        assert_line --index 0 "${pfx}This message will not be wrapped, prefix too long."
        assert_equal "${#lines[@]}" 1 # Ensure it's indeed a single line
    )
    unstub '['
}

# More advanced tests would involve mocking TTY detection and COLUMNS
# to test wrapping and coloring under different terminal conditions.

# Example for testing a colored message (assuming TTY and colors are enabled)
# This requires a way to enable TTY mode for the test or mock it.
# For now, these will likely fail or show plain text in a non-TTY CI.
# @test "msg_red() prints red message (if TTY)" {
#     # This test needs careful setup to simulate TTY and color support
#     # One way: SCRIPT_NAME="test_script.sh" _LIB_MSG_STDOUT_IS_TTY="true" _LIB_MSG_CLR_RED="\033[0;31m" _LIB_MSG_CLR_RESET="\033[0m" run msg_red "Red message"
#     # The above `run` won't work directly because env vars for run are tricky with functions.
#     # A subshell is better:
#     run bash -c ". ./lib_msg.sh; SCRIPT_NAME='test_script.sh'; _LIB_MSG_STDOUT_IS_TTY='true'; _lib_msg_init_colors; msg_red 'Red message' 2>/dev/null"
#     [ "$status" -eq 0 ]
#     # Expected output would be "test_script.sh: \033[0;31mRed message\033[0m"
#     # Bats might strip colors, or output might be hard to match exactly.
#     # Check for substring:
#     [[ "$output" == *"test_script.sh: "* ]]
#     [[ "$output" == *"\033[0;31mRed message\033[0m"* ]] # This will fail if bats strips colors
# }

# All original TODO items have been addressed by the refactoring.
