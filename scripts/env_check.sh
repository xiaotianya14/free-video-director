#!/usr/bin/env bash
# 环境自检：检测工具是否已安装、版本是否达标、能否跑通；输出 JSON + 人话摘要
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
MANIFEST="$(cd "$HERE/.." && pwd)/assets/tool-manifest.json"
[ -f "$MANIFEST" ] || { echo "找不到 tool-manifest.json"; exit 1; }
python3 - "$MANIFEST" <<'PY'
import json, subprocess, sys, shutil, re, os
man=json.load(open(sys.argv[1]))
out=[]
def run(cmd):
    try:
        p=subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=60)
        return p.returncode, (p.stdout or '')+(p.stderr or '')
    except Exception as e:
        return 1, str(e)
for t in man['tools']:
    code, txt = run(t['check'])
    installed = code==0
    version=None
    if installed:
        m=re.search(r'(\d+\.\d+(?:\.\d+)?)', txt)
        version=m.group(1) if m else None
    ok_version=True
    if installed and version and t.get('min'):
        try:
            a=[int(x) for x in version.split('.')[:3]]
            b=[int(x) for x in str(t['min']).split('.')[:3]]
            while len(a)<len(b): a.append(0)
            while len(b)<len(a): b.append(0)
            ok_version = a>=b
        except: ok_version=True
    smoke_ok=False
    if installed and ok_version:
        sc,_=run(t['smoke']); smoke_ok = sc==0
    status = 'ok' if (installed and ok_version and smoke_ok) else ('missing' if not installed else ('incomplete' if not smoke_ok else 'version-low'))
    out.append({**{k:t.get(k) for k in ('id','name','why','required','min')},
                'status':status,'version':version,'installed':installed,'smoke_ok':smoke_ok})
print(json.dumps({'platform':man.get('platform'),'tools':out}, ensure_ascii=False, indent=2))
bad=[x for x in out if x['status']!='ok']
print('\n===== 人话摘要 =====')
for x in out:
    mark={'ok':'✅','missing':'❌ 未安装','incomplete':'⚠️ 已装但跑不通','version-low':'⚠️ 版本过低'}[x['status']]
    print(f"{mark} {x['name']:<16} {x['version'] or '-':<12} {x['why']}")
req=[x for x in bad if x['required']]
print(f"\n必装缺失/异常: {len(req)} 个" + ("" if not req else " → 运行 scripts/env_install.sh"))
print(f"可选（3D）: " + (", ".join(x['name'] for x in bad if not x['required']) or "全部正常"))
sys.exit(0 if not req else 2)
PY
