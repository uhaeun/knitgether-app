"""Build the QA portfolio PDF from portfolio.md without rewriting its contents.

Requires reportlab. Uses embedded Pretendard fonts and selectable PDF text.
"""
from pathlib import Path
import re
from html import escape
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib import colors
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib.enums import TA_LEFT
from reportlab.platypus import (BaseDocTemplate, Frame, PageTemplate, Flowable,
                               Paragraph, Table, TableStyle,
                               Spacer, PageBreak, KeepTogether, Image)
from reportlab.pdfgen.canvas import Canvas

ROOT = Path(__file__).resolve().parents[4]
SOURCE = ROOT / 'docs/qa/submission/portfolio.md'
OUT = ROOT / 'output/pdf/knitgether_qa_portfolio.pdf'
FONT_DIR = SOURCE.parent / 'fonts'
for name, weight in [('Korean', 'Regular'), ('KoreanSemiBold', 'SemiBold'), ('KoreanBold', 'Bold')]:
    pdfmetrics.registerFont(TTFont(name, str(FONT_DIR / f'Pretendard-{weight}.ttf')))
pdfmetrics.registerFontFamily('Korean', normal='Korean', bold='KoreanBold',
                              italic='Korean', boldItalic='KoreanBold')
INK, TEAL, MUTED = '#243431', '#346D67', '#596963'
W, H = A4
M = 20 * mm
CW = W - M * 2
BASE = 'https://github.com/uhaeun/knitgether-app/blob/main/'

styles = {
    'body': ParagraphStyle('body', fontName='Korean', fontSize=11, leading=17.05,
                           alignment=TA_LEFT, wordWrap=None,
                           textColor=colors.HexColor(INK), spaceAfter=8,
                           allowWidows=0, allowOrphans=0),
}
def style(name, **kw):
    styles[name] = ParagraphStyle(name, parent=styles['body'], **kw)
style('title', fontName='KoreanBold', fontSize=32, leading=42, spaceAfter=18, keepWithNext=True)
style('chapter', fontName='KoreanBold', fontSize=22, leading=29, spaceBefore=0, spaceAfter=18, keepWithNext=True)
style('section', fontName='KoreanSemiBold', fontSize=14, leading=21, spaceBefore=10, spaceAfter=7,
      textColor=colors.HexColor(TEAL), keepWithNext=True)
style('cell', fontSize=11, leading=17.05, spaceAfter=0)
style('headcell', fontName='KoreanSemiBold', fontSize=11, leading=17.05, spaceAfter=0, textColor=colors.white)
style('caption', fontSize=9, leading=13.95, spaceAfter=6, textColor=colors.HexColor(MUTED))
style('link', fontSize=9, leading=13.95, spaceAfter=5, textColor=colors.HexColor(TEAL))
style('bullet', leftIndent=13, firstLineIndent=-11, spaceAfter=6)


class TrackedHeading(Flowable):
    """Set actual PDF character spacing to -1% em on large headings only."""
    def __init__(self, text, heading_style):
        super().__init__()
        self.text, self.style = text, heading_style
        self.spaceAfter = heading_style.spaceAfter
        self.keepWithNext = True
        self.tracking = -0.01 * heading_style.fontSize

    def measured_width(self, text):
        return (pdfmetrics.stringWidth(text, self.style.fontName, self.style.fontSize)
                + max(0, len(text) - 1) * self.tracking)

    def wrap(self, available_width, available_height):
        self.lines = []
        line = ''
        for word in self.text.split():
            candidate = f'{line} {word}' if line else word
            if line and self.measured_width(candidate) > available_width:
                self.lines.append(line)
                line = word
            else:
                line = candidate
        if line:
            self.lines.append(line)
        # Avoid leaving only a defect ID on the second line of a long title.
        if len(self.lines) == 2 and self.measured_width(self.lines[-1]) < available_width * 0.45:
            words = self.text.split()
            candidates = [(' '.join(words[:i]), ' '.join(words[i:]))
                          for i in range(1, len(words))]
            candidates = [pair for pair in candidates
                          if all(self.measured_width(s) <= available_width for s in pair)]
            if candidates:
                self.lines = list(min(candidates, key=lambda pair:
                                      abs(self.measured_width(pair[0]) - self.measured_width(pair[1]))))
        self.width = available_width
        self.height = self.style.leading * len(self.lines)
        return self.width, self.height

    def draw(self):
        self.canv.saveState()
        text = self.canv.beginText()
        text.setFont(self.style.fontName, self.style.fontSize)
        text.setFillColor(self.style.textColor)
        text.setCharSpace(self.tracking)
        text.setLeading(self.style.leading)
        ascent = pdfmetrics.getAscent(self.style.fontName) * self.style.fontSize / 1000
        text.setTextOrigin(0, self.height - ascent)
        for line in self.lines:
            text.textLine(line)
        self.canv.drawText(text)
        self.canv.restoreState()

