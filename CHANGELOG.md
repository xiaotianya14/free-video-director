# Changelog

## v0.0.1 — 2026-11-16
- 首版：六步导演流程（分镜→提示词→豆包生成→收片→本地后期→质检）
- 结构化提示词模板（画幅/主体/环境/光/镜头/材质/风格/画质/负面）
- FFmpeg 配方：拼接、竖屏/横屏统一、字幕、BGM、响度
- 常见坑与踩坑解法（AI 写错字、额度、授权弹窗、尺寸不统一）
- 合规：新增 NOTICE、Apache-2.0 许可证副本与知识库来源说明；移除含第三方文字引用的 skill-creator；含艺术家姓名的标题改为通用风格名
- 吸收 54 个视频技能、195 篇知识库文档（25 万字），含 11 条核心规则提炼
- 联网吸收：Seedance/豆包官方提示词公式、动作四原则、约束词、官方常见坑（换脸/双胞胎/风格漂移/衔接跳变/多音字）、短视频钩子 → `docs/网络最佳实践.md`
- 环境三件套：`env_check.sh`（检测/版本）、`env_install.sh`（自动装缺项）、`smoke_test.sh`（2D+3D 真出图验证）；`assets/tool-manifest.json` 工具清单
- 2D/3D 模板：`assets/2d-overlay.py`、`assets/3d-template.py`（Blender EEVEE 相机推进/浮卡/三点光）
- 发布两件套：zip + `.sha256` + `SHA256SUMS`，附 `scripts/verify_release.sh`（下载校验）
- 可选 dsh-go 原生「视频工坊」面板
