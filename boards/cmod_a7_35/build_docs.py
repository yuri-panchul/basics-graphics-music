#!/usr/bin/env python3
"""Render the small Markdown subset used by the two assembly guides.

Standard library only. The Markdown remains the editable source; fenced prompt
text is escaped verbatim, so historical instructions cannot become page markup.
"""
from pathlib import Path
from html import escape
import re

HERE = Path(__file__).resolve().parent


def inline(text):
    pattern = re.compile(r'`([^`]+)`|!\[([^\]]*)\]\(([^)]+)\)|\[([^\]]+)\]\(([^)]+)\)|\*\*([^*]+)\*\*')
    parts, offset = [], 0
    for match in pattern.finditer(text):
        parts.append(escape(text[offset:match.start()]))
        code, alt, image, label, target, strong = match.groups()
        if code is not None:
            parts.append('<code>' + escape(code) + '</code>')
        elif image is not None:
            parts.append(f'<figure><a href="{escape(image, quote=True)}"><img src="{escape(image, quote=True)}" alt="{escape(alt, quote=True)}" width="1100" height="760"></a><figcaption>{escape(alt)}</figcaption></figure>')
        elif target is not None:
            parts.append(f'<a href="{escape(target, quote=True)}">{escape(label)}</a>')
        else:
            parts.append('<strong>' + escape(strong) + '</strong>')
        offset = match.end()
    parts.append(escape(text[offset:]))
    return ''.join(parts)


def render(markdown):
    lines = markdown.splitlines()
    out, toc = [], []
    i, section = 0, 0
    while i < len(lines):
        line = lines[i]
        if not line.strip():
            i += 1
            continue
        if line.startswith('```'):
            language = line[3:].strip()
            block = []
            i += 1
            while i < len(lines) and not lines[i].startswith('```'):
                block.append(lines[i])
                i += 1
            out.append(f'<pre class="{escape(language, quote=True)}"><code>{escape(chr(10).join(block))}</code></pre>')
            i += 1
            continue
        heading = re.match(r'^(#{1,3}) (.*)', line)
        if heading:
            level, label = len(heading[1]), heading[2]
            section += 1
            anchor = f'section-{section}'
            if level == 2:
                toc.append(f'<a href="#{anchor}">{escape(label)}</a>')
            out.append(f'<h{level} id="{anchor}">{inline(label)}</h{level}>')
            i += 1
            continue
        if line.startswith('|'):
            rows = []
            while i < len(lines) and lines[i].startswith('|'):
                cells = [c.strip() for c in lines[i].strip().strip('|').split('|')]
                if not all(re.fullmatch(r':?-+:?', cell) for cell in cells):
                    rows.append(cells)
                i += 1
            header = '<tr>' + ''.join('<th scope="col">' + inline(c) + '</th>' for c in rows[0]) + '</tr>'
            body = ''.join('<tr>' + ''.join('<td>' + inline(c) + '</td>' for c in row) + '</tr>' for row in rows[1:])
            out.append('<div class="table-wrap" tabindex="0"><table><thead>' + header + '</thead><tbody>' + body + '</tbody></table></div>')
            continue
        if re.match(r'^(- |\d+\. )', line):
            ordered = not line.startswith('- ')
            tag = 'ol' if ordered else 'ul'
            items = []
            pattern = r'^\d+\. (.*)' if ordered else r'^- (.*)'
            while i < len(lines):
                item = re.match(pattern, lines[i])
                if not item:
                    break
                items.append('<li>' + inline(item[1]) + '</li>')
                i += 1
            out.append(f'<{tag}>' + ''.join(items) + f'</{tag}>')
            continue
        paragraph = [line]
        i += 1
        while i < len(lines) and lines[i].strip() and not re.match(r'^(#|\||```|- |\d+\. )', lines[i]):
            paragraph.append(lines[i])
            i += 1
        text = inline(' '.join(paragraph))
        out.append(text if text.startswith('<figure>') else '<p>' + text + '</p>')
    return '\n'.join(out), '\n'.join(toc)


