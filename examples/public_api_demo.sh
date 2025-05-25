#!/bin/sh
# Example script demonstrating the public API for lib_msg.sh

# Source the lib_msg.sh library
. "$(dirname "$(dirname "$0")")/lib_msg.sh"

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
if lib_msg_prompt_yn "Would you like to continue?" "y"; then
    echo "You chose to continue!"
else
    echo "You chose not to continue."
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

echo "Demo completed successfully!"