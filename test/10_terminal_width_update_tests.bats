#!/usr/bin/env bats

# Test that public API functions check terminal width every time they run

# Load BATS support and assertion libraries
load "libs/bats-support/load"
load "libs/bats-assert/load"
load "libs/bats-mock/stub.bash"

# Load our test helpers
load "test_helpers.bash"

# Load the library to be tested
# shellcheck source=../lib_msg.sh
load "../lib_msg.sh"

setup() {
    # Mock SCRIPT_NAME for consistent prefix in tests
    export SCRIPT_NAME="dynamic_test.sh"
    # Store original COLUMNS to restore later
    export _ORIG_COLUMNS="$COLUMNS"
}

teardown() {
    # Restore original COLUMNS
    export COLUMNS="$_ORIG_COLUMNS"
    unset _ORIG_COLUMNS
    # Re-initialize library state
    _lib_msg_force_reinit
    # Clean up temporary script if it exists
    if [ -f "$BATS_TMPDIR/multi_commands.sh" ]; then
        rm -f "$BATS_TMPDIR/multi_commands.sh"
    fi
}

@test "msg(): Detects changing terminal width between calls" {
    # Setup TTY conditions for wrapping
    simulate_tty_conditions 0 1 # stdout TTY, stderr not TTY
    
    # Set initial narrow width to 40
    export COLUMNS=40
    # First call with narrow terminal
    run msg "This is a long message that should wrap at different widths depending on the terminal."
    # Store first output
    first_output="$output"
    
    # Change width to 80 (wider terminal)
    export COLUMNS=80
    # Second call with wider terminal
    run msg "This is a long message that should wrap at different widths depending on the terminal."
    # Store second output
    second_output="$output"
    
    # Outputs should be different due to different wrapping
    [ "$first_output" != "$second_output" ]
    
    # Verify first output has more lines (narrower terminal = more wrapping)
    # Convert the output to lines array for counting
    local IFS=$'\n'
    # shellcheck disable=SC2206
    local first_lines=($first_output)
    # shellcheck disable=SC2206
    local second_lines=($second_output)
    
    # First output should have more lines than second due to narrower width
    [ ${#first_lines[@]} -gt ${#second_lines[@]} ]
}

@test "err(): Detects changing terminal width between calls" {
    # Setup TTY conditions for wrapping
    simulate_tty_conditions 1 0 # stdout not TTY, stderr TTY
    
    # Set initial narrow width to 40
    export COLUMNS=40
    # First call with narrow terminal
    run err "This is a long error message that should wrap at different widths depending on the terminal."
    # Store first output
    first_output="$output"
    
    # Change width to 80 (wider terminal)
    export COLUMNS=80
    # Second call with wider terminal
    run err "This is a long error message that should wrap at different widths depending on the terminal."
    # Store second output
    second_output="$output"
    
    # Outputs should be different due to different wrapping
    [ "$first_output" != "$second_output" ]
    
    # Verify first output has more lines (narrower terminal = more wrapping)
    # Convert the output to lines array for counting
    local IFS=$'\n'
    # shellcheck disable=SC2206
    local first_lines=($first_output)
    # shellcheck disable=SC2206
    local second_lines=($second_output)
    
    # First output should have more lines than second due to narrower width
    [ ${#first_lines[@]} -gt ${#second_lines[@]} ]
}

@test "info(): Detects changing terminal width between calls" {
    # Setup TTY conditions for wrapping
    simulate_tty_conditions 0 1 # stdout TTY, stderr not TTY
    
    # Set initial narrow width to 40
    export COLUMNS=40
    # First call with narrow terminal
    run info "This is a long info message that should wrap at different widths depending on the terminal."
    # Store first output
    first_output="$output"
    
    # Change width to 80 (wider terminal)
    export COLUMNS=80
    # Second call with wider terminal
    run info "This is a long info message that should wrap at different widths depending on the terminal."
    # Store second output
    second_output="$output"
    
    # Outputs should be different due to different wrapping
    [ "$first_output" != "$second_output" ]
    
    # Verify first output has more lines (narrower terminal = more wrapping)
    # Convert the output to lines array for counting
    local IFS=$'\n'
    # shellcheck disable=SC2206
    local first_lines=($first_output)
    # shellcheck disable=SC2206
    local second_lines=($second_output)
    
    # First output should have more lines than second due to narrower width
    [ ${#first_lines[@]} -gt ${#second_lines[@]} ]
}

@test "warn(): Detects changing terminal width between calls" {
    # Setup TTY conditions for wrapping
    simulate_tty_conditions 1 0 # stdout not TTY, stderr TTY
    
    # Set initial narrow width to 40
    export COLUMNS=40
    # First call with narrow terminal
    run warn "This is a long warning message that should wrap at different widths depending on the terminal."
    # Store first output
    first_output="$output"
    
    # Change width to 80 (wider terminal)
    export COLUMNS=80
    # Second call with wider terminal
    run warn "This is a long warning message that should wrap at different widths depending on the terminal."
    # Store second output
    second_output="$output"
    
    # Outputs should be different due to different wrapping
    [ "$first_output" != "$second_output" ]
    
    # Verify first output has more lines (narrower terminal = more wrapping)
    # Convert the output to lines array for counting
    local IFS=$'\n'
    # shellcheck disable=SC2206
    local first_lines=($first_output)
    # shellcheck disable=SC2206
    local second_lines=($second_output)
    
    # First output should have more lines than second due to narrower width
    [ ${#first_lines[@]} -gt ${#second_lines[@]} ]
}

@test "die(): Detects changing terminal width between calls" {
    # Setup TTY conditions for wrapping
    simulate_tty_conditions 1 0 # stdout not TTY, stderr TTY
    
    # Mock _lib_msg_is_return_valid to always return true, so die() returns instead of exits
    function _lib_msg_is_return_valid { return 0; }
    
    # Set initial narrow width to 40
    export COLUMNS=40
    # First call with narrow terminal
    run die "This is a long die message that should wrap at different widths depending on the terminal."
    # Store first output
    first_output="$output"
    
    # Change width to 80 (wider terminal)
    export COLUMNS=80
    # Second call with wider terminal
    run die "This is a long die message that should wrap at different widths depending on the terminal."
    # Store second output
    second_output="$output"
    
    # Outputs should be different due to different wrapping
    [ "$first_output" != "$second_output" ]
    
    # Verify first output has more lines (narrower terminal = more wrapping)
    # Convert the output to lines array for counting
    local IFS=$'\n'
    # shellcheck disable=SC2206
    local first_lines=($first_output)
    # shellcheck disable=SC2206
    local second_lines=($second_output)
    
    # First output should have more lines than second due to narrower width
    [ ${#first_lines[@]} -gt ${#second_lines[@]} ]
}

# Helper function to get the absolute path to the project root directory
get_project_root() {
    # Get the directory of this test file and go up one level to project root
    cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd
}

@test "Consecutive commands use current terminal width" {
    # Setup TTY conditions for wrapping
    simulate_tty_conditions 0 0 # both stdout and stderr are TTY
    
    # Get absolute path to project root
    local project_root="$(get_project_root)"
    
    # Create script to execute multiple commands in sequence
    cat > "$BATS_TMPDIR/multi_commands.sh" << EOF
#!/bin/sh
# Source the library using absolute path
. "$project_root/lib_msg.sh"
export SCRIPT_NAME="width_test.sh"

# Run multiple commands that should all respect the current width
msg "This is a message that should wrap according to current terminal width."
info "This is an info message that should also respect the current width."
warn "This is a warning that should follow the same wrapping behavior."
err "This is an error that should have consistent wrapping with others."
EOF

    chmod +x "$BATS_TMPDIR/multi_commands.sh"
    
    # Set narrow width and run
    export COLUMNS=50
    export LIB_MSG_FORCE_STDOUT_TTY=true
    export LIB_MSG_FORCE_STDERR_TTY=true
    
    # Make sure COLUMNS and TTY settings are passed to the subshell
    run env COLUMNS=50 LIB_MSG_FORCE_STDOUT_TTY=true LIB_MSG_FORCE_STDERR_TTY=true "$BATS_TMPDIR/multi_commands.sh"
    
    # Store output for comparison
    narrow_output="$output"
    
    # Set wide width and run again
    export COLUMNS=100
    
    # Make sure COLUMNS and TTY settings are passed to the subshell
    run env COLUMNS=100 LIB_MSG_FORCE_STDOUT_TTY=true LIB_MSG_FORCE_STDERR_TTY=true "$BATS_TMPDIR/multi_commands.sh"
    
    # Store output for comparison
    wide_output="$output"
    
    # Compare outputs - they should be different
    [ "$narrow_output" != "$wide_output" ]
    
    # Convert outputs to line counts
    local IFS=$'\n'
    # shellcheck disable=SC2206
    local narrow_lines=($narrow_output)
    # shellcheck disable=SC2206
    local wide_lines=($wide_output)
    
    # Narrow output should have more lines due to more wrapping
    [ ${#narrow_lines[@]} -gt ${#wide_lines[@]} ]
}