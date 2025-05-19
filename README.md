# lib_msg.sh - Shell Message Formatting Library

`lib_msg.sh` is a POSIX-compliant shell library for formatting messages, detecting TTY, wrapping text to terminal width, and displaying colored output.

## Features

-   Standardized message prefixes for information (`I:`), errors (`E:`), warnings (`W:`), and general messages.
-   Functions for messages with and without trailing newlines (e.g., `msg` vs `msgn`).
-   Automatic TTY detection for stdout and stderr.
-   Text wrapping based on terminal width (via `COLUMNS` environment variable) if outputting to a TTY.
-   ANSI color support for messages if outputting to a TTY.
-   `die` function to print an error message and exit with a specified code (or return if sourced).

## Usage

1.  **Source the Library:**
    To use `lib_msg.sh` in your shell script, source it at the beginning:

    ```sh
    #!/bin/sh

    # Adjust path to lib_msg.sh as necessary
    # shellcheck source=./lib_msg.sh
    . "./lib_msg.sh"

    # Your script logic here
    msg "Script started."
    info "Here's some information."
    warn "Something to be cautious about."
    err "An error occurred (but not fatal)."
    # die 1 "A fatal error occurred, exiting."
    ```

2.  **Set `SCRIPT_NAME` (Optional but Recommended):**
    The library uses the `SCRIPT_NAME` environment variable for message prefixes. If not set, it defaults to `lib_msg.sh`. It's good practice to set this in your main script:

    ```sh
    export SCRIPT_NAME="my_script.sh"
    # or SCRIPT_NAME=$(basename "$0")
    ```

### Available Functions

#### Standard Output (stdout)

-   `msg "message"`: Prints a general message with a prefix and newline.
-   `msgn "message"`: Prints a general message with a prefix but no trailing newline.
-   `info "message"`: Prints an information message with a blue "I: " prefix and newline.
-   `infon "message"`: Prints an information message with a blue "I: " prefix but no trailing newline.

#### Error Output (stderr)

-   `err "message"`: Prints an error message with a red "E: " prefix and newline.
-   `errn "message"`: Prints an error message with a red "E: " prefix but no trailing newline.
-   `warn "message"`: Prints a warning message with a yellow "W: " prefix and newline.
-   `warnn "message"`: Prints a warning message with a yellow "W: " prefix but no trailing newline.
-   `die <exit_code> "message"`: Prints an error message with a red "E: " prefix, then exits the script with `<exit_code>`. If the function is called from a sourced script, it returns with the error code instead of exiting.

## Testing

