import os
import json
from PIL import Image

src_path = 'C:/Users/User/.gemini/antigravity/brain/e71012ca-b79b-4a03-b78e-7af9a0919910/.user_uploaded/media_1794201918940_6f200dc5.jpg'
src_img = Image.open(src_path).convert('RGB')
cream_bg = (254, 248, 230)

# 1. Update assets/my_invitation_logo.png and official_logo.png
os.makedirs('assets', exist_ok=True)
src_img.save('assets/my_invitation_logo.png')
src_img.save('assets/official_logo.png')
print('Saved base assets')

# 2. Android Standard Mipmaps
android_res = 'android/app/src/main/res'
densities = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}
for folder, size in densities.items():
    d = os.path.join(android_res, folder)
    os.makedirs(d, exist_ok=True)
    resized = src_img.resize((size, size), Image.Resampling.LANCZOS)
    resized.save(os.path.join(d, 'ic_launcher.png'))
print('Saved Android standard mipmaps')

# 3. Android Adaptive Icons (Foreground 108dp canvas with safe zone ~66dp -> 66/108 = 61%)
fg_sizes = {
    'mipmap-mdpi': 108,
    'mipmap-hdpi': 162,
    'mipmap-xhdpi': 216,
    'mipmap-xxhdpi': 324,
    'mipmap-xxxhdpi': 432,
}
for folder, canvas_size in fg_sizes.items():
    d = os.path.join(android_res, folder)
    canvas = Image.new('RGBA', (canvas_size, canvas_size), (0, 0, 0, 0))
    logo_size = int(canvas_size * 0.70)
    logo_resized = src_img.convert('RGBA').resize((logo_size, logo_size), Image.Resampling.LANCZOS)
    offset = (canvas_size - logo_size) // 2
    canvas.paste(logo_resized, (offset, offset))
    canvas.save(os.path.join(d, 'ic_launcher_foreground.png'))
print('Saved Android adaptive foregrounds')

# Ensure colors.xml has ic_launcher_background
values_dir = os.path.join(android_res, 'values')
os.makedirs(values_dir, exist_ok=True)
colors_xml = os.path.join(values_dir, 'colors.xml')
if not os.path.exists(colors_xml):
    with open(colors_xml, 'w', encoding='utf-8') as f:
        f.write('<?xml version="1.0" encoding="utf-8"?>\n<resources>\n    <color name="ic_launcher_background">#FEF8E6</color>\n</resources>\n')
else:
    with open(colors_xml, 'r', encoding='utf-8') as f:
        content = f.read()
    if 'ic_launcher_background' not in content:
        content = content.replace('</resources>', '    <color name="ic_launcher_background">#FEF8E6</color>\n</resources>')
        with open(colors_xml, 'w', encoding='utf-8') as f:
            f.write(content)

# Ensure mipmap-anydpi-v26/ic_launcher.xml
v26_dir = os.path.join(android_res, 'mipmap-anydpi-v26')
os.makedirs(v26_dir, exist_ok=True)
xml_content = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
'''
with open(os.path.join(v26_dir, 'ic_launcher.xml'), 'w', encoding='utf-8') as f:
    f.write(xml_content)
with open(os.path.join(v26_dir, 'ic_launcher_round.xml'), 'w', encoding='utf-8') as f:
    f.write(xml_content)
print('Configured Android adaptive icon xmls')

# 4. iOS App Icons
ios_dir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
contents_path = os.path.join(ios_dir, 'Contents.json')
if os.path.exists(contents_path):
    with open(contents_path, 'r', encoding='utf-8') as f:
        meta = json.load(f)
    for entry in meta.get('images', []):
        fn = entry.get('filename')
        sz_str = entry.get('size', '20x20')
        sc_str = entry.get('scale', '1x')
        w, h = [float(x) for x in sz_str.split('x')]
        scale = float(sc_str.replace('x', ''))
        px = int(round(w * scale))
        resized = src_img.resize((px, px), Image.Resampling.LANCZOS)
        resized.save(os.path.join(ios_dir, fn))
print('Saved iOS app icons')

# 5. Web icons
web_dir = 'web'
web_icons_dir = os.path.join(web_dir, 'icons')
os.makedirs(web_icons_dir, exist_ok=True)

src_img.resize((64, 64), Image.Resampling.LANCZOS).save(os.path.join(web_dir, 'favicon.png'))
src_img.resize((192, 192), Image.Resampling.LANCZOS).save(os.path.join(web_icons_dir, 'Icon-192.png'))
src_img.resize((512, 512), Image.Resampling.LANCZOS).save(os.path.join(web_icons_dir, 'Icon-512.png'))
src_img.resize((192, 192), Image.Resampling.LANCZOS).save(os.path.join(web_icons_dir, 'Icon-maskable-192.png'))
src_img.resize((512, 512), Image.Resampling.LANCZOS).save(os.path.join(web_icons_dir, 'Icon-maskable-512.png'))

# Also copy into build/web if it exists
build_web = os.path.join('build', 'web')
if os.path.exists(build_web):
    src_img.resize((64, 64), Image.Resampling.LANCZOS).save(os.path.join(build_web, 'favicon.png'))
    b_icons = os.path.join(build_web, 'icons')
    os.makedirs(b_icons, exist_ok=True)
    src_img.resize((192, 192), Image.Resampling.LANCZOS).save(os.path.join(b_icons, 'Icon-192.png'))
    src_img.resize((512, 512), Image.Resampling.LANCZOS).save(os.path.join(b_icons, 'Icon-512.png'))
    src_img.resize((192, 192), Image.Resampling.LANCZOS).save(os.path.join(b_icons, 'Icon-maskable-192.png'))
    src_img.resize((512, 512), Image.Resampling.LANCZOS).save(os.path.join(b_icons, 'Icon-maskable-512.png'))
print('Saved Web icons')

