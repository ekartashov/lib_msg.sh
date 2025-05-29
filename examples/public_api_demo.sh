#!/bin/sh
# Example script demonstrating the public API for lib_msg.sh

# Source the lib_msg.sh library
. "$(dirname "$0")/../lib_msg.sh"

# Set script name for better prefix display
SCRIPT_NAME="public_api_demo.sh"

# ========================================================================
# --- Terminal and Color Capability Detection ---
# ========================================================================

echo "== Terminal and Color Detection =="
echo "stdout is a TTY: $(lib_msg_stdout_is_tty)"
echo "stderr is a TTY: $(lib_msg_stderr_is_tty)"
echo "Terminal width: $(lib_msg_get_terminal_width) columns"
echo "Colors enabled: $(lib_msg_colors_enabled)"
echo ""

# ========================================================================
# --- Text Styling Demo ---
# ========================================================================

echo "== Text Styling =="

# Get predefined styles
error_style=$(lib_msg_get_style "error")
warning_style=$(lib_msg_get_style "warning")
info_style=$(lib_msg_get_style "info")
success_style=$(lib_msg_get_style "success")
highlight_style=$(lib_msg_get_style "highlight")
dim_style=$(lib_msg_get_style "dim")

# Show the styles
echo "Predefined styles:"
echo "$(lib_msg_apply_style "Error style" "$error_style")"
echo "$(lib_msg_apply_style "Warning style" "$warning_style")"
echo "$(lib_msg_apply_style "Info style" "$info_style")"
echo "$(lib_msg_apply_style "Success style" "$success_style")"
echo "$(lib_msg_apply_style "Highlight style" "$highlight_style")"
echo "$(lib_msg_apply_style "Dim style" "$dim_style")"
echo ""

# Custom styles
echo "Custom styles:"
custom_style=$(lib_msg_build_style_sequence "$_LIB_MSG_SGR_ITALIC" "$_LIB_MSG_SGR_FG_MAGENTA")
echo "$(lib_msg_apply_style "Italic magenta text" "$custom_style")"

bg_style=$(lib_msg_build_style_sequence "$_LIB_MSG_SGR_FG_BLACK" "$_LIB_MSG_SGR_BG_BRIGHT_WHITE")
echo "$(lib_msg_apply_style "Black text on bright white background" "$bg_style")"
echo ""

# ========================================================================
# --- Text Processing Demo ---
# ========================================================================

echo "== Text Processing =="

# Text with ANSI codes
styled_text=$(lib_msg_apply_style "This text has styling" "$error_style")
echo "Original: $styled_text"
echo "Stripped: $(lib_msg_strip_ansi "$styled_text")"
echo ""

# Text wrapping
long_text="This is a long paragraph of text that demonstrates the text wrapping capabilities of the lib_msg.sh library. It should automatically wrap to fit within the specified width or the terminal width if available."
echo "Wrapped text (50 columns):"
echo "$(lib_msg_get_wrapped_text "$long_text" 50)"
echo ""

# ========================================================================
# --- Custom Message Formatting ---
# ========================================================================

echo "== Custom Message Formatting =="

# Create custom prefixes
info_prefix=$(lib_msg_create_prefix "INFO" "$info_style" "")
warn_prefix=$(lib_msg_create_prefix "WARN" "$warning_style" "")
error_prefix=$(lib_msg_create_prefix "ERROR" "$error_style" "")

# Output messages with custom prefixes
lib_msg_output "This is an information message" "$info_prefix"
lib_msg_output "This is a warning message" "$warn_prefix"
lib_msg_output "This is an error message" "$error_prefix" "" "true" # to stderr
echo ""

# ========================================================================
# --- Progress Bar Demo ---
# ========================================================================

echo "== Progress Bar Demo =="

# Simulate a long operation with progress bar
echo "Processing items:"
for i in 1 2 3 4 5 6 7 8 9 10; do
    progress=$(lib_msg_progress_bar "$i" 10)
    printf "\r%s" "$progress"
    sleep 0.3
done
echo "" # Final newline after progress bar
echo ""

# ========================================================================
# --- Interactive Prompt Demo ---
# ========================================================================

echo "== Interactive Prompts =="
echo "NOTE: This section requires user input."
echo "      Press Ctrl+C to skip if running non-interactively."
echo ""

# Simple prompt with default value
echo "Prompt with default value:"
name=$(lib_msg_prompt "Enter your name" "User")
echo "Hello, $name!"
echo ""

# Yes/No prompt
echo "Yes/No prompt:"
if lib_msg_prompt_yn "Would you like to continue?" "" "y" ; then
    echo "You chose to continue!"
else
    echo "You chose not to continue."
fi
echo ""

# Yes/No prompt with styling
echo "Yes/No prompt with styling:"
if lib_msg_prompt_yn "Do you want to see more examples?" "bracketed" "n"; then
    echo "Great! Continuing with more examples..."
else
    echo "Skipping additional examples."
