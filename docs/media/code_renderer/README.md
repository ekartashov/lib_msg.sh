# Code Renderer Scripts

This directory contains Python scripts to generate SVG images from shell script execution.

## Scripts

- **[`render_usage.py`](render_usage.py):**
    - Takes the [`Usage.sh`](Usage.sh) script as input.
    - Applies syntax highlighting to the shell script code.
    - Exports the highlighted code as an SVG file named `usage_code.svg` in the parent `media` directory.
- **[`render_usage_output.py`](render_usage_output.py):**
    - Executes the [`Usage.sh`](Usage.sh) script.
    - Captures the raw terminal output, including ANSI color codes.
    - Renders this output as an SVG file named `usage_output.svg` in the parent `media` directory.
- **[`Usage.sh`](Usage.sh):**
    - A sample shell script whose code and output are rendered by the Python scripts.

## Setup

To use these scripts, you need to set up a Python virtual environment and install the dependencies.

1.  **Create and activate a virtual environment:**

    ```bash
    python3 -m venv .venv
    source .venv/bin/activate
    ```

2.  **Install dependencies:**

    Make sure you are in the `docs/media/code_renderer` directory.

    ```bash
    pip install -r requirements.txt
    ```

## Usage

After setting up the environment, you can run the Python scripts directly:

```bash
python ./render_usage.py
python ./render_usage_output.py
```

This will generate/update the `usage_code.svg` and `usage_output.svg` files in the `docs/media/` directory.