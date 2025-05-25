# Contributing to lib_msg.sh

Thank you for considering contributing to lib_msg.sh! This document provides guidelines and instructions for contributing to this project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Git Workflow](#git-workflow)
- [Pull Request Process](#pull-request-process)
- [Testing Requirements](#testing-requirements)
- [Reporting Bugs](#reporting-bugs)
- [Feature Requests](#feature-requests)
- [Documentation](#documentation)

## Code of Conduct

This project adheres to a standard code of conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

## Development Setup

1. **Fork the repository** on GitHub.

2. **Clone your fork** to your local machine:
   ```sh
   git clone https://github.com/your-username/lib_msg.sh.git
   cd lib_msg.sh
   ```

3. **Set up the upstream remote**:
   ```sh
   git remote add upstream https://github.com/ekartashov/lib_msg.sh.git
   ```

4. **Create a branch** for your work:
   ```sh
   git checkout -b feature/your-feature-name
   ```

## Coding Standards

This project follows POSIX shell scripting standards and best practices:

1. **POSIX Compliance**: All code must be compatible with POSIX sh (not bash-specific).

2. **Naming Conventions**:
   - Public functions should be prefixed with `lib_msg_`
   - Internal/private functions should be prefixed with `_lib_msg_`
   - Constants and environment variables should be in UPPERCASE
   - Local variables should be in lowercase

3. **Code Structure**:
   - Each function should have a clear purpose and documentation comment
   - Break complex operations into smaller functions
   - Favor readability over cleverness

4. **Error Handling**:
   - Functions should handle errors gracefully
   - Return appropriate error codes when applicable
   - Provide useful error messages

5. **Performance**:
   - Avoid unnecessary external commands (prefer shell builtins)
   - Consider the performance impact of operations in tight loops

## Git Workflow

1. **Keep your branch up to date**:
   ```sh
   git fetch upstream
   git rebase upstream/main
   ```

2. **Make focused commits**:
   - Each commit should represent a single logical change
   - Write clear commit messages (see below)

3. **Commit Message Format**:
   ```
   type: Short description (50 chars max)

   Longer description if necessary, explaining what and why (not how).
   Wrap at 72 characters.
   ```

   Types:
   - `feat`: New feature
   - `fix`: Bug fix
   - `docs`: Documentation changes
   - `style`: Formatting, missing semicolons, etc; no code change
   - `refactor`: Code change that neither fixes a bug nor adds a feature
   - `perf`: Code change that improves performance
   - `test`: Adding or updating tests
   - `chore`: Changes to build process, auxiliary tools, etc.

## Pull Request Process

1. **Ensure your code passes all tests**.

2. **Update documentation** if needed.

3. **Submit a pull request** from your branch to the main repository.

4. **Describe your changes** in the PR description:
   - What changes have you made?
   - Why did you make these changes?
   - What issues does it address? (Link to any relevant issues)
   - Any special considerations or dependencies?

5. **Respond to feedback** from maintainers and make requested changes.

## Testing Requirements

1. **Test Coverage**:
   - Add test cases for new functionality
   - Ensure existing tests pass with your changes

2. **Test Environments**:
   - Test your changes on multiple shells (dash, ash, bash in POSIX mode)
   - Test with color enabled and disabled
   - Test with TTY and non-TTY output

3. **Running Tests**:
   ```sh
   # Run the full test suite
   ./run_tests.sh
   
   # Run specific test category
   ./run_tests.sh color
   ```

## Reporting Bugs

When reporting bugs, please include:

1. **Description** of the issue
2. **Steps to reproduce** the problem
3. **Expected behavior**
4. **Actual behavior**
5. **Environment information**:
   - Shell version (`echo $SHELL && $SHELL --version`)
   - Terminal emulator
   - Operating system
   - Any relevant environment variables

## Feature Requests

Feature requests are welcome! When suggesting a feature:

1. **Describe the problem** your feature would solve
2. **Explain how your solution would work**
3. **Discuss alternatives** you've considered
4. **Keep the scope** as narrow as possible

## Documentation

Good documentation is critical for this project:

1. **Code Documentation**:
   - All public functions should have clear documentation comments
   - Include parameters, return values, and examples
   - Document non-obvious behavior

2. **General Documentation**:
   - Update README.md for significant changes
   - Update API_REFERENCE.md when adding or changing functions
   - Consider updating QUICKSTART.md with examples of new features
   - Add entries to CHANGELOG.md for all notable changes

---

Thank you for contributing to lib_msg.sh! Your efforts help make this library better for everyone.