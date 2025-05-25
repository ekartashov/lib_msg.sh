#!/usr/bin/env bats

load 'libs/bats-support/load'
load 'libs/bats-assert/load'
load 'test_helpers'

# Source the library
source "$BATS_TEST_DIRNAME/../lib_msg.sh"

setup() {
  # Setup for performance tests if needed
  :
}

teardown() {
  # Cleanup after performance tests if needed
  :
}

# Generate test data of specified size
generate_test_data() {
  local size=$1
  local text=""
  local char_set="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 "
  local char_set_size=${#char_set}
  
  for ((i=0; i<size; i++)); do
    local idx=$((RANDOM % char_set_size))
    text="${text}${char_set:$idx:1}"
  done
  
  echo "$text"
}

# Generate test data with ANSI codes
generate_ansi_test_data() {
  local size=$1
  local text=""
  local char_set="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 "
  local char_set_size=${#char_set}
  local ansi_codes=(
    "\033[31m" # Red
    "\033[32m" # Green
    "\033[0m"  # Reset
    "\033[1m"  # Bold
  )
  local ansi_codes_size=${#ansi_codes[@]}
  
  for ((i=0; i<size; i++)); do
    # Insert ANSI code every ~20 characters
    if [ $((i % 20)) -eq 0 ] && [ $i -gt 0 ]; then
      local ansi_idx=$((RANDOM % ansi_codes_size))
      text="${text}${ansi_codes[$ansi_idx]}"
    fi
    
    local idx=$((RANDOM % char_set_size))
    text="${text}${char_set:$idx:1}"
  done
  
  echo "$text"
}

# Generate test data with newlines
generate_newline_test_data() {
  local size=$1
  local text=""
  local char_set="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 "
  local char_set_size=${#char_set}
  
  for ((i=0; i<size; i++)); do
    # Insert newline every ~40 characters
    if [ $((i % 40)) -eq 0 ] && [ $i -gt 0 ]; then
      text="${text}\n"
    fi
    
    local idx=$((RANDOM % char_set_size))
    text="${text}${char_set:$idx:1}"
  done
  
  echo -e "$text"
}

# Function to run performance test and print results
run_performance_test() {
  local func_name=$1
  shift
  local iterations=${1:-10}
  if [[ "$iterations" =~ ^[0-9]+$ ]]; then
    shift
  else
    iterations=10
  fi
  local start_time
  local end_time
  local elapsed
  
  # Run function multiple times to get a reliable measurement
  start_time=$(date +%s.%N)
  for ((i=0; i<iterations; i++)); do
    "$func_name" "$@" >/dev/null
  done
  end_time=$(date +%s.%N)
  
  # Calculate average time per iteration in milliseconds
  elapsed=$(echo "($end_time - $start_time) * 1000 / $iterations" | bc -l)
  printf "%.2f ms" "$elapsed"
}

@test "Performance: ANSI stripping - small input (100 chars)" {
  local input=$(generate_ansi_test_data 100)
  
  echo "ANSI stripping performance test - small input (100 chars)" >&3
  
  local shell_time=$(run_performance_test _lib_msg_strip_ansi_shell "$input")
  echo "Shell implementation: $shell_time" >&3
  
  local sed_time=$(run_performance_test _lib_msg_strip_ansi_sed "$input")
  echo "Sed implementation: $sed_time" >&3
  
  echo "" >&3
}

@test "Performance: ANSI stripping - medium input (1000 chars)" {
  local input=$(generate_ansi_test_data 1000)
  
  echo "ANSI stripping performance test - medium input (1000 chars)" >&3
  
  local shell_time=$(run_performance_test _lib_msg_strip_ansi_shell "$input")
  echo "Shell implementation: $shell_time" >&3
  
  local sed_time=$(run_performance_test _lib_msg_strip_ansi_sed "$input")
  echo "Sed implementation: $sed_time" >&3
  
  echo "" >&3
}

@test "Performance: ANSI stripping - large input (5000 chars)" {
  local input=$(generate_ansi_test_data 5000)
  
  echo "ANSI stripping performance test - large input (5000 chars)" >&3
  
  local shell_time=$(run_performance_test _lib_msg_strip_ansi_shell "$input" 20)
  echo "Shell implementation: $shell_time" >&3
  
  local sed_time=$(run_performance_test _lib_msg_strip_ansi_sed "$input" 20)
  echo "Sed implementation: $sed_time" >&3
  
  echo "" >&3
}

@test "Performance: Text wrapping - small input (100 chars, width 40)" {
  local input=$(generate_test_data 100)
  
  echo "Text wrapping performance test - small input (100 chars, width 40)" >&3
  
  # Use shell implementation (now the only implementation)
  local shell_time=$(run_performance_test _lib_msg_wrap_text 10 "$input" 40)
  echo "Shell implementation: $shell_time" >&3
  
  echo "" >&3
}

@test "Performance: Text wrapping - medium input (1000 chars, width 80)" {
  local input=$(generate_test_data 1000)
  
  echo "Text wrapping performance test - medium input (1000 chars, width 80)" >&3
  
  # Use shell implementation (now the only implementation)
  local shell_time=$(run_performance_test _lib_msg_wrap_text 10 "$input" 80)
  echo "Shell implementation: $shell_time" >&3
  
  echo "" >&3
}

@test "Performance: Text wrapping - large input (5000 chars, width 100)" {
  local input=$(generate_test_data 5000)
  
  echo "Text wrapping performance test - large input (5000 chars, width 100)" >&3
  
  # Use shell implementation (now the only implementation)
  local shell_time=$(run_performance_test _lib_msg_wrap_text 3 "$input" 100)
  echo "Shell implementation: $shell_time" >&3
  
  echo "" >&3
}

@test "Performance: Newline to space conversion - small input (100 chars)" {
  local input=$(generate_newline_test_data 100)
  
  echo "Newline to space conversion - small input (100 chars)" >&3
  
  local shell_time=$(run_performance_test _lib_msg_tr_newline_to_space_shell 10 "$input")
  echo "Shell implementation: $shell_time" >&3
  
  # Only run if tr is available
  if _lib_msg_has_command tr; then
    local tr_cmd_time=$(run_performance_test "tr_wrapper" 10 "$input")
    echo "tr command: $tr_cmd_time" >&3
  else
    echo "tr command not available, skipping" >&3
  fi
  
  echo "" >&3
}

@test "Performance: Newline to space conversion - medium input (1000 chars)" {
  local input=$(generate_newline_test_data 1000)
  
  echo "Newline to space conversion - medium input (1000 chars)" >&3
  
  local shell_time=$(run_performance_test _lib_msg_tr_newline_to_space_shell 10 "$input")
  echo "Shell implementation: $shell_time" >&3
  
  # Only run if tr is available
  if _lib_msg_has_command tr; then
    local tr_cmd_time=$(run_performance_test "tr_wrapper" 10 "$input")
    echo "tr command: $tr_cmd_time" >&3
  else
    echo "tr command not available, skipping" >&3
  fi
  
  echo "" >&3
}

@test "Performance: Newline to space conversion - large input (5000 chars)" {
  local input=$(generate_newline_test_data 5000)
  
  echo "Newline to space conversion - large input (5000 chars)" >&3
  
  local shell_time=$(run_performance_test _lib_msg_tr_newline_to_space_shell 5 "$input")
  echo "Shell implementation: $shell_time" >&3
  
  # Only run if tr is available
  if _lib_msg_has_command tr; then
    local tr_cmd_time=$(run_performance_test "tr_wrapper" 5 "$input")
    echo "tr command: $tr_cmd_time" >&3
  else
    echo "tr command not available, skipping" >&3
  fi
  
  echo "" >&3
}

@test "Performance: Whitespace removal - small input (100 chars)" {
  local input=$(generate_test_data 100)
  
  echo "Whitespace removal - small input (100 chars)" >&3
  
  local shell_time=$(run_performance_test _lib_msg_tr_remove_whitespace_shell 10 "$input")
  echo "Shell implementation: $shell_time" >&3
  
  # Only run if tr is available
  if _lib_msg_has_command tr; then
    local tr_cmd_time=$(run_performance_test "tr_remove_wrapper" 10 "$input")
    echo "tr command: $tr_cmd_time" >&3
  else
    echo "tr command not available, skipping" >&3
  fi
  
  echo "" >&3
}

@test "Performance: Whitespace removal - medium input (1000 chars)" {
  local input=$(generate_test_data 1000)
  
  echo "Whitespace removal - medium input (1000 chars)" >&3
  
  local shell_time=$(run_performance_test _lib_msg_tr_remove_whitespace_shell 10 "$input")
  echo "Shell implementation: $shell_time" >&3
  
  # Only run if tr is available
  if _lib_msg_has_command tr; then
    local tr_cmd_time=$(run_performance_test "tr_remove_wrapper" 10 "$input")
    echo "tr command: $tr_cmd_time" >&3
  else
    echo "tr command not available, skipping" >&3
  fi
  
  echo "" >&3
}

@test "Performance: Whitespace removal - large input (5000 chars)" {
  local input=$(generate_test_data 5000)
  
  echo "Whitespace removal - large input (5000 chars)" >&3
  
  local shell_time=$(run_performance_test _lib_msg_tr_remove_whitespace_shell 5 "$input")
  echo "Shell implementation: $shell_time" >&3
  
  # Only run if tr is available
  if _lib_msg_has_command tr; then
    local tr_cmd_time=$(run_performance_test "tr_remove_wrapper" 5 "$input")
    echo "tr command: $tr_cmd_time" >&3
  else
    echo "tr command not available, skipping" >&3
  fi
  
  echo "" >&3
}

# Wrapper functions for tr command
tr_wrapper() {
  printf '%s' "$1" | tr '\n' ' '
}

tr_remove_wrapper() {
  printf '%s' "$1" | tr -d '[:space:]'
}

@test "Performance: End-to-end message processing - small message (100 chars)" {
  local input=$(generate_test_data 100)
  
  echo "End-to-end message processing - small message (100 chars)" >&3
  
  # Call full message processing pipeline with different width settings
  simulate_tty_conditions 0 0
  export COLUMNS=80
  local time_80col=$(run_performance_test "_print_msg_core" 10 "$input" "Test: " "false" "false")
  echo "80 columns terminal: $time_80col" >&3
  
  export COLUMNS=40
  local time_40col=$(run_performance_test "_print_msg_core" 10 "$input" "Test: " "false" "false")
  echo "40 columns terminal: $time_40col" >&3
  
  echo "" >&3
}

@test "Performance: End-to-end message processing - medium message (1000 chars)" {
  local input=$(generate_test_data 1000)
  
  echo "End-to-end message processing - medium message (1000 chars)" >&3
  
  # Call full message processing pipeline with different width settings
  simulate_tty_conditions 0 0
  export COLUMNS=80
  local time_80col=$(run_performance_test "_print_msg_core" 10 "$input" "Test: " "false" "false")
  echo "80 columns terminal: $time_80col" >&3
  
  export COLUMNS=40
  local time_40col=$(run_performance_test "_print_msg_core" 10 "$input" "Test: " "false" "false")
  echo "40 columns terminal: $time_40col" >&3
  
  echo "" >&3
}