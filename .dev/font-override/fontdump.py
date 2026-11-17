import sys
from pdfminer.high_level import extract_pages
from pdfminer.layout import LTTextLine, LTChar, LTContainer


def lines(page):
    stack = [page]
    while stack:
        el = stack.pop()
        if isinstance(el, LTTextLine):
            yield el
        elif isinstance(el, LTContainer):
            stack.extend(list(el))


for path in sys.argv[1:]:
    print("=== " + path)
    for page in extract_pages(path):
        for el in lines(page):
            fonts = {}
            for ch in el:
                if isinstance(ch, LTChar) and ch.fontname and not ch.fontname.startswith("FontAwesome"):
                    key = (ch.fontname.split("+")[-1], round(ch.size, 1))
                    fonts[key] = fonts.get(key, 0) + 1
            text = el.get_text().strip().replace("\n", " ")
            if text:
                print(f"{text[:55]!r:58} {fonts}")
