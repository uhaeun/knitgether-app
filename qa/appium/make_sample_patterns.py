"""Regenerate the four original QA PDFs bundled with the app.

Requires reportlab. File names and page counts preserve existing fixture references.
These grids are test inputs, not knitting instructions.
"""
from pathlib import Path

from make_portfolio_fixtures import create


if __name__ == "__main__":
    out = Path(__file__).resolve().parents[2] / "KnitGether/Resources/SamplePatterns"
    out.mkdir(parents=True, exist_ok=True)
    for number, pages, accent in [
        (1, 11, "#426D67"),
        (2, 9, "#8A6046"),
        (3, 3, "#525F88"),
        (4, 17, "#71613F"),
    ]:
        create(out / f"sample{number}.pdf", f"SAMPLE {number}", pages, accent)
