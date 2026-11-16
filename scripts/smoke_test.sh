#!/usr/bin/env bash
# 冒烟测试：2D（FFmpeg+PIL）与 3D（Blender EEVEE 单帧）各跑一次，证明"能用"而不是"已安装"
set -u
TMP=/tmp/fvd_smoke; rm -rf "$TMP"; mkdir -p "$TMP"
fail=0
echo "== 2D 冒烟 =="
ffmpeg -y -loglevel error -f lavfi -i color=c=white:s=320x320:d=1 -frames:v 1 "$TMP/a.png" && echo "✅ ffmpeg 出图"
python3 - <<'PY2' && echo "✅ PIL 中文出图" || fail=1
from PIL import Image, ImageDraw, ImageFont
import subprocess, os, glob
path = subprocess.run(['fc-match','-f','%{file}','Noto Sans CJK SC'], capture_output=True, text=True).stdout.strip()
if not path or not os.path.exists(path):
    cands = glob.glob('/system/fonts/*CJK*.ttc') + glob.glob('/usr/share/fonts/**/*.ttc', recursive=True)
    path = cands[0] if cands else None
if not path: raise SystemExit('无中文字体')
img=Image.new('RGB',(320,120),(255,255,255)); d=ImageDraw.Draw(img)
f=ImageFont.truetype(path, 40); d.text((10,40),'测试中文 2D',font=f,fill=(20,20,20))
img.save('/tmp/fvd_smoke/t.png')
PY2
echo "== 3D 冒烟（Blender 单帧，可能较慢）=="
if command -v blender >/dev/null 2>&1; then
  cat > "$TMP/s.py" <<'PY'
import bpy
bpy.ops.wm.read_factory_settings(use_empty=True)
sc=bpy.context.scene; sc.render.engine='BLENDER_EEVEE'; sc.render.resolution_x=160; sc.render.resolution_y=160
sc.render.filepath='/tmp/fvd_smoke/b.png'
bpy.ops.mesh.primitive_cube_add(); bpy.ops.object.camera_add(location=(3,-3,2.5), rotation=(1.1,0,0.78)); sc.camera=bpy.context.object
bpy.ops.object.light_add(type='AREA', location=(2,-2,3))
bpy.ops.render.render(write_still=True)
print('BLENDER_OK')
PY
  blender -b --python "$TMP/s.py" 2>/dev/null | tee "$TMP/bl.log" | grep -q BLENDER_OK && [ -s "$TMP/b.png" ] && echo "✅ Blender 3D 出图 ($(stat -c%s "$TMP/b.png") bytes)" || { echo "❌ Blender 3D 失败"; fail=1; }
else
  echo "⏭️ 未安装 Blender（3D 可选，2D 不受影响）"
fi
echo "== 结果 =="; ls -lh "$TMP"/*.png 2>/dev/null
exit $fail
