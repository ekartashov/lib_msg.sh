#!/usr/bin/env python3
from pathlib import Path
from rich.console import Console
from rich.syntax import Syntax


def main():
    # Path to your Usage.sh script
    script_path = Path(__file__).parent / "Usage.sh"

    # Read the script contents
    code = script_path.read_text()

    # Choose a nicer syntax theme
    theme = "native"

    # Create a Syntax object for Bash highlighting with line numbers
    syntax = Syntax(
        code,
        "bash",
        line_numbers=True,
        word_wrap=False,
        theme=theme,
    )

    # Determine the maximum line width (in characters)
    max_line_length = max((len(line) for line in code.splitlines()), default=0)
    # Add extra space for the line number gutter (approximate width of numbers + padding)
    gutter_width = len(str(len(code.splitlines()))) + 4
    console_width = max_line_length + gutter_width

    # Initialize a Console with recording and fixed width
    console = Console(record=True, width=console_width)
    # Print the syntax-highlighted code to the console buffer
    console.print(syntax)

    # Export to SVG with a custom title
    svg_output = console.export_svg(title="Usage.sh")
    out_path = Path(__file__).parent.parent / "usage_code.svg"
    out_path.write_text(svg_output)
    print(f"✅ Syntax-highlighted SVG written to {out_path} using theme '{theme}'")

if __name__ == "__main__":
    main()
