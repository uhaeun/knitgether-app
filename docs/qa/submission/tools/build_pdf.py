"""Build the submission PDF from the single portfolio Markdown source."""
from pathlib import Path
from html import escape
import os
import re
from urllib.parse import quote
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib import colors
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Table, TableStyle, Spacer, PageBreak,
    Image, KeepTogether,
)

ROOT = Path(__file__).resolve().parents[4]
SOURCE = ROOT / 'docs/qa/submission/github-guide.md'
OUT = ROOT / 'output/pdf/knitgether_qa_portfolio.pdf'
FONT_DIR = SOURCE.parent / 'fonts'
EVIDENCE_REF = os.environ.get('KNITGETHER_PDF_REF', '60c0a708d9f310d1095f99ca1683c83531c0171f')
SUBMISSION_REF = os.environ.get('KNITGETHER_SUBMISSION_REF', 'portfolio/knitgether-20261029')
REPO = 'https://github.com/uhaeun/knitgether-app'
W, H = A4
M = 19 * mm
CW = W - 2 * M
INK, TEAL, MUTED, LINE, PALE = [colors.HexColor(s) for s in
    ['#243936', '#267267', '#64746F', '#DCE5E0', '#F1F6F3']]
for name, weight in [('KR', 'Regular'), ('KRB', 'Bold'), ('KRS', 'SemiBold')]:
    pdfmetrics.registerFont(TTFont(name, str(FONT_DIR / f'Pretendard-{weight}.ttf')))
pdfmetrics.registerFontFamily('KR', normal='KR', bold='KRB', italic='KR', boldItalic='KRB')

styles = {}
def style(name, size=10.7, leading=16.8, **kw):
    styles[name] = ParagraphStyle(name, fontName='KR', fontSize=size, leading=leading,
        textColor=INK, wordWrap='CJK', spaceAfter=8, splitLongWords=True, **kw)
style('body')
styles['title'] = ParagraphStyle('title', fontName='KRB', fontSize=30, leading=39,
    textColor=INK, spaceAfter=13, wordWrap='CJK')
styles['chapter'] = ParagraphStyle('chapter', fontName='KRB', fontSize=20, leading=28,
    textColor=INK, spaceAfter=14, wordWrap='CJK', keepWithNext=True)
styles['section'] = ParagraphStyle('section', fontName='KRS', fontSize=12.2, leading=18,
    textColor=TEAL, spaceBefore=7, spaceAfter=8, wordWrap='CJK', keepWithNext=True)
styles['caption'] = ParagraphStyle('caption', parent=styles['body'], fontSize=8.3,
    leading=12.2, textColor=MUTED, spaceAfter=8)
styles['link'] = ParagraphStyle('link', parent=styles['caption'], textColor=TEAL, spaceAfter=7)
styles['cell'] = ParagraphStyle('cell', parent=styles['body'], fontSize=9.2, leading=14.1, spaceAfter=0)
styles['headcell'] = ParagraphStyle('headcell', parent=styles['cell'], fontName='KRS', textColor=colors.white)
styles['label'] = ParagraphStyle('label', parent=styles['body'], fontName='KRS', textColor=TEAL,
    fontSize=9.5, leading=14, spaceAfter=10)


def url(href):
    if href.startswith(('https://', 'http://')):
        return href
    target = (SOURCE.parent / href).resolve()
    rel = target.relative_to(ROOT).as_posix()
    new_document = rel in {'README.md', 'docs/qa/submission/github-guide.md',
        'docs/qa/submission/portfolio.md', 'docs/qa/submission/README.md',
        'docs/qa/submission/technical-summary.md', 'qa/api-tests/README.md'} or rel.startswith('docs/qa/validation/2026-10-29/')
    ref = SUBMISSION_REF if new_document else EVIDENCE_REF
    kind = 'tree' if target.is_dir() else 'blob'
    return f'{REPO}/{kind}/{ref}/{quote(rel)}'


def inline(text):
    chunks = re.split(r'(\[[^\]]+\]\([^)]+\))', text)
    rendered = []
    for part in chunks:
        match = re.fullmatch(r'\[([^\]]+)\]\(([^)]+)\)', part)
        if match:
            rendered.append(f'<link href="{escape(url(match[2]), quote=True)}" color="#267267"><u>{escape(match[1])}</u></link>')
        else:
            value = escape(part)
            value = re.sub(r'\*\*(.+?)\*\*', r'<b>\1</b>', value)
            value = re.sub(r'`([^`]+)`', r'\1', value)
            rendered.append(value)
    return ''.join(rendered)


def p(text, kind='body'):
    return Paragraph(inline(text), styles[kind])


class ProofImage(Image):
    def __init__(self, href, width):
        self.href = url(href)
        super().__init__(str(SOURCE.parent / href))
        natural_width, natural_height = self.imageWidth, self.imageHeight
        self.drawWidth = width
        self.drawHeight = width * natural_height / natural_width
        self.hAlign = 'CENTER'
    def draw(self):
        super().draw()
        self.canv.linkURL(self.href, (0, 0, self.drawWidth, self.drawHeight), relative=1)


