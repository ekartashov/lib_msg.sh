# Contributing to lib_msg.sh

Thank you for your interest in contributing to lib_msg.sh! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Environment](#development-environment)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)
- [Documentation](#documentation)
- [Release Process](#release-process)
- [Community](#community)

## Code of Conduct

By participating in this project, you agree to abide by the [Code of Conduct](CODE_OF_CONDUCT.md). Please report unacceptable behavior to the project maintainers.

## Getting Started

### Fork and Clone the Repository

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```sh
   git clone https://github.com/YOUR-USERNAME/lib_msg.sh.git
   cd lib_msg.sh
   ```
3. Add the original repository as upstream:
   ```sh
   git remote add upstream https://github.com/ekartashov/lib_msg.sh.git
   ```

### Set Up Your Environment

1. Ensure you have a POSIX-compliant shell (bash, dash, ksh, etc.)
2. Install [Bats](https://github.com/bats-core/bats-core) for testing:
   ```sh
   git clone https://github.com/bats-core/bats-core.git
   cd bats-core
   ./install.sh /usr/local # Or another location in your PATH
   ```
3. Initialize and update the submodules to get the test helper libraries:
   ```sh
   # Use the provided script
   ./scripts/update_submodules.sh
   ```

## Development Environment

### Directory Structure

```
lib_msg.sh/
├── lib_msg.sh       # Main library file
├── test/            # Test directory
│   ├── XX_*_tests.bats  # Test files numbered in sequence
│   ├── fixtures/    # Test fixtures
│   ├── libs/        # Test helper libraries (submodules)
│   └── test_helpers.bash  # Helper functions for tests
├── examples/        # Example scripts
└── docs/            # Documentation
```

### Branching Strategy

- `main`: Stable release branch
- `develop`: Development branch for upcoming releases
- Feature branches: `feature/your-feature-name`
- Fix branches: `fix/issue-description`

## Coding Standards

### Shell Style Guide

1. **POSIX Compliance**: All code must be POSIX-compliant. Avoid bash-specific features.

2. **Function Naming**:
   - Public functions: `descriptive_function_name`
   - Internal functions: `_lib_msg_internal_function_name` (with underscore prefix)

3. **Indentation**: Use 4 spaces for indentation (not tabs).

4. **Line Length**: Keep lines under 80 characters when possible.

5. **Variable Names**:
   - Public variables: `UPPERCASE_NAME`
   - Internal variables: `_LIB_MSG_INTERNAL_VARIABLE`
   - Local variables: `lowercase_name`

6. **Comments and Documentation**:
   - Every function must have a comment block describing its purpose, parameters, and return value.
   - Use `#` for comments, with a space after the # character.
   ```sh
   # This is a properly formatted comment
   ```

7. **Error Handling**:
   - Functions should handle errors appropriately.
   - Use return codes for errors when appropriate.

8. **Portability**:
   - Always provide pure shell fallbacks for all functionality.
   - External command usage must be optional and fallback to shell implementation.

### Example Function Documentation

```sh
# Description: Brief description of what the function does
# 
# Parameters:
#   $1: Description of first parameter
#   $2: Description of second parameter
#
# Output:
#   Stdout: Description of what is output to stdout
#   Stderr: Description of what is output to stderr (if applicable)
#
# Returns:
#   0 if successful, non-zero error code on failure
function_name() {
    # Function implementation
}
```

## Testing

All changes must be tested. The project uses Bats for testing.

### Running Tests

```sh
# Run all tests
bats test/

# Run specific test files
bats test/01_init_detection_tests.bats

# Run tests in parallel
bats -T test/ -j $(nproc --ignore 2)
```

### Writing Tests

1. Create or modify tests in the appropriate test file.
2. Follow the existing test structure and naming conventions.
3. Test both success and failure cases.
4. Use the helper functions in `test_helpers.bash`.

### Test Coverage

Aim for complete test coverage for new functions. Each function should have tests for:
- Normal operation
- Edge cases
- Error conditions

### Example Test

```sh
#!/usr/bin/env bats
load 'test_helpers'

@test "function_name handles empty input" {
    run function_name ""
    assert_success
    assert_output ""
}

@test "function_name processes valid input" {
    run function_name "valid input"
    assert_success
    assert_output "expected output"
}

@test "function_name fails on invalid input" {
    run function_name "invalid input"
    assert_failure
    assert_output --partial "error message"
}
```

## Pull Request Process

1. **Create a Branch**:
   ```sh
   git checkout -b feature/your-feature-name
   ```

2. **Make Your Changes**:
   - Follow the coding standards
   - Add or update tests
   - Update documentation

3. **Test Your Changes**:
   ```sh
   bats test/
   ```

4. **Commit Your Changes**:
   ```sh
   git commit -m "Description of changes"
   ```
   
   Use meaningful commit messages that explain what changes were made and why.

5. **Push to Your Fork**:
   ```sh
   git push origin feature/your-feature-name
   ```

6. **Create a Pull Request**:
   - Go to your fork on GitHub
   - Click "New Pull Request"
   - Select the appropriate branches
   - Fill in the PR template

7. **Code Review**:
   - Address any comments or feedback
   - Make requested changes
   - Push additional commits

8. **Merge**:
   - Once approved, the maintainer will merge your PR
   - Clean up your branch after it's merged

## Documentation

All changes should be documented appropriately:

### Code Documentation

- Update function documentation comments
- Add explanations for complex code sections
- Document any assumptions or special cases

### User Documentation

- Update relevant markdown files in the `docs/` directory
- Update the README.md if necessary
- Add examples for new features

### Documentation Style

- Use Markdown for all documentation
- Follow the existing documentation style
- Use code blocks with appropriate syntax highlighting
- Keep language clear and concise

## Release Process

The release process is handled by the project maintainers:

1. Verify all tests pass
2. Update version numbers in applicable files
3. Update CHANGELOG.md with new version details
4. Create a new tag
5. Create a GitHub release

## Performance Considerations

When contributing, keep performance in mind:

1. **Benchmarking**: Run existing performance tests to ensure changes don't negatively impact performance:
   ```sh
   bats test/13_performance_tests.bats
   ```

2. **Implementation Selection**: For any functionality:
   - Provide a pure shell implementation for portability
   - Add optimized implementations using external commands when appropriate
   - Include logic to select the best implementation based on the environment

3. **Balance Portability and Performance**:
   - Prioritize portability for core functionality
   - Provide performance-optimized paths when available
   - Document performance considerations

## Community

### Reporting Bugs

- Use the GitHub issue tracker
- Include detailed steps to reproduce
- Include environment details (OS, shell version, etc.)
- If possible, provide a minimal reproduction case

### Feature Requests

- Use the GitHub issue tracker
- Describe the feature and its benefits
- Provide use cases
- If possible, suggest an implementation approach

### Getting Help

- For questions, use GitHub Discussions
- Check existing issues and documentation before asking
- Be respectful of others' time

Thank you for contributing to lib_msg.sh!