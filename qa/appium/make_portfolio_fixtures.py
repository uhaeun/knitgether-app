"""Submission capture inputs only: original, non-commercial test PDFs."""
from pathlib import Path
import sys
from reportlab.pdfgen import canvas
from reportlab.lib.colors import HexColor


def create(path, title, pages, accent):
    c = canvas.Canvas(str(path), pagesize=(420, 594))
    c.setTitle(title)
    c.setAuthor("KnitGether QA test fixture")
    for page in range(1, pages + 1):
        c.setFillColor(HexColor("#F7F4EE"))
        c.rect(0, 0, 420, 594, stroke=0, fill=1)
        c.setFillColor(HexColor(accent))
        c.rect(0, 485, 420, 109, stroke=0, fill=1)
        c.setFillColor(HexColor("#FFFFFF"))
        c.setFont("Helvetica-Bold", 25)
        c.drawString(28, 548, title)
        c.setFont("Helvetica-Bold", 32)
        c.drawString(28, 501, f"PAGE {page:02d} / {pages:02d}")
        c.setFillColor(HexColor("#263B3A"))
        c.setFont("Helvetica", 14)
        c.drawString(28, 446, "KnitGether QA - drawing and page retention")
        c.drawString(28, 418, f"Unique page marker: {title}-{page:02d}")
        c.setStrokeColor(HexColor("#A8BAB5"))
        for row in range(9):
            c.line(42, 140 + row * 27, 366, 140 + row * 27)
        for col in range(13):
            c.line(42 + col * 27, 140, 42 + col * 27, 356)
        c.setFont("Helvetica", 12)
        c.drawString(28, 92, "TEST INPUT ONLY - not a knitting instruction")
        c.drawString(28, 68, "Draw here, then cancel or confirm PDF replacement.")
        c.showPage()
    c.save()


if __name__ == "__main__":
    out = Path(sys.argv[1])
    out.mkdir(parents=True, exist_ok=True)
    create(out / "qa-original.pdf", "PATTERN A", 4, "#426D67")
    create(out / "qa-replacement.pdf", "PATTERN B", 2, "#8A6046")