def url(href):
    if href.startswith(('http:', 'https:')):
        return href
    return BASE + (SOURCE.parent / href).resolve().relative_to(ROOT).as_posix()

def inline(txt):
    # Convert only the inline Markdown used by the canonical source.
    parts = re.split(r'(\[[^\]]+\]\([^)]+\))', txt)
    result = []
    for part in parts:
        m = re.fullmatch(r'\[([^\]]+)\]\(([^)]+)\)', part)
        if m:
            result.append('<link href="' + escape(url(m[2]), quote=True) + '" color="' + TEAL + '"><u>' + escape(m[1]) + '</u></link>')
        else:
            s = escape(part)
            s = re.sub(r'\*\*(.+?)\*\*', r'<font color="' + TEAL + r'">\1</font>', s)
            s = re.sub(r'`([^`]+)`', r'\1', s)
            result.append(s)
    return ''.join(result)

def p(text, typ='body'):
    if typ in ('title', 'chapter'):
        return TrackedHeading(text, styles[typ])
    return Paragraph(inline(text), styles[typ])

class LinkedImage(Image):
    def __init__(self, source, width):
        super().__init__(str(SOURCE.parent / source))
        self.drawHeight = self.imageHeight * width / self.imageWidth
        self.drawWidth = width
        self.href = url(source)
        self.hAlign = 'CENTER'
    def draw(self):
        super().draw()
        self.canv.linkURL(self.href, (0, 0, self.drawWidth, self.drawHeight), relative=1)

def table(lines, photo_width=165):
    cells = [[c.strip() for c in line.strip().strip('|').split('|')] for line in lines]
    rows = [cells[0]] + cells[2:]
    image_table = '<img ' in '\n'.join(lines)
    n = len(rows[0])
    if n == 3 and rows[0][0] == '검증 방법':
        widths = [96, 96, CW-192]
    elif n == 3:
        widths = [105, 190, CW-295]
    elif n == 2 and not image_table:
        widths = [CW*.42, CW*.58]
    else:
        widths = [CW/n] * n
    data=[]
    for i,row in enumerate(rows):
        out=[]
        for cell in row:
            match = re.search(r'<img src="([^"]+)"',cell)
            if match:
                out.append(LinkedImage(match[1], photo_width))
            else:
                out.append(p(cell, 'headcell' if i==0 else 'caption' if image_table else 'cell'))
        data.append(out)
    t=Table(data, colWidths=widths, repeatRows=1, hAlign='LEFT')
    ts=[('BACKGROUND',(0,0),(-1,0),colors.HexColor(TEAL)),
        ('VALIGN',(0,0),(-1,-1),'TOP'), ('LEFTPADDING',(0,0),(-1,-1),8),
        ('RIGHTPADDING',(0,0),(-1,-1),8),('TOPPADDING',(0,0),(-1,-1),7),
        ('BOTTOMPADDING',(0,0),(-1,-1),7),
        ('LINEBELOW',(0,0),(-1,-1),.4,colors.HexColor('#D9E3DF'))]
    if image_table:
        ts += [('ALIGN',(0,0),(-1,-1),'CENTER'), ('BACKGROUND',(0,1),(-1,-1),colors.HexColor('#F8FAF9')),
               ('TOPPADDING',(0,0),(-1,-1),4), ('BOTTOMPADDING',(0,0),(-1,-1),4)]
    else:
        ts += [('ROWBACKGROUNDS',(0,1),(-1,-1),[colors.white, colors.HexColor('#F2F6F4')])]
    t.setStyle(TableStyle(ts))
    return KeepTogether([t,Spacer(1,4)]) if image_table else t

class NumberedCanvas(Canvas):
    def __init__(self,*args,**kw):
        super().__init__(*args,**kw); self.states=[]
    def showPage(self):
        self.states.append(dict(self.__dict__)); self._startPage()
    def save(self):
        total=len(self.states)
        for state in self.states:
            self.__dict__.update(state)
            self.setFillColor(colors.HexColor(TEAL));self.rect(M,H-M-8,25,2,fill=1,stroke=0)
            self.setFont('Korean',9);self.drawString(M+34,H-M-10,'KNITGETHER / MOBILE QA PORTFOLIO')
            self.setStrokeColor(colors.HexColor('#D9E3DF'));self.line(M,M+19,W-M,M+19)
            self.setFillColor(colors.HexColor(MUTED));self.drawString(M,M+3,'유하은 | 뜨개더 iOS 앱 QA')
            self.drawRightString(W-M,M+3,f'{self._pageNumber:02d} / {total:02d}')
            super().showPage()
        super().save()

