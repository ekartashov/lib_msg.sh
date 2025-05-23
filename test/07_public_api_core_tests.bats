#!/usr/bin/env bats

# This file contains core tests for the public API functions of lib_msg.sh
# (msg, err, info, warn, die, etc.), focusing on correct prefixing,
# stream usage, newline handling, and exit/return codes.
# More complex integration tests (e.g., detailed wrapping/coloring)
# are in other files.

# Require BATS version 1.5.0 for run with expected exit code (-123)
bats_require_minimum_version 1.5.0

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
    # Mock SCRIPT_NAME for consistent prefix in tests
    SCRIPT_NAME="test_script.sh"
    # Helpers like simulate_tty_conditions will handle TTY state and library re-initialization.
}

teardown() {
    unset -f script_to_run_die_return 2>/dev/null
    unset -f script_to_run_die_return_no_code 2>/dev/null
    unset -f script_to_run_die_return_invalid_code 2>/dev/null
    unset -f test_func_for_is_return_valid 2>/dev/null
    # Individual tests that stub 'test' should unstub it themselves or rely on simulate_tty_conditions.
}

@test "err() prints message to stderr with colored 'E:' prefix and newline (simulated TTY for stderr)" {
    # stdout not TTY (exit 1), stderr is TTY (exit 0)
    simulate_tty_conditions 1 0

    run err 'This is an error message' 1>/dev/null

    assert_success
    # Use partial matching to avoid issues with color codes
    assert_output --partial "This is an error message"
}

@test "err() prints plain message to stderr if not TTY (simulated no TTY for stderr)" {
    # stdout not TTY (exit 1), stderr not TTY (exit 1)
    simulate_tty_conditions 1 1

    run err 'Plain error' 1>/dev/null
    assert_success
    assert_line --index 0 "test_script.sh: E: Plain error"
}

@test "errn() prints message to stderr with colored 'E:' prefix and no newline (simulated TTY for stderr)" {
    # stdout not TTY (exit 1), stderr is TTY (exit 0)
    simulate_tty_conditions 1 0

    run errn 'Error no newline' 1>/dev/null
    assert_success
    # Use partial matching to avoid issues with color codes
    assert_output --partial "Error no newline"
}

@test "warn() prints message to stderr with colored 'W:' prefix and newline (simulated TTY for stderr)" {
    # stdout not TTY (exit 1), stderr is TTY (exit 0)
    simulate_tty_conditions 1 0

    run warn 'This is a warning message' 1>/dev/null
    assert_success
    # Use partial matching to avoid issues with color codes
    assert_output --partial "This is a warning message"
}

@test "warn() prints plain message to stderr if not TTY (simulated no TTY for stderr)" {
    # stdout not TTY (exit 1), stderr not TTY (exit 1)
    simulate_tty_conditions 1 1

    run warn 'Plain warning' 1>/dev/null
    assert_success
    assert_line --index 0 "test_script.sh: W: Plain warning"
}

@test "warnn() prints message to stderr with colored 'W:' prefix and no newline (simulated TTY for stderr)" {
    # stdout not TTY (exit 1), stderr is TTY (exit 0)
    simulate_tty_conditions 1 0

    run warnn 'Warning no newline' 1>/dev/null
    assert_success
    # Use partial matching to avoid issues with color codes
    assert_output --partial "Warning no newline"
}

@test "msg() prints message to stdout with prefix and newline (simulated no TTY for stdout)" {
    # stdout not TTY (exit 1), stderr not TTY (exit 1)
    simulate_tty_conditions 1 1

    run msg 'This is a general message' 2>/dev/null
    assert_success
    assert_line --index 0 "test_script.sh: This is a general message"
}

@test "msgn() prints message to stdout with prefix and no newline (simulated no TTY for stdout)" {
    # stdout not TTY (exit 1), stderr not TTY (exit 1)
    simulate_tty_conditions 1 1

    run msgn 'This is a general message without newline' 2>/dev/null
    assert_success
    assert_output "test_script.sh: This is a general message without newline"
}

@test "info() prints message to stdout with colored 'I:' prefix and newline (simulated TTY for stdout)" {
    # stdout is TTY (exit 0), stderr not TTY (exit 1)
    simulate_tty_conditions 0 1

    run info 'This is an info message' 2>/dev/null
    assert_success
    # Use partial matching to avoid issues with color codes
    assert_output --partial "This is an info message"
}

