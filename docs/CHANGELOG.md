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