#!/usr/bin/env bash
# 自动安装缺失工具：apt 优先；装完复检并冒烟测试。不下载来路不明的二进制。
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
MAN="$ROOT/assets/tool-manifest.json"
LOG="/tmp/free-video-director-install.log"
echo "== 安装开始 $(date) ==" | tee -a "$LOG"

PKGS=$(python3 - "$MAN" <<'PY'
import json,sys,subprocess
man=json.load(open(sys.argv[1])); pk=set()
for t in man['tools']:
    p=subprocess.run(t['check'], shell=True, capture_output=True)
    if p.returncode!=0 and t.get('install',{}).get('kind')=='apt':
        pk.add(t['install']['package'])
print(' '.join(sorted(pk)))
PY
)
if [ -n "$PKGS" ]; then
  echo ">> 需要安装: $PKGS" | tee -a "$LOG"
  apt-get update -qq >>"$LOG" 2>&1 || true
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq $PKGS >>"$LOG" 2>&1 || true
else
  echo ">> 所有必装工具已就绪，无需安装" | tee -a "$LOG"
fi

echo "== 复检 ==" | tee -a "$LOG"
bash "$HERE/env_check.sh" | tee -a "$LOG"
echo "== 冒烟（2D + 3D）==" | tee -a "$LOG"
bash "$HERE/smoke_test.sh" | tee -a "$LOG"
