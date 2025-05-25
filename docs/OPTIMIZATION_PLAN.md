# Code Optimization Plan for `lib_msg.sh`

**Date:** 2025-05-25

**Overall Principle:**
Leverage high-performance external commands (`sed`, `tr`) where they provide clear benefits, while optimizing pure shell implementations for cases where external commands cannot be used. Current focus areas:

1. **Text Wrapping (Completed)**: Standardize on the pure POSIX shell implementation (`_lib_msg_wrap_text_sh`), as it has demonstrated competitive or superior performance compared to `awk`.

2. **ANSI Stripping (In Progress)**: Optimize the shell implementation of ANSI stripping to reduce the extreme performance gap between the shell fallback and the `sed` implementation.

---

## OPTIMIZATION AREA 1: Shell-Only Text Wrapping (COMPLETED)

**Phase 1: Analysis & Confirmation (Completed)**

*   **Deep Dive into `lib_msg.sh` Dispatch Logic:**
    *   Confirmed that `sed` and `tr` are correctly prioritized for ANSI stripping and basic string transformations.
    *   Identified that `_lib_msg_wrap_text()` currently prioritizes `awk`.
*   **Performance Test Data Review:**
    *   Confirmed shell implementation for text wrapping is generally faster or comparable to `awk`.
*   **Complexity Analysis:**
    *   Acknowledged the inherent complexity of the shell text wrapper but accepted it due to its performance.

**Phase 2: Code Implementation - Refactoring `lib_msg.sh` (Completed)**

