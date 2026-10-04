"""Build the QA portfolio PDF from portfolio.md without rewriting its contents.

Requires reportlab. Set KG_KOREAN_FONT to a Korean TrueType font when needed.
"""
from pathlib import Path
import os
import re
from html import escape
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib import colors
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import (SimpleDocTemplate, Paragraph, Table, TableStyle,
                               Spacer, PageBreak, KeepTogether, Image)
from reportlab.pdfgen.canvas import Canvas

ROOT = Path(__file__).resolve().parents[4]
SOURCE = ROOT / 'docs/qa/submission/portfolio.md'
OUT = ROOT / 'output/pdf/knitgether_qa_portfolio.pdf'
FONT = os.environ.get('KG_KOREAN_FONT', '/Library/Fonts/Arial Unicode.ttf')
pdfmetrics.registerFont(TTFont('Korean', FONT))
pdfmetrics.registerFontFamily('Korean', normal='Korean', bold='Korean', italic='Korean', boldItalic='Korean')
INK, TEAL, MUTED = '#243431', '#346D67', '#596963'
W, H, M = 595.28, 841.89, 44
CW = W - M * 2
BASE = 'https://github.com/uhaeun/knitgether-app/blob/main/'

styles = {
    'body': ParagraphStyle('body', fontName='Korean', fontSize=10.3, leading=15.8,
                           wordWrap=None, textColor=colors.HexColor(INK), spaceAfter=7),
}
def style(name, **kw):
    styles[name] = ParagraphStyle(name, parent=styles['body'], **kw)
style('title', fontSize=24, leading=32, spaceAfter=12, textColor=colors.HexColor(INK), keepWithNext=True)
style('chapter', fontSize=18, leading=26, spaceBefore=0, spaceAfter=15, keepWithNext=True)
style('section', fontSize=12.4, leading=19, spaceBefore=8, spaceAfter=5,
      textColor=colors.HexColor(TEAL), keepWithNext=True)
style('cell', fontSize=9.3, leading=14.3, spaceAfter=0)
style('headcell', fontSize=9.5, leading=14.5, spaceAfter=0, textColor=colors.white)
style('caption', fontSize=8.5, leading=12.5, spaceAfter=5, textColor=colors.HexColor(MUTED))
style('link', fontSize=8.6, leading=13, spaceAfter=4, textColor=colors.HexColor(TEAL))
style('bullet', leftIndent=12, firstLineIndent=-10, spaceAfter=5)

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
        widths = [95, 98, CW-193]
    elif n == 3:
        widths = [104, 207, CW-311]
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
            self.setFillColor(colors.HexColor(TEAL));self.rect(M,H-35,25,2,fill=1,stroke=0)
            self.setFont('Korean',7.8);self.drawString(M+34,H-37,'KNITGETHER / MOBILE QA PORTFOLIO')
            self.setStrokeColor(colors.HexColor('#D9E3DF'));self.line(M,40,W-M,40)
            self.setFillColor(colors.HexColor(MUTED));self.drawString(M,26,'유하은 | 뜨개더 iOS 앱 QA')
            self.drawRightString(W-M,26,f'{self._pageNumber:02d} / {total:02d}')
            super().showPage()
        super().save()

def build():
    lines=SOURCE.read_text().splitlines(); story=[]; i=0; chapter=''; photo_width=165; photo_page=False
    while i<len(lines):
        line=lines[i].strip();i+=1
        if not line or line=='---': continue
        if line.startswith('# '):
            story.append(p(line[2:],'title')); continue
        if line.startswith('## '):
            txt=line[3:]
            if not txt.startswith('01 '): story.append(PageBreak())
            chapter=txt[:2]
            photo_page=False;photo_width=165
            if txt.startswith('03 '):
                story.append(p(txt,'section'))
            else: story.append(p(txt,'chapter'))
            continue
        if line.startswith('### 03-'):
            if not line.startswith('### 03-1'):story.append(PageBreak())
            photo_page=False;photo_width=165
            story.append(p(line[4:],'chapter'));continue
        if line.startswith(('### ','#### ')):
            txt=re.sub(r'^#+\s*','',line)
            if txt in ['담당 역할','위험도에 따른 테스트 우선순위']:story.append(PageBreak())
            story.append(p(txt,'section'));continue
        if line.startswith('|'):
            block=[line]
            while i<len(lines) and lines[i].strip().startswith('|'):
                block.append(lines[i].strip());i+=1
            story.extend([table(block,photo_width),Spacer(1,4 if photo_page else 8)]);continue
        if re.match(r'^(- |\d+\. )',line):
            text=line.replace('- ','- ',1)
            story.append(p(text,'bullet'));continue
        if line.startswith('**') and line.endswith('**'):
            if '추가 재검증 화면' in line:
                story.append(PageBreak());photo_page=True
                photo_width=124 if '03-1' in line else 165
            story.append(p(line.strip('*'),'section'));continue
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
        typ='caption' if photo_page or txt.startswith(('촬영:','테스트 데이터를 준비해')) else 'body'
        story.append(p(txt,typ))
    OUT.parent.mkdir(parents=True,exist_ok=True)
    doc=SimpleDocTemplate(str(OUT), pagesize=(W,H), leftMargin=M, rightMargin=M,
                          topMargin=53,bottomMargin=47,title='뜨개더 iOS 앱 QA | 유하은', author='유하은')
    doc.build(story, canvasmaker=NumberedCanvas)
    print(OUT)

if __name__=='__main__':build()
