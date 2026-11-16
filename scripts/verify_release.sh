#!/usr/bin/env bash
# 校验下载的发布包是否完整（下载校验，不是运行校验）
# 用法: bash verify_release.sh free-video-director-v0.0.1.zip [sha256文件]
set -u
F="${1:?用法: verify_release.sh <zip> [zip.sha256]}"
S="${2:-$F.sha256}"
[ -f "$F" ] || { echo "❌ 找不到 $F"; exit 1; }
[ -f "$S" ] || { echo "❌ 找不到校验文件 $S"; exit 1; }
echo "== 期望: $(cat "$S")"
ACT=$(sha256sum "$F" | awk '{print $1}')
EXP=$(awk '{print $1}' "$S")
if [ "$ACT" = "$EXP" ]; then echo "✅ 校验通过：$F"; exit 0; else echo "❌ 校验失败！实际 $ACT"; exit 1; fi
