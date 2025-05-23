#!/usr/bin/env bats

# BATS file-level setup and teardown for terminal width management
# These variables are used by the terminal management helpers in lib_msg_test_helpers.bash
_bats_saved_stty_cols=""
_bats_saved_columns_env=""

# Load BATS support and assertion libraries
load "libs/bats-support/load"
load "libs/bats-assert/load"
load "libs/bats-mock/stub.bash" # Though not directly used by setup_file/teardown_file, good to have

# Load our test helpers
load "test_helpers.bash"

# Load the library to be tested (needed for _lib_msg_test_save_terminal_settings etc. from helpers)
# shellcheck source=../lib_msg.sh
load "../lib_msg.sh"

setup_file() {
    echo "setup_file: Checking conditions via environment variables..." >&3
    echo "setup_file: command -v stty exit code: $(command -v stty >/dev/null; echo $?)" >&3
    echo "setup_file: _BATS_TEST_STDIN_IS_TTY='$_BATS_TEST_STDIN_IS_TTY', resolved stdin_is_tty='$([ "$_BATS_TEST_STDIN_IS_TTY" = "true" ] && echo true || echo false)'" >&3
    echo "setup_file: _BATS_TEST_STDOUT_IS_TTY='$_BATS_TEST_STDOUT_IS_TTY', resolved stdout_is_tty='$([ "$_BATS_TEST_STDOUT_IS_TTY" = "true" ] && echo true || echo false)'" >&3

    # Default TTY vars to false if not set
    if [ -z "$_BATS_TEST_STDIN_IS_TTY" ]; then
        export _BATS_TEST_STDIN_IS_TTY="false"
    fi
    
    if [ -z "$_BATS_TEST_STDOUT_IS_TTY" ]; then
        export _BATS_TEST_STDOUT_IS_TTY="false"
    fi

    # Save current terminal settings - don't fail if this fails
    _lib_msg_test_save_terminal_settings || true
    
    # Set terminal width to a standard value for tests
    _lib_msg_test_set_terminal_width 80
}

teardown_file() {
    # Restore previously saved terminal settings
    _lib_msg_test_restore_terminal_settings
}

# --- Tests for setup_file and teardown_file stty/COLUMNS logic ---

@test "setup_file/teardown_file: stty available, stty size provides columns" {
    # Local context for this test
    local _bats_saved_stty_cols_local=""
    local _bats_saved_columns_env_local=""
    local original_columns_value="99" # Simulate pre-existing COLUMNS

    # Set mock output for stty size
    export LIB_MSG_TEST_STTY_SIZE_OUTPUT="120"
    
    # Assign to global vars that setup_file/teardown_file use
    _bats_saved_stty_cols="$_bats_saved_stty_cols_local"
    _bats_saved_columns_env="$_bats_saved_columns_env_local"
    export COLUMNS="$original_columns_value"
    export _BATS_TEST_STDIN_IS_TTY="true"
    export _BATS_TEST_STDOUT_IS_TTY="true"

    setup_file

    assert_equal "$_bats_saved_stty_cols" "120" "Original stty cols should be captured"
    assert_equal "$_bats_saved_columns_env" "$original_columns_value" "Original COLUMNS env should be captured"
    assert_equal "$COLUMNS" "80" "COLUMNS should be set to 80 by setup_file"

    # Now test teardown_file
    # teardown_file will use _BATS_TEST_STDIN_IS_TTY and _BATS_TEST_STDOUT_IS_TTY
    # which are already set to "true" earlier in this test.
    teardown_file # Direct call

    assert_equal "$COLUMNS" "$original_columns_value" "COLUMNS should be restored"
    # _bats_saved_stty_cols and _bats_saved_columns_env are unset by teardown_file
    assert_equal "$_bats_saved_stty_cols" "" "_bats_saved_stty_cols should be unset"
    assert_equal "$_bats_saved_columns_env" "" "_bats_saved_columns_env should be unset"

    # Clean up
    unset LIB_MSG_TEST_STTY_SIZE_OUTPUT
    # Restore COLUMNS just in case, though teardown_file should handle it
    if [ -n "${original_columns_value+x}" ]; then export COLUMNS="$original_columns_value"; else unset COLUMNS; fi
    unset _BATS_TEST_STDIN_IS_TTY _BATS_TEST_STDOUT_IS_TTY
}

