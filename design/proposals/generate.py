import re, sys, pathlib
B = str(pathlib.Path.home() / "Development/estools-docs/brand/logo") + "/"  # ES Tools brand files
RING = re.search(r'<path d="([^"]+)"', open(B + "estools-icon.svg").read()).group(1)
WM = re.findall(r'<path d="([^"]+)"', open(B + "estools-wordmark-dark.svg").read())
OUT = pathlib.Path(sys.argv[1])
LIGHT = dict(bg="#FFFFFF", border="#E4E4E7", fg="#171717", muted="#A1A1AA", accent="#10B981", surface="#F4F4F5", on_accent="#FFFFFF")
DARK = dict(bg="#0A0A0A", border="#27272A", fg="#FAFAFA", muted="#71717A", accent="#10B981", surface="#18181B", on_accent="#0A0A0A")

def frame(p, inner):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">'
            f'<rect x="100" y="100" width="824" height="824" rx="185" fill="{p["bg"]}"/>'
            f'<rect x="101.5" y="101.5" width="821" height="821" rx="183.5" fill="none" stroke="{p["border"]}" stroke-width="3"/>'
            f'{inner}</svg>')

def ring(cx, cy, d, color):
    s = d / 297.0
    return f'<g transform="translate({cx} {cy}) scale({s:.4f}) translate(-256.2 -256)"><path d="{RING}" fill="{color}"/></g>'

def wordmark(cx, cy, w, color):
    s = w / 705.453
    paths = "".join(f'<path d="{d}"/>' for d in WM)
    # the wordmark's first "o" is the green ring: keep the letters in fg, ring path in accent
    return f'<g transform="translate({cx - w/2} {cy - 179*s/2}) scale({s:.4f})" fill="{color}">{paths}</g>'

def clip(x, y, s, stroke, fill, lines=None):
    # clipboard glyph, top-left at x,y, size s (height); width = 0.76 s
    w, h, sw = 0.76 * s, s, max(2, s * 0.07)
    lines = lines or stroke
    return (f'<rect x="{x}" y="{y + 0.08*s}" width="{w}" height="{h*0.92}" rx="{s*0.12}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>'
            f'<rect x="{x + w*0.28}" y="{y}" width="{w*0.44}" height="{s*0.18}" rx="{s*0.06}" fill="{stroke}"/>'
            f'<line x1="{x+w*0.22}" y1="{y+s*0.42}" x2="{x+w*0.70}" y2="{y+s*0.42}" stroke="{lines}" stroke-width="{sw*1.2}" stroke-linecap="round"/>'
            f'<line x1="{x+w*0.22}" y1="{y+s*0.58}" x2="{x+w*0.78}" y2="{y+s*0.58}" stroke="{lines}" stroke-width="{sw*0.8}" stroke-linecap="round" opacity="0.55"/>'
            f'<line x1="{x+w*0.22}" y1="{y+s*0.72}" x2="{x+w*0.60}" y2="{y+s*0.72}" stroke="{lines}" stroke-width="{sw*0.8}" stroke-linecap="round" opacity="0.55"/>')

def text(x, y, size, color, t, weight=600, family="Geist", anchor="middle", ls=0):
    return f'<text x="{x}" y="{y}" font-family="{family}" font-weight="{weight}" font-size="{size}" fill="{color}" text-anchor="{anchor}" letter-spacing="{ls}">{t}</text>'