def build():
    lines=SOURCE.read_text().splitlines(); story=[]; i=0; chapter=''; photo_width=165; photo_page=False
    case_title=''; photo_title=''; photo_tables=0
    while i<len(lines):
        line=lines[i].strip();i+=1
        if not line or line=='---': continue
        if line.startswith('# '):
            story.append(Spacer(1,95))
            story.append(p(line[2:],'title')); continue
        if line.startswith('## '):
            txt=line[3:]
            if txt.startswith('01 '):
                story.append(Spacer(1,70))
                story.append(p('문서 구성','section'))
                for item in ['01  프로젝트와 역할', '02  테스트 전략과 설계',
                             '03  주요 검증 사례 5개', '04  결과와 회고']:
                    story.append(p(item))
            story.append(PageBreak())
            chapter=txt[:2]
            photo_page=False;photo_width=165
            if txt.startswith('03 '):
                story.append(p(txt,'section'))
            else: story.append(p(txt,'chapter'))
            continue
        if line.startswith('### 03-'):
            if not line.startswith('### 03-1'):story.append(PageBreak())
            photo_page=False;photo_width=165
            case_title=line[4:]
            story.append(p(case_title,'chapter'));continue
        if line.startswith(('### ','#### ')):
            txt=re.sub(r'^#+\s*','',line)
            if txt == '담당 역할':
                story.extend([PageBreak(),p('01 프로젝트와 역할','chapter')])
            elif txt in ['테스트 범위와 케이스 구성','대표 테스트 조건과 기대 결과']:
                story.extend([PageBreak(),p('02 테스트 전략과 설계','chapter')])
            elif txt == '후속 조치와 재검증' and case_title:
                story.extend([PageBreak(),p(case_title,'chapter')])
            story.append(p(txt,'section'));continue
        if line.startswith('|'):
            block=[line]
            while i<len(lines) and lines[i].strip().startswith('|'):
                block.append(lines[i].strip());i+=1
            if photo_page and photo_tables:
                story.extend([PageBreak(),p(photo_title,'chapter')])
            story.extend([table(block,photo_width),Spacer(1,4 if photo_page else 8)])
            if photo_page:photo_tables+=1
            continue
        if re.match(r'^(- |\d+\. )',line):
            if chapter == '04' and line.startswith('3. **자동화 결과'):
                story.extend([PageBreak(),p('04 결과와 회고','chapter'),
                              p('프로젝트를 통해 배운 점 (계속)','section')])
            text=line.replace('- ','- ',1)
            story.append(p(text,'bullet'));continue
        if line.startswith('**') and line.endswith('**'):
            if '추가 재검증 화면' in line:
                story.append(PageBreak());photo_page=True
                photo_width=165;photo_tables=0;photo_title=line.strip('*')
                story.append(p(photo_title,'chapter'))
            else:story.append(p(line.strip('*'),'section'))
            continue
        if re.fullmatch(r'\[[^\]]+\]\([^)]+\)',line):
            links=[line]
            while i<len(lines):
                j=i
                while j<len(lines) and not lines[j].strip():j+=1
                if j<len(lines) and re.fullmatch(r'\[[^\]]+\]\([^)]+\)',lines[j].strip()):
                    links.append(lines[j].strip());i=j+1
                else:break
            story.append(p(' / '.join(links),'link'));continue
        block=[line]
        while i<len(lines) and lines[i].strip() and not re.match(r'^(#|\||---|\d+\. |- )',lines[i]):
            block.append(lines[i].strip());i+=1
        txt=' '.join(block)
        typ='caption' if txt.startswith(('촬영:','테스트 데이터를 준비해')) else 'body'
        story.append(p(txt,typ))
    OUT.parent.mkdir(parents=True,exist_ok=True)
    doc=BaseDocTemplate(str(OUT), pagesize=A4, leftMargin=M, rightMargin=M,
                          topMargin=M,bottomMargin=M,title='뜨개더 iOS 앱 QA | 유하은', author='유하은')
    # Running headers and footers also stay inside the 20 mm safe area.
    frame=Frame(M,M+30,CW,H-2*M-60,leftPadding=0,rightPadding=0,
                topPadding=0,bottomPadding=0,id='body')
    doc.addPageTemplates(PageTemplate(id='portfolio',frames=[frame]))
    doc.build(story, canvasmaker=NumberedCanvas)
    print(OUT)

if __name__=='__main__':build()
