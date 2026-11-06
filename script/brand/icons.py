# Regenerates the app icons in public/ from the Clempo mark (app/assets/images/logos/logo.svg).
# Usage: cd to a scratch dir, `python3 path/to/script/brand/icons.py`, then render with rsvg-convert
# (512/192 any + maskable, 180 touch, 96 favicon, 16/32/48 → favicon.ico, 96 badge) and copy into public/.

# Builds the Clempo mark (logos/logo.svg: ring + C + blue dot) at any size.
import sys
INK, BLUE = "#1b1d29", "#2f5bb0"

def mark(cx, cy, R, ring_w, c_w, dot_r, ink=INK, blue=BLUE, ring=True, cls=False):
    k = R / 31.0                      # source logo: ring r=31, C r=16, dot at +14
    sx, sy, ey = cx + 14*k, cy - 10*k, cy + 10*k
    a = 16*k
    ink_attr  = 'class="ink"'  if cls else f'stroke="{ink}"'
    blue_attr = 'class="dot"' if cls else f'fill="{blue}"'
    out = []
    if ring:
        out.append(f'<circle cx="{cx}" cy="{cy}" r="{R - ring_w/2:.2f}" fill="none" {ink_attr} stroke-width="{ring_w:.2f}"/>')
    out.append(f'<path d="M{sx:.2f} {sy:.2f} A{a:.2f} {a:.2f} 0 1 0 {sx:.2f} {ey:.2f}" fill="none" {ink_attr} stroke-width="{c_w:.2f}" stroke-linecap="round"/>')
    out.append(f'<circle cx="{sx:.2f}" cy="{cy}" r="{dot_r:.2f}" {blue_attr}/>')
    return "\n  ".join(out)

def bg(S):
    # White tile with the app's two faint glows (lavender top-right, mint bottom-left).
    return f'''<defs>
    <radialGradient id="g1" cx="1" cy="0" r="0.9"><stop offset="0" stop-color="#e9dcf6" stop-opacity=".9"/><stop offset="1" stop-color="#e9dcf6" stop-opacity="0"/></radialGradient>
    <radialGradient id="g2" cx="0" cy="1" r="0.85"><stop offset="0" stop-color="#d6f1e6" stop-opacity=".9"/><stop offset="1" stop-color="#d6f1e6" stop-opacity="0"/></radialGradient>
  </defs>
  <rect width="{S}" height="{S}" fill="#f7f7fa"/>
  <rect width="{S}" height="{S}" fill="url(#g1)"/>
  <rect width="{S}" height="{S}" fill="url(#g2)"/>'''

def tile(S, scale):
    R = S*scale
    k = R/31
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {S} {S}" width="{S}" height="{S}">
  {bg(S)}
  {mark(S/2 - 2.5*k, S/2, R, max(1.6*k, S/170), 3.6*k, 2.3*k)}
</svg>
'''

def favicon():
    # Transparent, heavier strokes, follows the browser's light/dark tab.
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
  <style>
    .ink {{ stroke: {INK}; }} .dot {{ fill: {BLUE}; }}
    @media (prefers-color-scheme: dark) {{ .ink {{ stroke: #eef0f6; }} .dot {{ fill: #7f9cf0; }} }}
  </style>
  {mark(32, 32, 31, 3.2, 6.4, 4.2, cls=True)}
</svg>
'''

def favicon_png_src():
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
  {mark(32, 32, 31, 3.2, 6.4, 4.2)}
</svg>
'''

def badge(S=96):
    # Android status-bar badge: alpha mask only, so white C + dot, no hairline ring.
    k = S/2/22
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {S} {S}" width="{S}" height="{S}">
  {mark(S/2 - 4*k, S/2, 31*k, 0, 7*k, 4.6*k, ink="#ffffff", blue="#ffffff", ring=False)}
</svg>
'''

files = {
  "icon-any.svg": tile(512, 0.36),
  "icon-maskable.svg": tile(512, 0.30),   # ring stays inside the 40% safe zone
  "icon-touch.svg": tile(180, 0.34),
  "favicon.svg": favicon(),
  "favicon-src.svg": favicon_png_src(),
  "badge.svg": badge(),
}
for name, svg in files.items():
    open(name, "w").write(svg)
