from PIL import Image
from pathlib import Path

splash_path = Path(r'c:\Project\Reader\assets\splash\reader_splash.png')
src = Image.open(splash_path).convert('RGBA')
px = src.load()
w, h = src.size

xs, ys = [], []
for y in range(h):
    for x in range(w):
        r, g, b, a = px[x, y]
        if a > 200 and not (r > 245 and g > 245 and b > 245):
            xs.append(x)
            ys.append(y)

left, top, right, bottom = min(xs), min(ys), max(xs), max(ys)
# small margin so we don't clip anti-alias
pad = 8
left = max(0, left - pad)
top = max(0, top - pad)
right = min(w - 1, right + pad)
bottom = min(h - 1, bottom + pad)
content = src.crop((left, top, right + 1, bottom + 1))

# Scale content to fill ~96% of a square canvas (larger on home screen).
canvas = 1024
target = int(canvas * 0.96)
cw, ch = content.size
scale = target / max(cw, ch)
nw, nh = int(cw * scale), int(ch * scale)
scaled = content.resize((nw, nh), Image.Resampling.LANCZOS)

# Soft blue-lavender background matching splash.
bg = Image.new('RGB', (canvas, canvas), (170, 205, 240))
out = bg.convert('RGBA')
ox = (canvas - nw) // 2
oy = (canvas - nh) // 2
out.alpha_composite(scaled, (ox, oy))
final_src = out.convert('RGB').convert('RGBA')

sizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

res_root = Path(r'c:\Project\Reader\android\app\src\main\res')
assets_root = Path(r'c:\Project\Reader\assets\app_icons\android')

for folder, size in sizes.items():
    icon = final_src.resize((size, size), Image.Resampling.LANCZOS)
    for root in (res_root, assets_root):
        dest_dir = root / folder
        dest_dir.mkdir(parents=True, exist_ok=True)
        icon.save(dest_dir / 'ic_launcher.png', 'PNG')
        print('wrote', dest_dir / 'ic_launcher.png', size)

master = Path(r'c:\Project\Reader\assets\app_icons\ic_launcher_master.png')
final_src.resize((512, 512), Image.Resampling.LANCZOS).save(master, 'PNG')
print('master', master)

check = Image.open(res_root / 'mipmap-xxxhdpi' / 'ic_launcher.png').convert('RGBA')
print('corner', check.getpixel((0, 0)))