1.  **Standardize on Shell-Only Text Wrapping:**
    *   **Modify `_lib_msg_wrap_text()` (Dispatcher Function in `lib_msg.sh`):**
        *   Remove the `_LIB_MSG_FORCE_TEXT_WRAP_IMPL` environment variable check (or simplify if it's kept for forcing only the shell version, though likely remove entirely for this part).
        *   Remove the `_lib_msg_has_command awk` check.
        *   Ensure `_lib_msg_wrap_text()` *always and only* calls `_lib_msg_wrap_text_sh()`.
    *   **Delete `_lib_msg_wrap_text_awk()` Function:**
        *   Remove the entire `_lib_msg_wrap_text_awk()` function definition from `lib_msg.sh`.

2.  **Verify Other Dispatchers (No Changes Expected):**
    *   Briefly re-verify that the dispatch logic for `_lib_msg_strip_ansi()`, `_lib_msg_tr_newline_to_space()`, and `_lib_msg_tr_remove_whitespace()` remains untouched and correctly prioritizes `sed` and `tr`.

**Phase 3: Test Suite Adjustments (Completed)**

1.  **Remove `awk`-Specific Text Wrapping Tests:**
    *   Delete the test file `test/04_text_wrapping_awk_tests.bats` entirely.
2.  **Update Dispatcher Tests:**
    *   Modify `test/06_text_wrapping_dispatcher_tests.bats`:
        *   Remove any tests that specifically check if `awk` is chosen when available.
        *   Remove tests that compare `awk` output against shell output.
        *   Ensure remaining tests thoroughly validate the shell wrapper via the main `_lib_msg_wrap_text()` entry point.
3.  **Run All Tests:**
    *   Execute `bats test/` to ensure all unit tests pass.
    *   Execute `bats test/13_performance_tests.bats`. The text wrapping performance results will now solely reflect the shell implementation.

**Phase 4: Documentation Updates (Completed)**

1.  **Update `README.md`:**
    *   In the "How It Works" section, remove references to `awk` for text wrapping. State that it uses a pure shell implementation.
    *   In the "Performance Considerations" section:
        *   Remove `awk` from the list of beneficial external commands for text wrapping.
        *   Update the explanation to highlight that the shell implementation is used for its good performance and to ensure POSIX compliance without external dependencies for this specific feature.
2.  **Update `docs/TESTING.md`:**
    *   In the "Performance Tests" section, update the description for "Text wrapping" to indicate it now refers to the performance of the (sole) shell implementation, not a comparison.
    *   Remove any mentions of comparing shell vs. `awk` for text wrapping in the "Performance Test Results" summary.

---

## OPTIMIZATION AREA 2: ANSI Stripping Performance (IN PROGRESS)

**Phase 1: Analysis & Confirmation (Completed)**

* **Performance Test Results Analysis:**
    * Observed extreme performance gap: Shell implementation (17412.59 ms) vs. sed implementation (5.85 ms).
    * Identified ANSI stripping as the next critical performance bottleneck after text wrapping optimization.
* **Code Analysis of `_lib_msg_strip_ansi_shell()`:**
    * Identified inefficient character-by-character processing with complex nested loops.
    * Found redundant string operations and excessive string concatenation.
    * Identified the shell ESC sequence parsing algorithm as overly complex.

**Phase 2: Code Implementation - Optimizing `_lib_msg_strip_ansi_shell()` (In Progress)**

1. **Algorithm Optimization Strategy:**
   * Replace character-by-character processing with more efficient chunk-based processing.
   * Use parameter expansion to split on escape character and process in larger chunks.
   * Simplify the ANSI sequence detection and removal logic.
   * Eliminate multiple nested loops.

2. **Implementation Details:**
   * Process input text in segments divided by escape characters.
   * Implement a more efficient state machine for ANSI sequence detection.
   * Preserve the functional correctness while improving time complexity.
   * Maintain POSIX compatibility for the shell fallback implementation.

3. **Error Handling and Edge Cases:**
   * Ensure proper handling of incomplete ANSI sequences.
   * Handle ESC characters not followed by valid CSI sequences.
   * Maintain behavior consistency with the original implementation.

**Phase 3: Testing (Planned)**

1. **Functional Testing:**
   * Run `test/02_ansi_stripping_tests.bats` to ensure the optimized implementation maintains correctness.
   * Verify handling of all edge cases including incomplete sequences.

2. **Performance Testing:**
   * Execute `test/13_performance_tests.bats` to measure performance improvements.
   * Compare optimized shell implementation against the original shell implementation.
   * Document performance gains while maintaining the sed implementation as primary when available.

**Phase 4: Documentation Updates (Planned)**

1. **Update Performance Documentation:**
   * Document the performance improvements in the ANSI stripping shell implementation.
   * Explain the optimization approach and its benefits.

2. **Review Dispatcher Logic:**
   * Ensure the dispatcher function (`_lib_msg_strip_ansi()`) still correctly prioritizes sed when available.
   * Confirm documentation reflects the optimized fallback strategy.

**Mermaid Diagram of the ANSI Stripping Optimization:**

```mermaid
graph TD
    A[Start: Optimize ANSI Stripping Performance] --> B(Phase 1: Analysis & Confirmation);
    B --> B1[Identify Performance Gap: Shell vs. sed];
    B --> B2[Analyze Inefficiencies in Shell Implementation];
    B --> B3[Determine Optimization Strategy];
    
    B3 --> C(Phase 2: Code Implementation);
    C --> C1[Implement Chunk-based Processing];
    C --> C2[Optimize ANSI Sequence Detection];
    C --> C3[Eliminate Nested Loops];
    C --> C4[Test Optimal Balance of Speed vs. Readability];
    
    C4 --> D(Phase 3: Testing);
    D --> D1[Run Functional Tests];
    D --> D2[Run Performance Tests];
    D --> D3[Compare Results with Original Implementation];
    
    D3 --> E(Phase 4: Documentation);
    E --> E1[Update Performance Documentation];
    E --> E2[Ensure Dispatcher Logic Maintains Priority];
    E2 --> F[End: Optimization Complete, ANSI Stripping Performance Improved];
```

---

## Next Optimization Targets

After completing the ANSI stripping optimization, we will analyze performance test results to identify any remaining bottlenecks in shell implementations that serve as fallbacks when external commands are not available. Potential candidates include:

1. Other string transformation functions (if they show significant performance issues)
2. Message formatting and indentation logic
3. Terminal width calculations and handling

Our goal remains to maintain a POSIX-compliant shell library with optimal performance, using efficient algorithms and falling back to pure shell implementations only when necessary.