fi
echo ""

# ========================================================================
# --- Standard Message Functions ---
# ========================================================================

echo "== Standard Message Functions =="
msg "This is a standard message"
info "This is an information message"
warn "This is a warning message"
err "This is an error message"
echo ""

# ========================================================================
# --- Additional Functions Demo ---
# ========================================================================

echo "== Additional Functions Demo =="
msgn "This message has no newline"
echo " (continued on same line)"

infon "Information with no newline"
echo " (continued on same line)"

warnn "Warning with no newline"
echo " (continued on same line)"

errn "Error with no newline"
echo " (continued on same line)"

echo "The die() function would terminate the script, so it's commented out:"
echo "# die 2 \"This would exit with code 2\""
echo ""

# ========================================================================
# --- Advanced Styling and Custom Output Demo ---
# ========================================================================

echo "== Advanced Styling Demo =="

# Show all predefined styles
echo "All predefined styles:"
for style in error warning info success highlight dim; do
    style_seq=$(lib_msg_get_style "$style")
    styled_text=$(lib_msg_apply_style "Sample $style text" "$style_seq")
    echo "  $styled_text"
done
echo ""

# Custom prefix creation
echo "Custom prefix examples:"
error_prefix=$(lib_msg_create_prefix "ERROR" "$(lib_msg_get_style error)")
warn_prefix=$(lib_msg_create_prefix "WARN" "$(lib_msg_get_style warning)")
info_prefix=$(lib_msg_create_prefix "INFO" "$(lib_msg_get_style info)")

lib_msg_output "This is a custom error message" "$error_prefix"
lib_msg_output "This is a custom warning message" "$warn_prefix"
lib_msg_output "This is a custom info message" "$info_prefix"
echo ""

# ========================================================================
# --- Advanced Progress Bar Demo ---
# ========================================================================

echo "== Advanced Progress Bar Demo =="

# Different progress bar configurations
echo "Standard progress bar (20 chars):"
echo "$(lib_msg_progress_bar 7 10)"
echo ""

echo "Wide progress bar (40 chars):"
echo "$(lib_msg_progress_bar 7 10 40)"
echo ""

echo "Custom characters progress bar:"
echo "$(lib_msg_progress_bar 3 5 25 "█" "░")"
echo ""

echo "Progress simulation with custom width:"
for i in 0 1 2 3 4 5; do
    progress=$(lib_msg_progress_bar "$i" 5 30)
    printf "\r%s" "$progress"
    sleep 0.2
done
echo "" # Final newline
echo ""

# ========================================================================
# --- Text Processing Demo ---
# ========================================================================

echo "== Text Processing Demo =="

# ANSI stripping
styled_text=$(lib_msg_apply_style "This text has ANSI codes" "$(lib_msg_get_style highlight)")
echo "Text with ANSI: $styled_text"
echo "Text stripped: $(lib_msg_strip_ansi "$styled_text")"
echo ""

# Text wrapping at different widths
# Note: Using a shorter text to avoid shell compatibility issues with very long texts
long_text="This demonstrates text wrapping in lib_msg.sh with proper word boundaries."

echo "Text wrapping demo:"
echo "Original text: $long_text"
echo ""
echo "Wrapped at 30 columns:"
wrapped_30=$(printf "%s" "$long_text" | sed 's/\(.\{1,30\}\) /\1\n/g')
echo "$wrapped_30"
echo ""
echo "Wrapped at 50 columns:"
wrapped_50=$(printf "%s" "$long_text" | sed 's/\(.\{1,50\}\) /\1\n/g')
echo "$wrapped_50"
echo ""
echo "Note: Text wrapping function lib_msg_get_wrapped_text() is available"
echo "but may have shell compatibility issues in some environments."
echo ""

# ========================================================================
# --- Advanced Output Control Demo ---
# ========================================================================

echo "== Advanced Output Control Demo =="

# Output to stderr
echo "Demonstrating output to stderr (check your terminal for red text on stderr):"
lib_msg_output "This message goes to stderr" "" "$(lib_msg_get_style error)" "true"
echo ""

# No-newline output
echo "No-newline output examples:"
lib_msg_output_n "First part"
lib_msg_output_n " - middle part"
lib_msg_output " - final part with newline"
echo ""

# ========================================================================
# --- Environment Information Demo ---
# ========================================================================

echo "== Environment Information =="
echo "Current library state:"
echo "  Colors enabled: $(lib_msg_colors_enabled)"
echo "  Terminal width: $(lib_msg_get_terminal_width)"
echo "  stdout is TTY: $(lib_msg_stdout_is_tty)"
echo "  stderr is TTY: $(lib_msg_stderr_is_tty)"
echo ""

# Force terminal width update and show result
echo "Force updating terminal width..."
new_width=$(lib_msg_update_terminal_width)
echo "Updated terminal width: $new_width"
echo ""

echo "Demo completed successfully!"
echo "All available lib_msg.sh functionality has been demonstrated."
