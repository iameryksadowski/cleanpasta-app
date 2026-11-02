import re, sys, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).parent))
from generate import RING, ring, clip, text, LIGHT, DARK
OUT = pathlib.Path(sys.argv[1]); OUT.mkdir(parents=True, exist_ok=True)
L = dict(LIGHT, sig="#F4F4F5", sig2="#E4E4E7", glow="#10B981", tile="#FFFFFF")
D = dict(DARK, sig="#18181B", sig2="#27272A", glow="#10B981", tile="#18181B")

def frame(p, inner, defs=""):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024"><defs>{defs}'
            f'<clipPath id="sq"><rect x="100" y="100" width="824" height="824" rx="185"/></clipPath>'
            f'<filter id="blur" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="46"/></filter>'
            f'<filter id="blur2" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="90"/></filter></defs>'
            f'<rect x="100" y="100" width="824" height="824" rx="185" fill="{p["bg"]}"/>'
            f'<g clip-path="url(#sq)">{inner}</g>'
            f'<rect x="101.5" y="101.5" width="821" height="821" rx="183.5" fill="none" stroke="{p["border"]}" stroke-width="3"/></svg>')

def center_clip(p, s=360, stroke=None, fill=None, lines=None):
    w = 0.76 * s
    return clip(512 - w/2, 512 - s/2, s, stroke or p["fg"], fill or p["bg"], lines or stroke or p["fg"])

V = []
def v(n):
    def d(f): V.append((n, f)); return f
    return d

@v("Sygnet przycięty w rogu (jak PDF) + schowek")
def a(p): return ring(820, 820, 900, p["sig"]) + center_clip(p)
@v("Sygnet przycięty + zielona poświata")
def b(p): return f'<g filter="url(#blur)" opacity="0.55">{ring(800, 800, 820, p["glow"])}</g>' + ring(800, 800, 820, p["sig"]) + center_clip(p)
@v("Poświata sygnetu za schowkiem")
def c(p): return f'<g filter="url(#blur2)" opacity="0.45">{ring(512, 512, 700, p["glow"])}</g>' + center_clip(p)
@v("Duży sygnet w tle, schowek na środku")
def d(p): return ring(512, 512, 760, p["sig"]) + center_clip(p, 330)
@v("Sygnet w tle, zielony schowek")
def e(p): return ring(512, 512, 760, p["sig"]) + center_clip(p, 330, p["accent"], p["bg"], p["accent"])
@v("Sygnet przycięty, schowek na kafelku")
def f(p): return ring(830, 830, 900, p["sig"]) + f'<rect x="297" y="297" width="430" height="430" rx="96" fill="{p["tile"]}" stroke="{p["sig2"]}" stroke-width="6"/>' + center_clip(p, 280)
@v("Zielony sygnet przycięty (lewy górny) + schowek")
def g(p): return f'<g opacity="0.16">{ring(220, 220, 900, p["accent"])}</g>' + center_clip(p)
@v("Poświata + mały pierścień w rogu")
def h(p): return f'<g filter="url(#blur2)" opacity="0.40">{ring(512, 540, 640, p["glow"])}</g>' + center_clip(p, 340) + ring(790, 790, 120, p["accent"])

cell, pad, cols = 230, 30, 4
rows = (len(V) + cols - 1) // cols
W = cols * (2 * cell + pad) + pad; H = rows * (cell + 70) + 90
parts = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}"><rect width="{W}" height="{H}" fill="#E9E9EC"/>',
         text(pad, 55, 30, "#171717", "Cleanpasta - sygnet w tle, ikona na środku (jasna | ciemna)", 600, anchor="start")]
for i, (name, fn) in enumerate(V):
    r, cidx = divmod(i, cols); x = pad + cidx * (2 * cell + pad); y = 90 + r * (cell + 70)
    for j, pal in enumerate((L, D)):
        svg = frame(pal, fn(pal))
        (OUT / f"{chr(65+i)}-{'light' if j == 0 else 'dark'}.svg").write_text(svg)
        # nested svg ids must be unique per cell
        svg = svg.replace('id="sq"', f'id="sq{i}{j}"').replace('url(#sq)', f'url(#sq{i}{j})').replace('id="blur"', f'id="b{i}{j}"').replace('url(#blur)', f'url(#b{i}{j})').replace('id="blur2"', f'id="c{i}{j}"').replace('url(#blur2)', f'url(#c{i}{j})')
        parts.append(svg.replace('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">', f'<svg x="{x + j*cell}" y="{y}" width="{cell}" height="{cell}" viewBox="0 0 1024 1024">'))
    parts.append(text(x + 4, y + cell + 30, 20, "#171717", f"{chr(65+i)}. {name}", 600, anchor="start"))
parts.append("</svg>")
(OUT / "sheet2.svg").write_text("".join(parts)); print(len(V))