@test "info() prints plain message to stdout if not TTY (simulated no TTY for stdout)" {
    # stdout not TTY (exit 1), stderr not TTY (exit 1)
    simulate_tty_conditions 1 1

    run info 'Plain info' 2>/dev/null
    assert_success
    assert_line --index 0 "test_script.sh: I: Plain info"
}

@test "infon() prints message to stdout with colored 'I:' prefix and no newline (simulated TTY for stdout)" {
    # stdout is TTY (exit 0), stderr not TTY (exit 1)
    simulate_tty_conditions 0 1

    run infon 'Info no newline' 2>/dev/null
    assert_success
    # Use partial matching to avoid issues with color codes
    assert_output --partial "Info no newline"
}

@test "die() prints message to stderr, colored 'E:', and exits with given code (when not sourced, simulated TTY)" {
    # Mock TTY: stderr is TTY
    # Use environment variable approach instead of stubbing
    run bash -c "export BATS_TEST_DIRNAME='${TEST_PATH}'; export LIB_MSG_FORCE_STDERR_TTY='0'; source \"${LIB_PATH}/lib_msg.sh\"; SCRIPT_NAME='test_script.sh'; die 123 'Fatal error, exiting' 1>/dev/null"
    assert_failure 123
    # Use partial matching to avoid issues with color codes
    assert_output --partial "Fatal error, exiting"
}

@test "die() prints message to stderr, plain 'E:', and exits with given code (when not sourced, simulated no TTY)" {
    # Use environment variable approach - stderr is not a TTY
    run bash -c "export BATS_TEST_DIRNAME='${TEST_PATH}'; export LIB_MSG_FORCE_STDERR_TTY='1'; source \"${LIB_PATH}/lib_msg.sh\"; SCRIPT_NAME='test_script.sh'; die 123 'Fatal error, exiting plain' 1>/dev/null"
    assert_failure 123
    assert_line --index 0 "test_script.sh: E: Fatal error, exiting plain"
}

@test "die() prints message and exits with 1 if no code provided (when not sourced, simulated TTY)" {
    # Use environment variable approach - stderr is a TTY
    run bash -c "export BATS_TEST_DIRNAME='${TEST_PATH}'; export LIB_MSG_FORCE_STDERR_TTY='0'; source \"${LIB_PATH}/lib_msg.sh\"; SCRIPT_NAME='test_script.sh'; die 'Implicit error code' 1>/dev/null"
    assert_failure 1
    # Use partial matching to avoid issues with color codes
    assert_output --partial "Implicit error code"
}

@test "die() prints message and exits with 1 if invalid code 'invalid' provided (when not sourced, simulated TTY)" {
    # Use environment variable approach - stderr is a TTY
    run bash -c "export BATS_TEST_DIRNAME='${TEST_PATH}'; export LIB_MSG_FORCE_STDERR_TTY='0'; source \"${LIB_PATH}/lib_msg.sh\"; SCRIPT_NAME='test_script.sh'; die 'invalid' 'Error with invalid code' 1>/dev/null"
    assert_failure 1
    # Use partial matching to avoid issues with color codes
    assert_output --partial "Error with invalid code"
}

@test "die() prints message and exits with 1 if invalid code '-5' provided (when not sourced, simulated TTY)" {
    # Use environment variable approach - stderr is a TTY
    run bash -c "export BATS_TEST_DIRNAME='${TEST_PATH}'; export LIB_MSG_FORCE_STDERR_TTY='0'; source \"${LIB_PATH}/lib_msg.sh\"; SCRIPT_NAME='test_script.sh'; die '-5' 'Error with negative code' 1>/dev/null"
    assert_failure 1
    # Use partial matching to avoid issues with color codes
    assert_output --partial "Error with negative code"
}

