# Pure Shell Fallback Functions Review

This document provides a review of the pure shell fallback implementations in `lib_msg.sh`, as specified in Task 3.1 of the improvement plan. These functions provide critical functionality when preferred commands like `sed` or `awk` are unavailable on the target system.

## Shell Implementation Functions

The library contains the following pure shell fallback functions:

1. `_lib_msg_strip_ansi_shell()` (lines 97-163): Used when `sed` is unavailable
2. `_lib_msg_wrap_text_sh()` (lines 185-321): Used when `awk` is unavailable

## 1. ANSI Stripping (`_lib_msg_strip_ansi_shell`)

This function removes ANSI escape sequences from text using character-by-character processing.

### Analysis

- **Correctness**: The function correctly handles the standard ANSI escape sequence format (`ESC[parameters;commandChar`)
- **Edge Cases**: Handles various edge cases with escape sequences appropriately
- **Complexity**: The nested loop implementation is complex but necessary for POSIX shell compatibility
- **Algorithm**: Uses a state machine approach to identify and skip escape sequences

### Recommendations

- **Documentation**: Add more comments explaining the character-by-character loop logic for better maintainability
- **Testing**: Consider adding test cases for unusual or malformed ANSI sequences
- **Variable Names**: Some variable names could be shortened for readability while maintaining clarity

## 2. Text Wrapping (`_lib_msg_wrap_text_sh`)

This function wraps text to fit within specified width constraints without using arrays (for POSIX compatibility).

### Analysis

- **Special Cases**: Correctly handles empty input, whitespace-only input, and no-wrap (width ≤ 0) cases
- **Long Word Handling**: Properly processes long words that need to be broken across lines
- **Line Delimiting**: Uses record separator (`_LIB_MSG_RS`) as an elegant solution to the no-arrays constraint

### Potential Improvements

- **Code Duplication**: The long word handling code is duplicated in lines 233-260 and 275-303, which could be refactored
- **Edge Case Documentation**: Add more comments explaining the complex edge case on line 314
- **Variable Naming**: Some variables like `_build_chunk_temp_word_copy` have overly long names

## Other Shell Functions

- `_lib_msg_is_return_valid()` (lines 554-560): Correctly detects if the function is sourced or executed
- `_lib_msg_init_detection()` (lines 13-45): Properly initializes TTY detection with fallbacks and handles environment variables

## Overall Assessment

The pure shell fallback functions are well-implemented and handle edge cases appropriately. The implementation ensures POSIX compatibility while providing robust functionality. The code prioritizes correctness over simplicity, which is appropriate for a library that needs to work across diverse environments.

### Recommendations Summary

1. **Add Documentation**: More inline comments explaining complex logic, particularly:
   - The character-by-character processing in `_lib_msg_strip_ansi_shell()`
   - The complex edge case in `_lib_msg_wrap_text_sh()` on line 314

2. **Testing**: Create additional test cases for edge cases:
   - Added new test file `test/pure_shell_fallback_tests.bats` with dedicated tests for shell fallback functions
   - Include tests with various ANSI sequences and Unicode characters
   - Add tests for comparison between shell and optimized implementations

3. **Refactoring**: Consider extracting duplicated long word handling logic into a helper function:
   ```sh
   # Example helper function
   _lib_msg_wrap_long_word() {
       local _word="$1"
       local _max_width="$2"
       local _result=""
       
       while [ "${#_word}" -gt "$_max_width" ]; do
           _chunk="${_word:0:$_max_width}"
           _result="${_result}${_LIB_MSG_RS}${_chunk}"
           _word="${_word:$_max_width}"
       done
       
       # Return the result and remaining word
       printf "%s\n%s" "$_result" "$_word"
   }
   ```

4. **Naming**: Revisit variable names for improved readability:
   - Rename `_build_chunk_temp_word_copy` to `_remain_word` or similar
   - Rename `_char_count_for_chunk` to `_chunk_len` for brevity

No critical issues were found that would affect functionality or compatibility.

## Performance Considerations

The pure shell fallback functions prioritize compatibility over performance. For systems where performance is critical:

1. Pre-compute terminal width at script start rather than dynamically
2. Prefer the optimized implementations where available (`sed` and `awk`)
3. Consider caching results of ANSI stripping for repeated operations on the same strings
4. When wrapping very long text, consider using a chunking approach to reduce nested loop iterations

_Review completed: May 20, 2025_