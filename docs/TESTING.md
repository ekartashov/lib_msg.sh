# Testing Guide for lib_msg.sh

This document provides information about running tests for the lib_msg.sh library.

## Test Framework

The project uses [Bats](https://github.com/bats-core/bats-core) (Bash Automated Testing System) for testing. Tests are located in the `test/` directory with the naming convention `XX_description_tests.bats`.

## Running Tests

### Running All Tests

To run all tests:

```bash
bats test/
```

Or with parallel execution:

```bash
bats -T test/ -j $(nproc --ignore 2)
```

### Running Specific Tests

To run a specific test file:

```bash
bats test/01_init_detection_tests.bats
```

### Excluding Specific Tests

#### Exclude Performance Tests

Performance tests (test #13) can be resource-intensive and time-consuming. To run all tests except the performance tests:

```bash
bats $(find test -name "[0-9][0-9]_*.bats" | grep -v "13_performance_tests.bats")
```

#### Exclude Multiple Specific Tests

To exclude both performance tests (test #13) and setup tests (test #00):

```bash
bats test/0{1,2,3,4,5,6,7,8,9}_*.bats test/1{0,1,2}_*.bats
```

Or using a more generic approach:

```bash
bats $(find test -name "[0-9][0-9]_*.bats" | grep -v "13_performance_tests.bats" | grep -v "00_setup_teardown_tests.bats")
```

## Performance Tests

The performance tests (test #13) compare different implementations:
- ANSI stripping (shell vs sed)
- Text wrapping (shell vs awk)
- Newline conversion (shell vs tr command)
- Whitespace removal (shell vs tr command)
- End-to-end message processing

To run only the performance tests:

```bash
bats test/13_performance_tests.bats
```

## Test Environment

Some tests manipulate the environment to simulate different conditions:
- TTY vs non-TTY output
- Different terminal widths
- Presence or absence of external commands

The `test_helpers.bash` file contains utility functions for manipulating the test environment.