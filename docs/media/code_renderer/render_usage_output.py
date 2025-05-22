#!/usr/bin/env python3
import subprocess
from pathlib import Path
from rich.console import Console
from rich.text import Text

def main():
    script_path = Path(__file__).parent / "Usage.sh"
    out_svg     = Path(__file__).parent.parent / "usage_output.svg"

    # 1) Capture everything, raw ANSI + newlines
    proc = subprocess.Popen(
        ["script", "-qc", str(script_path), "/dev/null"],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
        errors="ignore",
    )

    texts = []
    max_width = 0

    for raw in proc.stdout:
        line = raw.rstrip("\n")
        txt = Text.from_ansi(line)

        plain = txt.plain.rstrip()
        max_width = max(max_width, len(plain))

        texts.append(txt)

    proc.stdout.close()
    proc.wait()

    # 2) Replay into a Console sized to your content
    console = Console(record=True, width=max_width)
    for txt in texts:
        console.print(txt)

    # 3) Export cropped SVG with custom title
    svg = console.export_svg(title="Output")
    out_svg.write_text(svg)
    print(f"✅ SVG written to {out_svg} with window title “Output”")

if __name__ == "__main__":
    main()