def make_table(lines, width, photo_width=144):
    rows = [[c.strip() for c in row.strip().strip('|').split('|')] for row in lines]
    rows = [rows[0]] + rows[2:]
    is_photo = '<img ' in '\n'.join(lines)
    n = len(rows[0])
    if is_photo:
        widths = [width / n] * n
    elif n == 3:
        widths = [width * .27, width * .33, width * .40]
    else:
        widths = [width * .37, width * .63] if n == 2 else [width / n] * n
    data = []
    for i, row in enumerate(rows):
        values = []
        for cell in row:
            match = re.search(r'<img src="([^"]+)"', cell)
            values.append(ProofImage(match[1], min(photo_width, width/n-20)) if match else
                p(cell, 'headcell' if i == 0 else 'cell'))
        data.append(values)
    result = Table(data, colWidths=widths, hAlign='LEFT', repeatRows=1)
    result.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), TEAL),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [PALE, colors.white]),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('LEFTPADDING', (0,0), (-1,-1), 9), ('RIGHTPADDING', (0,0), (-1,-1), 9),
        ('TOPPADDING', (0,0), (-1,-1), 8), ('BOTTOMPADDING', (0,0), (-1,-1), 8),
        ('LINEBELOW', (0,0), (-1,-1), .35, LINE),
        ('ALIGN', (0,0), (-1,-1), 'CENTER' if is_photo else 'LEFT'),
    ]))
    return KeepTogether([result, Spacer(1,9)]) if is_photo else result


def parse(lines, width=CW):
    flows, i, photo_width = [], 0, 144
    while i < len(lines):
        text = lines[i].strip()
        i += 1
        if not text:
            continue
        setting = re.fullmatch(r'<!-- photo-width: (\d+) -->', text)
        if setting:
            photo_width = int(setting[1]); continue
        if text.startswith('<!--'):
            continue
        if text.startswith('### '):
            flows.append(p(text[4:], 'section')); continue
        if text.startswith('|'):
            block = [text]
            while i < len(lines) and lines[i].strip().startswith('|'):
                block.append(lines[i].strip()); i += 1
            flows += [make_table(block, width, photo_width), Spacer(1,10)]
            continue
        block = [text]
        while i < len(lines) and lines[i].strip() and not re.match(r'^(#|\||<!--)', lines[i].strip()):
            block.append(lines[i].strip()); i += 1
        text = ' '.join(block)
        if text.startswith('촬영:'):
            kind = 'caption'
        elif text.startswith('['):
            kind = 'link'
        elif text.startswith('**') and text.endswith('**'):
            kind = 'label'
        else:
            kind = 'body'
        flows.append(p(text, kind))
    return flows


def footer(canvas, doc):
    canvas.saveState()
    canvas.setFillColor(TEAL)
    canvas.rect(M, H-31, 22, 2, stroke=0, fill=1)
    canvas.setFont('KRS', 8)
    canvas.drawString(M+30, H-33, 'KNITGETHER / QA CASE STUDY')
    canvas.setFillColor(MUTED)
    canvas.setFont('KR', 8)
    canvas.drawRightString(W-M, H-33, '2026.10')
    canvas.setStrokeColor(LINE)
    canvas.line(M, 41, W-M, 41)
    canvas.setFont('KR', 8)
    canvas.drawString(M, 26, '유하은 | 작업 기록의 보존을 중심으로')
    canvas.drawRightString(W-M, 26, f'{doc.page:02d} / 08')
    canvas.restoreState()


def build():
    source = SOURCE.read_text(encoding='utf-8')
    sections = re.split(r'^## ', source, flags=re.M)[1:]
    if len(sections) != 8:
        raise ValueError('The portfolio must have eight sections.')
    story = []
    for number, section in enumerate(sections, 1):
        lines = section.splitlines()
        title = lines.pop(0).strip()
        if number > 1:
            story.append(PageBreak())
        if number == 1:
            story += [p('뜨개더', 'title'), p('QA PORTFOLIO', 'label')]
        story.append(p(title, 'chapter'))
        if number == 5:
            # Float the narrow phone screenshot beside its explanation.
            image_start = next(i for i,line in enumerate(lines) if line.startswith('| 충돌 안내'))
            left_lines = [line for line in lines[:image_start] if not line.startswith('<!--')]
            image_source = re.search(r'<img src="([^"]+)"', '\n'.join(lines[image_start:])).group(1)
            last_image_row = next(i for i in range(image_start, len(lines)) if '<img ' in lines[i])
            left_width, image_width = CW-174, 148
            split = Table([[parse(left_lines, left_width), ProofImage(image_source, image_width)]],
                colWidths=[left_width+10, CW-left_width-10], hAlign='LEFT')
            split.setStyle(TableStyle([('VALIGN',(0,0),(-1,-1),'TOP'),
                ('LEFTPADDING',(0,0),(-1,-1),0), ('RIGHTPADDING',(0,0),(-1,-1),9),
                ('TOPPADDING',(0,0),(-1,-1),0), ('BOTTOMPADDING',(0,0),(-1,-1),9)]))
            story += [split] + parse(lines[last_image_row+1:])
        else:
            story += parse(lines)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    doc = SimpleDocTemplate(str(OUT), pagesize=A4, leftMargin=M, rightMargin=M,
        topMargin=52, bottomMargin=56, title='뜨개더 QA 포트폴리오 | 유하은', author='유하은',
        subject='iOS 앱의 기록 보존, API와 DB 정합성, 저장 충돌과 복구 검증')
    doc.build(story, onFirstPage=footer, onLaterPages=footer)
    print(OUT)

if __name__ == '__main__':
    build()
