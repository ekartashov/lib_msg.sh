# Project Analysis and Improvement Plan for `lib_msg.sh`

## 1. Current State & Strengths

*   **Overview:** `lib_msg.sh` is a POSIX-compliant shell library for versatile message formatting, TTY detection, intelligent text wrapping, and colored output.
*   **Key Strengths:**
    *   **POSIX Compliance:** Recent refactoring has solidified this.
    *   **Rich Functionality:** Comprehensive messaging functions (`msg`, `info`, `warn`, `err`, `die`).
    *   **TTY Awareness & Adaptability:** Smart handling of colors and wrapping based on TTY status, with testable overrides.
    *   **Optimized Implementations:** Leverages `sed` and `awk` with pure POSIX `sh` fallbacks.
    *   **Robust BATS Test Suite:** Extensive tests using `bats-assert`, `bats-support`, and `bats-mock`.
    *   **Clear Documentation:** `README.md` is informative.
    *   **Contextual `die` Function:** Intelligently exits or returns.

## 2. Identified Weak Points & Areas for Improvement (Revised)

*   **A. Test Suite Robustness & Complexity:**
    *   **Issue 1 (File-Level Setup/Teardown):** The `setup_file` / `teardown_file` logic in `test/lib_msg.bats` for `stty` and `COLUMNS` management is complex, relying on environment variables passed from individual tests to control its TTY-dependent behavior. This can lead to brittleness.
    *   **Issue 2 (Global `lines` Array for Test Compatibility):** [DONE] Previously, the library converted its internal RS-delimited string to a bash array in `_lib_msg_wrap_text()` for BATS test compatibility. This workaround has been removed.
    *   **Proposed Solution (A1):** [DONE] `setup_file` has been simplified. Individual tests now use `simulate_tty_conditions` to establish their specific TTY states.
    *   **Proposed Solution (A2):** [DONE] BATS tests for `_lib_msg_wrap_text` now assert against the `_LIB_MSG_RS`-delimited string output directly, and the array conversion layer in `_lib_msg_wrap_text` has been removed.

*   **B. Complexity of Shell-Based Fallbacks:**
    *   **Issue:** Pure shell fallbacks (`_lib_msg_strip_ansi_shell()`, `_lib_msg_wrap_text_sh()`) are inherently complex and harder to maintain than `sed`/`awk` versions. The `fold` utility is not a suitable alternative due to the requirement for prefix-aware indentation on wrapped lines, which `fold` does not natively support.
    *   **Proposed Solution:** Continue to maintain these fallbacks for POSIX purity. Schedule periodic reviews for correctness. Emphasize in documentation that `sed` and `awk` are recommended for optimal performance.

*   **C. ANSI Wrapping Limitation:**
    *   **Issue:** As per `README.md`, if messages are colored *before* wrapping, ANSI codes affect length calculation, potentially leading to slightly off visual wrapping. The library mitigates this by coloring *after* wrapping.
    *   **Proposed Solution:** Maintain the current effective strategy of coloring after wrapping. Ensure this is clearly documented.

*   **D. Submodule Update Process:**
    *   **Issue:** The script for updating BATS helper submodules in `README.md` is manual.
    *   **Proposed Solution:** Move this to an executable helper script (e.g., `scripts/update_submodules.sh`) and document its use.

*   **E. `COLUMNS` Variable Reliance:**
    *   **Issue:** Relies on the `COLUMNS` environment variable, which can be unreliable in some environments (`README.md`).
    *   **Proposed Solution:** The current approach (using `COLUMNS` with a fallback to disable wrapping) is standard and acceptable. No immediate change is needed here beyond what's done for testing.

## 3. Proposed Action Plan (Prioritized)

1.  **High Priority: Enhance Test Suite Robustness & Maintainability (COMPLETED)**
    *   **Task 1.1:** [DONE] Refactor BATS assertions for `_lib_msg_wrap_text` to work directly with `_LIB_MSG_RS`-delimited strings.
    *   **Task 1.2:** [DONE] Simplify `_lib_msg_wrap_text()` by removing the bash array conversion logic.
    *   **Task 1.3:** [DONE] Refactor `setup_file`/`teardown_file` in `test/lib_msg.bats` to decouple its `stty` operations from individual test TTY states.

2.  **Medium Priority: Improve Developer Experience & Documentation**
    *   **Task 2.1:** [DONE] Create `scripts/update_submodules.sh` from the README snippet.
    *   **Task 2.2:** [DONE] Update `README.md` to refer to the new script and re-emphasize the performance benefits of having `sed` and `awk`.

3.  **Low Priority: Ongoing Maintenance**
    *   **Task 3.1:** Periodically review the pure shell fallback functions (`_lib_msg_strip_ansi_shell()`, `_lib_msg_wrap_text_sh()`) for correctness.

## 4. Mermaid Diagram: Conceptual Flow of Improvements

```mermaid
graph TD
    A[Project: lib_msg.sh] --> B{Analysis};
    B --> C[Weak Point: Test Suite Complexity];
    B --> D[Weak Point: Shell Fallback Complexity];
    B --> E[Weak Point: Manual Submodule Updates];

    C --> C1[Action: Refactor BATS Assertions for RS-strings];
    C --> C2[Action: Simplify _lib_msg_wrap_text (remove array hack)];
    C --> C3[Action: Decouple setup_file TTY logic];
    C1 & C2 & C3 --> F[Outcome: More Robust & Maintainable Tests];

    D --> D1[Action: Periodic Review of Fallbacks];
    D1 --> G[Outcome: Ensured Correctness of Fallbacks];

    E --> E1[Action: Create update_submodules.sh script];
    E1 --> H[Outcome: Easier Submodule Management];

    F & G & H --> I[Improved lib_msg.sh Ecosystem];