def badge_circle(cx, cy, r, p, inner, fill=None, ring_stroke=True):
    return (f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{fill or p["bg"]}" stroke="{p["border"] if ring_stroke else "none"}" stroke-width="4"/>' + inner)

def keycap(x, y, s, p, label="V"):
    return (f'<rect x="{x}" y="{y}" width="{s}" height="{s}" rx="{s*0.22}" fill="{p["surface"]}" stroke="{p["fg"]}" stroke-width="{s*0.06}"/>'
            + text(x + s*0.5, y + s*0.68, s*0.5, p["fg"], label, 600))

V = []
def v(name):
    def deco(f): V.append((name, f)); return f
    return deco

@v("Pierścień + schowek w kółku (róg)")
def v1(p): return ring(480, 480, 470, p["accent"]) + badge_circle(730, 730, 140, p, clip(678, 655, 150, p["fg"], p["bg"]))
@v("Pierścień + mały schowek w środku")
def v2(p): return ring(512, 512, 560, p["accent"]) + clip(455, 437, 150, p["fg"], p["bg"])
@v("Pierścień + nazwa na dole")
def v3(p): return ring(512, 450, 440, p["accent"]) + text(512, 810, 92, p["fg"], "paste", 600, ls=-2)
@v("Wordmark estools + schowek w rogu")
def v4(p): return wordmark(512, 470, 640, p["fg"]) + clip(700, 650, 170, p["accent"], p["bg"], p["accent"])
@v("Pierścień + etykieta Cleanpasta")
def v5(p): return ring(512, 440, 420, p["accent"]) + f'<rect x="262" y="720" width="500" height="112" rx="56" fill="{p["fg"]}"/>' + text(512, 795, 58, p["bg"], "Cleanpasta", 600)
@v("Pierścień + monogram CP w rogu")
def v6(p): return ring(470, 470, 480, p["accent"]) + badge_circle(735, 735, 130, p, text(735, 772, 104, p["fg"], "CP", 700, ls=-4))
@v("Pierścień + schowek w rogu bez tła")
def v7(p): return ring(480, 480, 500, p["accent"]) + clip(690, 640, 190, p["fg"], p["bg"])
@v("Pierścień jako rama, schowek w środku")
def v8(p): return ring(512, 512, 700, p["accent"]) + clip(440, 415, 200, p["fg"], p["bg"])
@v("Pierścień + zagięty róg ze schowkiem")
def v9(p): return ring(470, 470, 480, p["accent"]) + f'<path d="M924 600 L924 739 Q924 924 739 924 L600 924 Z" fill="{p["fg"]}"/>' + clip(770, 760, 110, p["bg"], p["fg"], p["bg"])
@v("Pierścień + klawisz V (wklej)")
def v10(p): return ring(470, 470, 480, p["accent"]) + keycap(650, 650, 190, p)
@v("Pierścień + znak czystego tekstu Tt")
def v11(p): return ring(470, 470, 480, p["accent"]) + badge_circle(735, 735, 130, p, text(735, 777, 118, p["fg"], "Tt", 600, ls=-4))
@v("Pierścień + iskra (czyszczenie)")
def v12(p):
    star = f'<path d="M735 640 C748 700 770 722 830 735 C770 748 748 770 735 830 C722 770 700 748 640 735 C700 722 722 700 735 640 Z" fill="{p["fg"]}"/>'
    return ring(470, 470, 480, p["accent"]) + badge_circle(735, 735, 130, p, star)
@v("Pierścień + pigułka PASTE")
def v13(p): return ring(512, 450, 440, p["accent"]) + f'<rect x="352" y="740" width="320" height="86" rx="43" fill="{p["accent"]}"/>' + text(512, 797, 48, p["on_accent"], "PASTE", 700, family="Geist Mono", ls=6)
@v("Pierścień + zielony pas ze schowkiem")
def v14(p): return ring(512, 420, 400, p["accent"]) + f'<path d="M100 700 L924 700 L924 739 Q924 924 739 924 L285 924 Q100 924 100 739 Z" fill="{p["accent"]}"/>' + clip(452, 732, 160, p["on_accent"], p["accent"], p["on_accent"])
@v("Pierścień na podkładce schowka")
def v15(p): return f'<rect x="262" y="230" width="500" height="600" rx="70" fill="{p["surface"]}" stroke="{p["fg"]}" stroke-width="26"/><rect x="412" y="190" width="200" height="90" rx="30" fill="{p["fg"]}"/>' + ring(512, 540, 340, p["accent"])
@v("Pierścień + proste cudzysłowy")
def v16(p): return ring(470, 470, 480, p["accent"]) + badge_circle(735, 735, 130, p, text(735, 810, 190, p["fg"], "&quot;", 600))
@v("es duże + schowek")
def v17(p): return text(470, 600, 400, p["fg"], "es", 600, ls=-24) + clip(690, 640, 180, p["accent"], p["bg"], p["accent"])
@v("Pierścień + zielona naklejka V")
def v18(p): return ring(470, 470, 480, p["fg"]) + f'<rect x="650" y="650" width="200" height="200" rx="48" fill="{p["accent"]}"/>' + text(750, 790, 130, p["on_accent"], "V", 700)
@v("Pierścień + schowek i nazwa")
def v19(p): return ring(512, 430, 400, p["accent"]) + clip(300, 700, 120, p["fg"], p["bg"]) + text(400, 790, 72, p["fg"], "Cleanpasta", 600, anchor="start", ls=-2)
@v("Pierścień + nazwa pod spodem mono")
def v20(p): return ring(512, 450, 450, p["accent"]) + text(512, 800, 54, p["muted"], "CLEANPASTA", 500, family="Geist Mono", ls=8)

OUT.mkdir(parents=True, exist_ok=True)
cell, pad, cols = 220, 30, 5
rows = (len(V) + cols - 1) // cols
W = cols * (2 * cell + pad) + pad
H = rows * (cell + 70) + 90
parts = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}"><rect width="{W}" height="{H}" fill="#E9E9EC"/>',
         text(pad, 55, 30, "#171717", "ES Tools Cleanpasta - 20 propozycji ikony (jasna | ciemna)", 600, anchor="start")]
for i, (name, f) in enumerate(V):
    r, c = divmod(i, cols)
    x = pad + c * (2 * cell + pad); y = 90 + r * (cell + 70)
    for j, pal in enumerate((LIGHT, DARK)):
        svg = frame(pal, f(pal))
        (OUT / f"{i+1:02d}-{'light' if j == 0 else 'dark'}.svg").write_text(svg)
        inner = svg.replace('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">', f'<svg x="{x + j*cell}" y="{y}" width="{cell}" height="{cell}" viewBox="0 0 1024 1024">')
        parts.append(inner)
    parts.append(text(x + 4, y + cell + 30, 20, "#171717", f"{i+1}. {name}", 600, anchor="start"))
parts.append("</svg>")
(OUT / "sheet.svg").write_text("".join(parts))
print(len(V), "variants")
