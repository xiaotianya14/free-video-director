# 2D 叠加模板：在任意底图/帧序列上画标题、副标题、进度条（PIL，保证中文正确）
# 用法: python3 2d-overlay.py --src frames_dir --out out_dir --title "标题" --sub "副标题"
import argparse, os, glob
from PIL import Image, ImageDraw, ImageFont

def cjk_font(size):
    import subprocess, glob as g
    p = subprocess.run(['fc-match','-f','%{file}','Noto Sans CJK SC'], capture_output=True, text=True).stdout.strip()
    if not p or not os.path.exists(p):
        c = g.glob('/system/fonts/*CJK*.ttc') + g.glob('/usr/share/fonts/**/*.ttc', recursive=True)
        p = c[0] if c else None
    return ImageFont.truetype(p, size) if p else ImageFont.load_default()

ap = argparse.ArgumentParser()
ap.add_argument('--src', required=True); ap.add_argument('--out', required=True)
ap.add_argument('--title', default=''); ap.add_argument('--sub', default='')
ap.add_argument('--size', type=int, default=1080)
a = ap.parse_args()
os.makedirs(a.out, exist_ok=True)
files = sorted(glob.glob(os.path.join(a.src, '*.png')))
if not files: raise SystemExit('没有输入帧')
ft = cjk_font(int(a.size*0.075)); fs = cjk_font(int(a.size*0.036))
for i, f in enumerate(files):
    im = Image.open(f).convert('RGB').resize((a.size, a.size), Image.LANCZOS)
    d = ImageDraw.Draw(im)
    if a.title: d.text((a.size*0.08, a.size*0.16), a.title, font=ft, fill=(20,20,22))
    if a.sub:   d.text((a.size*0.08, a.size*0.16 + a.size*0.10), a.sub, font=fs, fill=(70,70,74))
    # 底部进度条
    x0, x1, y = a.size*0.08, a.size*0.92, a.size*0.94
    d.line([(x0,y),(x1,y)], fill=(210,210,210), width=2)
    d.line([(x0,y),(x0+(x1-x0)*(i+1)/len(files),y)], fill=(200,40,30), width=3)
    im.save(os.path.join(a.out, os.path.basename(f)))
print('2D_OVERLAY_DONE', len(files))