@test "setup_file/teardown_file: stty available, stty size returns empty" {
    # Local context for this test
    local _bats_saved_stty_cols_local=""
    local _bats_saved_columns_env_local=""
    local original_columns_value="99" # Simulate pre-existing COLUMNS

    # Set mock for stty size to be empty but exit success
    export LIB_MSG_TEST_STTY_SIZE_OUTPUT=""
    
    # Assign to global vars that setup_file/teardown_file use
    _bats_saved_stty_cols="$_bats_saved_stty_cols_local"
    _bats_saved_columns_env="$_bats_saved_columns_env_local"
    export COLUMNS="$original_columns_value"
    export _BATS_TEST_STDIN_IS_TTY="true"
    export _BATS_TEST_STDOUT_IS_TTY="true"

    setup_file

    assert_equal "$_bats_saved_stty_cols" "" "Original stty cols should be empty"
    assert_equal "$_bats_saved_columns_env" "$original_columns_value" "Original COLUMNS env should be captured"
    assert_equal "$COLUMNS" "80" "COLUMNS should be set to 80 by setup_file"

    # Teardown should not call 'stty cols ""' when saved cols is empty
    teardown_file

    assert_equal "$COLUMNS" "$original_columns_value" "COLUMNS should be restored"
    assert_equal "$_bats_saved_stty_cols" "" "_bats_saved_stty_cols should be unset"
    assert_equal "$_bats_saved_columns_env" "" "_bats_saved_columns_env should be unset"

    # Clean up
    unset LIB_MSG_TEST_STTY_SIZE_OUTPUT
    # Restore COLUMNS just in case, though teardown_file should handle it
    if [ -n "${original_columns_value+x}" ]; then export COLUMNS="$original_columns_value"; else unset COLUMNS; fi
    unset _BATS_TEST_STDIN_IS_TTY _BATS_TEST_STDOUT_IS_TTY
}

@test "setup_file/teardown_file: stty command not available" {
    # Local context for this test
    local _bats_saved_stty_cols_local=""
    local _bats_saved_columns_env_local=""
    local original_columns_value="99" # Simulate pre-existing COLUMNS

    # Assign to global vars that setup_file/teardown_file use
    _bats_saved_stty_cols="$_bats_saved_stty_cols_local"
    _bats_saved_columns_env="$_bats_saved_columns_env_local"
    export COLUMNS="$original_columns_value"
    
    # Set TTY environment vars if needed for completeness
    export _BATS_TEST_STDIN_IS_TTY="true"
    export _BATS_TEST_STDOUT_IS_TTY="true"

    # Simulate stty unavailable
    export LIB_MSG_TEST_STTY_UNAVAILABLE="true"

    setup_file

    assert_equal "$_bats_saved_stty_cols" "" "Original stty cols should be empty when stty unavailable"
    assert_equal "$_bats_saved_columns_env" "$original_columns_value" "Original COLUMNS env should be captured"
    assert_equal "$COLUMNS" "80" "COLUMNS should be set to 80 by setup_file"

    teardown_file # Should not attempt stty operations

    assert_equal "$COLUMNS" "$original_columns_value" "COLUMNS should be restored"
    assert_equal "$_bats_saved_stty_cols" "" "_bats_saved_stty_cols should be unset"
    assert_equal "$_bats_saved_columns_env" "" "_bats_saved_columns_env should be unset"

    # Restore original environment
    unset LIB_MSG_TEST_STTY_UNAVAILABLE
    # Restore COLUMNS just in case, though teardown_file should handle it
    if [ -n "${original_columns_value+x}" ]; then export COLUMNS="$original_columns_value"; else unset COLUMNS; fi
    unset _BATS_TEST_STDIN_IS_TTY _BATS_TEST_STDOUT_IS_TTY
}

@test "setup_file/teardown_file: not a TTY" {
    # Local context for this test
    local _bats_saved_stty_cols_local=""
    local _bats_saved_columns_env_local=""
    local original_columns_value="99" # Simulate pre-existing COLUMNS

    # Assign to global vars that setup_file/teardown_file use
    _bats_saved_stty_cols="$_bats_saved_stty_cols_local"
    _bats_saved_columns_env="$_bats_saved_columns_env_local"
    export COLUMNS="$original_columns_value"
    
    # Simulate stdin not being a TTY, stdout being a TTY
    export _BATS_TEST_STDIN_IS_TTY="false"
    export _BATS_TEST_STDOUT_IS_TTY="true"
    
    # No stty stub needed, as it shouldn't be called if TTY checks fail in our helper functions

    setup_file

    assert_equal "$_bats_saved_stty_cols" "" "Original stty cols should be empty as not a TTY"
    assert_equal "$_bats_saved_columns_env" "$original_columns_value" "Original COLUMNS env should be captured"
    assert_equal "$COLUMNS" "80" "COLUMNS should be set to 80 by setup_file"

    teardown_file # Should not attempt stty operations

    assert_equal "$COLUMNS" "$original_columns_value" "COLUMNS should be restored"
    assert_equal "$_bats_saved_stty_cols" "" "_bats_saved_stty_cols should be unset"
    assert_equal "$_bats_saved_columns_env" "" "_bats_saved_columns_env should be unset"

    # Restore original environment
    # Restore COLUMNS just in case, though teardown_file should handle it
    if [ -n "${original_columns_value+x}" ]; then export COLUMNS="$original_columns_value"; else unset COLUMNS; fi
    unset _BATS_TEST_STDIN_IS_TTY _BATS_TEST_STDOUT_IS_TTY
}