The library includes a test suite using [BATS (Bash Automated Testing System)](https://github.com/bats-core/bats-core).

1.  **Install BATS:**
    If you don't have BATS installed, you can install it using your system's package manager.

    *   **Ubuntu/Debian:**
        ```sh
        sudo apt-get update
        sudo apt-get install bats
        ```
    *   **macOS (using Homebrew):**
        ```sh
        brew install bats-core
        ```
    *   **Other systems:** Refer to the [BATS installation guide](https://bats-core.readthedocs.io/en/stable/installation.html).

2.  **Initialize Required Submodules:**
    The test suite relies on several BATS helper libraries that are included as Git submodules:
    
    ```sh
    git submodule init
    git submodule update
    ```

3.  **Run Tests:**
    Navigate to the root directory of this project (where `lib_msg.sh` and the `test` directory are located) and run:

    ```sh
    bats test/lib_msg.bats
    ```

    This will execute all tests defined in [`test/lib_msg.bats`](test/lib_msg.bats:0).

### Updating BATS Helper Submodules

The BATS helper libraries (`bats-assert`, `bats-support`, `bats-mock`) are included as Git submodules in the `test/libs/` directory. To update them to their latest tagged versions:

1.  **Update all submodules to the latest commit on their tracked branch:**
    ```sh
    git submodule update --remote --merge
    ```

2.  **Checkout the latest tag for each helper:**
    You can use the following script snippet to find and checkout the latest semantic version tag for each submodule. Run this from the project root:

    ```sh
    #!/bin/sh

    update_submodule_to_latest_tag() {
        submodule_path="$1"
        echo "Updating submodule: $submodule_path"

        if [ ! -d "$submodule_path" ]; then
            echo "Error: Submodule path $submodule_path does not exist."
            return 1
        fi

        (
            cd "$submodule_path" || exit 1
            # Fetch all tags from remote
            git fetch --tags
            # Get the latest semantic version tag (vX.Y.Z)
            # This sorts tags that look like versions and picks the last one.
            # It assumes tags are like v0.3.0, v1.2.5 etc.
            latest_tag=$(git tag -l 'v*' | sort -V | tail -n 1)

            if [ -z "$latest_tag" ]; then
                echo "No version tags (v*) found for $submodule_path. Skipping tag checkout."
                # Optionally, you might want to checkout a default branch here
                # git checkout main # or master, or the default branch of the submodule
            else
                echo "Checking out latest tag: $latest_tag"
                git checkout "$latest_tag"
            fi
        )
        echo "------------------------------------"
    }

    update_submodule_to_latest_tag "test/libs/bats-assert"
    update_submodule_to_latest_tag "test/libs/bats-support"
    update_submodule_to_latest_tag "test/libs/bats-mock"

    echo "Submodule update process complete. Review changes and commit the updated submodule references:"
    echo "git add test/libs/bats-assert test/libs/bats-support test/libs/bats-mock"
    echo "git commit -m \"Update BATS helper submodules to latest tags\""
    ```

    **Note:** This script assumes that the latest desired version is always the highest semantic version tag. Review the tags and release notes for each library if you need a specific version other than the latest.

## How It Works

-   **TTY Detection:** On initialization (`_lib_msg_init_detection`), the library checks if stdout (file descriptor 1) and stderr (file descriptor 2) are connected to a terminal using `[ -t 1 ]` and `[ -t 2 ]`. This can be overridden with the environment variables `LIB_MSG_FORCE_STDOUT_TTY` and `LIB_MSG_FORCE_STDERR_TTY` (useful for testing).
-   **Terminal Width:** If a TTY is detected, it attempts to get the terminal width from the `COLUMNS` environment variable. If `COLUMNS` is not set or invalid, wrapping is disabled.
-   **Color Initialization:** If a TTY is detected, ANSI escape codes for various colors and styles are initialized (`_lib_msg_init_colors`). Otherwise, color variables remain empty, effectively disabling colored output.
-   **Wrapping Logic (`_lib_msg_wrap_text`):**
    -   If wrapping is enabled and necessary, text is split into words.
    -   Words are appended to the current line if they fit within the calculated maximum content width (terminal width minus prefix length).
    -   If a word doesn't fit, the current line is printed, and the word starts a new line.
    -   Very long words that exceed the maximum content width by themselves are forcibly broken into chunks.
-   **Core Printing Logic (`_print_msg_core`):**
    -   This internal function handles all message printing.
    -   It determines the correct output stream (stdout/stderr).
    -   Applies color using `_lib_msg_colorize` if a color code is provided and the stream is a TTY.
    -   If the stream is a TTY and terminal width is known, it uses `_lib_msg_wrap_text` to wrap the message content. Each wrapped line is then prefixed.
    -   If no TTY or no width, it prints the message with the prefix directly.
    -   Handles whether a final newline should be printed.
-   **Context-Aware Exiting (`die` function):**
    -   Detects whether it's being called from a sourced context or directly executed script using `_lib_msg_is_return_valid()`.
    -   If called in a sourced script/function, uses `return` with the error code to allow the calling script to continue.
    -   If called in a directly executed script, uses `exit` to terminate the entire script.

## Limitations and Known Issues

-   **ANSI in Wrapped Text:** The current text wrapping logic in `_lib_msg_wrap_text` is not fully ANSI-aware. If a message is colored *before* wrapping, the ANSI escape codes contribute to the string length seen by the wrapper. This can lead to lines being wrapped slightly shorter than expected visually. To mitigate this, the library handles ANSI stripping for length calculations using `_lib_msg_strip_ansi_shell`.
-   **Complex Scripts in Prefixes:** Prefixes are currently treated as plain text for length calculation. If prefixes contain ANSI codes, the library handles this correctly by stripping ANSI codes when calculating lengths.
-   **`COLUMNS` Variable:** Relies on the `COLUMNS` environment variable being correctly set and updated for accurate terminal width. Some terminal emulators or environments might not update this reliably.
-   **Word Splitting:** The wrapper splits words based on single spaces. Multiple consecutive spaces in the input text might lead to slightly different spacing in the wrapped output compared to the input, as empty "words" might be processed.