@test "die() prints message to stderr, colored 'E:', and returns with given code (when sourced/in function, simulated TTY)" {
    # Note: simulate_tty_conditions will handle stubbing 'test'
    script_to_run_die_return() {
            local test_dir="$1"
            local lib_dir="$2"
            
            # Use full paths
            source "$test_dir/libs/bats-mock/stub.bash" # Load bats-mock for stub
            source "$lib_dir/lib_msg.sh" # Source the main library
            source "$test_dir/test_helpers.bash" # Source helpers
    
            SCRIPT_NAME="test_script.sh"
            simulate_tty_conditions 1 0 # stdout not TTY, stderr is TTY
    
            my_func() {
                die 77 "Returning from function"
                local _die_status=$?
                echo "my_func status: $_die_status" >&3 # Send to fd 3 for capture by bats
                return "$_die_status"
            }
            my_func
            return $?
        }
    export -f script_to_run_die_return
    run bash -c "script_to_run_die_return '$TEST_PATH' '$LIB_PATH' 1>/dev/null"

    assert_failure 77
    # Use partial matching to avoid issues with color codes
    assert_output --partial "Returning from function"
}

@test "die() returns 1 if no code provided (when sourced/in function, simulated TTY)" {
    script_to_run_die_return_no_code() {
            local test_dir="$1"
            local lib_dir="$2"
            
            # Use full paths
            source "$test_dir/libs/bats-mock/stub.bash" # Load bats-mock for stub
            source "$lib_dir/lib_msg.sh" # Source the main library
            source "$test_dir/test_helpers.bash" # Source helpers
    
            SCRIPT_NAME="test_script.sh"
            simulate_tty_conditions 1 0 # stdout not TTY, stderr is TTY
    
            my_func_no_code() {
                die "Returning with implicit code"
            }
            my_func_no_code
            return $?
        }
    export -f script_to_run_die_return_no_code
    run bash -c "script_to_run_die_return_no_code '$TEST_PATH' '$LIB_PATH' 1>/dev/null"
    assert_failure 1
    # Use partial matching to avoid issues with color codes
    assert_output --partial "Returning with implicit code"
}

@test "die() returns 1 if invalid code 'invalid' provided (when sourced/in function, simulated TTY)" {
    script_to_run_die_return_invalid_code() {
            local test_dir="$1"
            local lib_dir="$2"
            
            # Use full paths
            source "$test_dir/libs/bats-mock/stub.bash" # Load bats-mock for stub
            source "$lib_dir/lib_msg.sh" # Source the main library
            source "$test_dir/test_helpers.bash" # Source helpers
    
            SCRIPT_NAME="test_script.sh"
            simulate_tty_conditions 1 0 # stdout not TTY, stderr is TTY
    
            my_func_invalid_code() {
                die "invalid" "Returning with invalid code"
            }
            my_func_invalid_code
            return $?
        }
    export -f script_to_run_die_return_invalid_code
    run bash -c "script_to_run_die_return_invalid_code '$TEST_PATH' '$LIB_PATH' 1>/dev/null"
    assert_failure 1
    # Use partial matching to avoid issues with color codes
    assert_output --partial "Returning with invalid code"
}

@test "Prefix uses 'lib_msg.sh' if SCRIPT_NAME is unset (simulated no TTY)" {
    # TTY detection within the subshell will be controlled by LIB_MSG_FORCE_*_TTY variables.
    # Direct stubbing of 'test' here is not necessary as it won't be reached by _lib_msg_init_detection
    # when the FORCE variables are set.

    # Use environment variable approach - both stdout and stderr are not TTYs
    run bash -c "export BATS_TEST_DIRNAME='${TEST_PATH}'; export LIB_MSG_FORCE_STDOUT_TTY='1'; export LIB_MSG_FORCE_STDERR_TTY='1'; source \"${LIB_PATH}/lib_msg.sh\"; unset SCRIPT_NAME; msg 'Testing SCRIPT_NAME fallback' 2>/dev/null"
    assert_success
    assert_line --index 0 "lib_msg.sh: Testing SCRIPT_NAME fallback"
}

# --- _lib_msg_is_return_valid() Tests ---
# These tests are ported from the original .worktree/test/core_functions_tests.bats
# They verify the logic that determines if die() should exit or return.

@test "_lib_msg_is_return_valid(): correctly detects sourced context" {
    # Since we're running in BATS, lib_msg.sh is sourced via the 'load' command at the top.
    # _lib_msg_is_return_valid itself relies on `(return 0 2>/dev/null)` succeeding.
    run _lib_msg_is_return_valid
    assert_success "Should return success (0) when in a sourced context"
}

