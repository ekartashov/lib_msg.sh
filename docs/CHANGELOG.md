# Changelog

All notable changes to the lib_msg.sh project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive documentation improvements
  - New API reference documentation
  - Improved installation guide
  - Added quickstart guide
  - Enhanced troubleshooting documentation
- Performance testing infrastructure for benchmarking implementations
- Comprehensive test coverage for progress bar function with edge cases
- **Max wrap length feature**: Added optional parameter to text wrapping functions to prevent stalls with extremely long inputs

### Changed
- Achieved pure POSIX shell implementation by eliminating all tr command dependencies
- Optimized ANSI stripping implementation with chunk-based processing
- Improved shell implementation performance to exceed sed implementation
- Simplified codebase by removing sed implementation for ANSI stripping
- Enhanced test suite with comprehensive progress bar edge case coverage
- **Major Performance Improvements**: Achieved dramatic performance gains across all core text processing functions
  - Text wrapping function: 12.5x performance improvement (9,820ms → 786ms for 5K characters)
  - Whitespace removal function: 31x performance improvement (8,596ms → 275ms for 5K characters)
  - End-to-end text processing: 3.8x performance improvement (1,445ms → 379ms for 1K characters)
- Replaced character-by-character processing with efficient chunk-based algorithms
- Optimized text wrapping with pre-computed line lengths and efficient oversized word splitting
- Implemented fast-path optimizations for inputs without special characters

### Fixed
- Resolved all tr command dependencies with optimized pure shell implementations
- Fixed misleading documentation comments in progress bar function
- Improved performance of newline-to-space and whitespace removal operations
- Fixed POSIX shell compatibility by eliminating bash-specific parameter expansions
- Resolved "Bad substitution" errors in strict POSIX shell environments
- Improved `lib_msg_prompt_yn` API design by switching from string output to shell exit codes
- Eliminated O(n²) complexity bottlenecks in text processing functions

## [1.2.1] - 2025-05-15

### Fixed
- Fixed text wrapping calculation for multibyte UTF-8 characters
- Corrected terminal width detection when COLUMNS variable is unset
- Fixed rare case where ANSI stripping could fail with certain escape sequences

### Changed
- Improved performance of `lib_msg_strip_ansi` function

## [1.2.0] - 2025-04-02

### Added
- New `lib_msg_progress_bar` function for displaying text-based progress bars
- Added support for bright (high-intensity) ANSI colors
- Exposed additional SGR constants for more styling options

### Changed
- Optimized `lib_msg_get_wrapped_text` for better performance with long texts
- Enhanced TTY detection for unusual terminal configurations

## [1.1.0] - 2025-02-17

### Added
- New prompt functions for interactive user input
  - `lib_msg_prompt` for general text input
  - `lib_msg_prompt_yn` for yes/no questions
- Added `lib_msg_create_prefix` function for custom message prefixes
- New convenience function `lib_msg_get_style` for predefined styles

### Changed
- Improved color detection logic
- Better handling of sourced vs. executed script contexts

### Fixed
- Fixed ANSI color leakage when messages were truncated
- Corrected behavior of `die` function in sourced scripts

## [1.0.0] - 2025-01-10

### Added
- Initial stable release with core functionality
- Basic message functions: `msg`, `info`, `warn`, `err`, `die`
- Support for no-newline variants: `msgn`, `infon`, `warnn`, `errn`
- Terminal detection functions
- ANSI color support with automatic detection
- Text wrapping based on terminal width
- Environment variable controls for customization

### Changed
- Finalized public API

## [0.9.0] - 2024-12-15

### Added
- Beta release with most core functionality
- POSIX sh compatibility
- Dynamic terminal width detection
- Basic color support

[Unreleased]: https://github.com/ekartashov/lib_msg.sh/compare/v1.2.1...HEAD
[1.2.1]: https://github.com/ekartashov/lib_msg.sh/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/ekartashov/lib_msg.sh/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/ekartashov/lib_msg.sh/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/ekartashov/lib_msg.sh/compare/v0.9.0...v1.0.0
[0.9.0]: https://github.com/ekartashov/lib_msg.sh/releases/tag/v0.9.0