STYLE = '''
:root{color-scheme:light}*{box-sizing:border-box}body{margin:0;background:#eef3f4;color:#203541;font:16px/1.65 system-ui,-apple-system,"Segoe UI",sans-serif;overflow-wrap:anywhere}main{max-width:1060px;background:#fff;margin:28px auto;padding:38px 48px;border-top:7px solid #196f75;border-radius:7px}h1{font-size:2.2rem;line-height:1.18;margin-top:0;color:#124e55}h2{font-size:1.5rem;margin:42px 0 16px;border-top:1px solid #d3dfe1;padding-top:24px;scroll-margin-top:16px}h3{font-size:1.15rem}a{color:#086e80;text-underline-offset:3px}p{margin:14px 0}li{margin:9px 0}code{font:0.9em ui-monospace,Consolas,monospace;background:#f0f4f5;padding:1px 4px;border-radius:3px}pre{padding:18px;background:#edf3f4;white-space:pre-wrap;overflow-wrap:anywhere;font-size:.85rem;line-height:1.55;border-left:3px solid #699b9f}pre code{padding:0;background:none}figure{margin:24px 0}img{max-width:100%;height:auto;display:block;border:1px solid #ccdadd}figcaption{font-size:.85rem;color:#536c78;margin-top:8px}.table-wrap{overflow:auto;border:1px solid #cbdadd;border-radius:6px;margin:20px 0}table{width:100%;border-collapse:collapse;font-size:.91rem}th,td{padding:10px 13px;text-align:left;vertical-align:top;border-bottom:1px solid #dce5e7}th{background:#e5f0ef}tr:last-child td{border:0}tr:nth-child(even) td{background:#f8fbfb}nav{background:#ecf4f2;padding:18px 22px;border-radius:8px;display:grid;grid-template-columns:1fr 1fr;gap:7px 22px;font-size:.9rem}nav strong{grid-column:1/-1}button{font:inherit;border:1px solid #9eb8bd;background:#fff;padding:8px 16px;border-radius:5px;cursor:pointer}.toolbar{display:flex;justify-content:space-between;align-items:center;gap:15px;margin-bottom:26px}.toolbar span{font-size:.85rem;color:#526975}a:focus-visible,button:focus-visible,.table-wrap:focus-visible{outline:3px solid #b66b1f;outline-offset:2px}@media(max-width:700px){main{margin:0;padding:25px 18px;border-radius:0}h1{font-size:1.75rem}nav{grid-template-columns:1fr}th,td{padding:9px}.toolbar{flex-wrap:wrap}}@media print{@page{margin:15mm}body{font-size:10pt;background:#fff}main{margin:0;padding:0;border:0;max-width:none}.toolbar,nav{display:none}h2{break-after:avoid}table{font-size:9pt}tr,figure{break-inside:avoid}thead{display:table-header-group}.table-wrap{overflow:visible}a{color:inherit}pre{font-size:8pt}}
'''


for language in ('en', 'ru'):
    source = HERE / f'assembly_{language}.md'
    content, toc = render(source.read_text())
    title = source.read_text().splitlines()[0][2:]
    label = 'Contents' if language == 'en' else 'Содержание'
    print_label = 'Print / save PDF' if language == 'en' else 'Печать / сохранить PDF'
    first_section = content.index('<h2')
    navigation = f'<nav aria-label="{label}"><strong>{label}</strong>{toc}</nav>'
    content = content[:first_section] + navigation + content[first_section:]
    page = f'''<!doctype html>
<html lang="{language}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>{escape(title)}</title><style>{STYLE}</style></head>
<body><main><div class="toolbar"><span>BGM · codex_cmod_a7 · 2026-11-16</span><button onclick="window.print()">{print_label}</button></div>
{content}
</main></body></html>'''
    (HERE / f'assembly_{language}.html').write_text(page)
    print(HERE / f'assembly_{language}.html')