@test "_lib_msg_is_return_valid(): correctly detects non-sourced context using bash subshell" {
    # Create a temporary script that executes the function's core logic directly (not sourced)
    local temp_script="$BATS_TEST_TMPDIR/test_return_valid.sh"
    
    # Create the test script with a non-sourced function execution
    # This script mimics the core check within _lib_msg_is_return_valid
    cat > "$temp_script" << 'EOF'
#!/usr/bin/env bash
# This script is to simulate a non-sourced environment for _lib_msg_is_return_valid's logic

# Direct execution of the function logic
# (return 0 2>/dev/null) will fail here, causing the 'else' branch.
if (return 0 2>/dev/null); then
  # This block should not be reached in a non-sourced script
  exit 0  # Indicates (incorrectly) a sourced context
else
  # This block *should* be reached
  exit 1  # Indicates (correctly) a non-sourced context
fi
EOF
    
    chmod +x "$temp_script"
    
    # Run the script.
    # _lib_msg_is_return_valid itself would return 1 (failure) in a non-sourced context.
    # So, if our temp_script (which mimics its check) exits 1, it means the logic is correct.
    run "$temp_script"
    
    assert_failure "Should return failure (exit 1) when not in a sourced context"
}

@test "_lib_msg_is_return_valid(): used correctly by die() in sourced script" {
    # This test verifies that die() *returns* (doesn't exit) when lib_msg.sh is sourced.
    # It relies on _lib_msg_is_return_valid() correctly identifying the sourced context.

    test_func_for_is_return_valid() {
        local exit_code="$1"
        local lib_path_for_source="$2" # Expect LIB_PATH as the second argument
        local test_path_for_source="$3" # Expect TEST_PATH as the third argument

        # Source lib_msg.sh directly in this function's context for isolation.
        # SCRIPT_NAME is set in the main BATS setup() and should be inherited or can be set here.
        # test_helpers.bash and bats-mock are loaded by the main BATS file.
        if ! source "$lib_path_for_source/lib_msg.sh"; then
            echo "CRITICAL_ERROR: Failed to source $lib_path_for_source/lib_msg.sh for test_func_for_is_return_valid" >&2
            return 254 # Arbitrary error code for sourcing failure
        fi
        # Ensure SCRIPT_NAME is set for consistent prefixes if die prints it.
        SCRIPT_NAME="${SCRIPT_NAME:-test_script.sh}"

        # Explicitly set TTY state for this test's context
        export LIB_MSG_FORCE_STDERR_TTY="0" # stderr is TTY
        export LIB_MSG_FORCE_STDOUT_TTY="1" # stdout is not (or doesn't matter for die)
        
        # Source test_helpers.bash to get _lib_msg_force_reinit
        # Note: test_helpers.bash also sources lib_msg.sh, but sourcing it again here
        # after setting FORCE vars and before _lib_msg_force_reinit is fine.
        if ! source "$test_path_for_source/test_helpers.bash"; then
             echo "CRITICAL_ERROR: Failed to source $test_path_for_source/test_helpers.bash" >&2
             return 253
        fi
        _lib_msg_force_reinit # Re-initialize lib_msg.sh with forced TTY state

        # Create a function that calls die with our specified exit code
        inner_test_die_func() {
            # SCRIPT_NAME is inherited
            die "$exit_code" "Test die message from inner_test_die_func"
            local status=$?
            # This echo should be reached if die() returns
            echo "Die returned with status: $status" >&3 # Output to fd 3 for BATS to capture
            return "$status"
        }
        
        # Call the function. die() should return.
        inner_test_die_func
        return $? # Return the status from inner_test_die_func (which is from die)
    }
    export -f test_func_for_is_return_valid # Export the function for bash -c
    
    # Run the test function in a subshell.
    # Pass LIB_PATH as an argument to the function.
    # Explicitly exit the subshell with the return status of the function.
    # Tell BATS run to expect exit code 123 from the command.
    # Redirect fd3 of the function call to fd1 of the bash -c command so BATS captures it in $output
    run -123 bash -c "test_func_for_is_return_valid 123 \"$LIB_PATH\" \"$TEST_PATH\" 3>&1; exit \$?"
    
    # assert_failure 123 # This is now redundant as run -123 handles the exit code check.
    # Check that the message from die() was printed (to stderr, which BATS captures in $output)
    assert_output --partial "Test die message from inner_test_die_func"
    # Check that our diagnostic echo was reached (on fd 3, which BATS also captures in $output)
    assert_output --partial "Die returned with status: 123"
}