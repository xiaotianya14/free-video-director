---
name: free-video-director
description: 用豆包 App 等免费额度做短视频/宣传片的完整导演流程：分镜 → 结构化长提示词 → 模拟点击豆包生成 → 自动收片 → 本地 FFmpeg 剪辑字幕合成 → 质检交付。没有视频模型 API、只有手机和豆包免费版时用。
whenToUse: 用户说「用豆包做视频」「免费做个宣传片/短片」「没有 API 也想生成视频」「把分镜生成成片」「手机做视频」，或要用豆包免费版当生成后端、本地合成出片时使用。
---

# 免费视频导演（free-video-director）

> 目标：**零 API 费用**做出能发布的产品短片。
> 后端 = 豆包 App 免费视频生成（也可换同类免费工具）；后期 = 本机 FFmpeg + PIL；导演 = 你（AI）。

## 零、开箱环境（自动检测 / 自动安装 / 冒烟验证）

本技能自带「环境三件套」，**先跑检测，缺什么装什么，装完必须冒烟通过**，再开始做视频：

```bash
# 1) 检测：已装？版本够？能跑通？（JSON + 人话摘要）
bash scripts/env_check.sh

# 2) 一键安装缺失项（apt 优先；装完自动复检 + 冒烟）
bash scripts/env_install.sh

# 3) 冒烟：2D（FFmpeg+PIL 中文）与 3D（Blender EEVEE 单帧）各出一次图
bash scripts/smoke_test.sh
```

工具清单在 `assets/tool-manifest.json`（每个工具含：检测命令、最低版本、安装方式、体积、冒烟命令、是否必装）：

| 工具 | 作用 | 必装 |
|---|---|---|
| FFmpeg / FFprobe | 剪辑、转码、拼接、读规格 | 是 |
| Python 3 + Pillow | 2D 叠字/字幕（保证中文正确） | 是 |
| 中文字体（Noto CJK） | 字幕标题，缺字会变方框 | 是 |
| **Blender（EEVEE）** | **3D 场景/旋转/3D 底图** | 否（做 3D 才需要） |

设计原则：**包里不带二进制**，只带清单 + 检测 + 安装脚本；安装走系统包管理器（可换国内镜像），安装后必须冒烟通过才算「可用」，防止「装了一半/版本不对」。

## 零之二、2D 与 3D 两条制作路径

### 2D 路径（快、稳、文字一定对）
1. PIL 生成标题/字幕/进度条 → `assets/2d-overlay.py`
2. FFmpeg 叠加到底图或实拍帧
3. 适合：文字卡、流程演示、字幕版宣传片

### 3D 路径（质感好，渲染慢）
1. Blender headless 渲染 PNG 序列 → `assets/3d-template.py`（带相机推进/浮动卡片/三点布光/EEVEE 8 采样）
2. FFmpeg 合成 25fps 视频 → 再叠 2D 文字
3. 手机建议：540–720p 渲染、6–8 采样、一镜 3–10 秒；1080p 视机型而定
4. 适合：产品旋转、3D 底图、抽象科技感空镜

## 一、什么时候用
- 买不起/不想买视频模型 API，只有一台手机 + 豆包免费版
- 要做宣传片、产品展示、口播旁白片、短剧切片
- 需要「画面好看 + 文字一字不错」（AI 生成文字不可靠，必须后期叠加）

## 二、核心心法（先记住这三条）
1. **豆包只出空镜**：不要求豆包生成中文字/标题，AI 会写错（实测「签名」被生成成「签包」）。文字全部后期叠。
2. **一个镜头一个动作**：一条提示词只写一个主要动作 + 一个主要运镜，不要塞多个镜头。
3. **提示词要像导演阐述**：主体/动作/环境/镜头（景别+机位+运动）/光线/材质/风格/画质/**负面词**。越具体越不简陋。

## 三、流程（六步）

### 第 1 步：定片型与时长
| 片型 | 时长 | 画幅 | 用途 |
|---|---|---|---|
| 平台短视频 | 15–45s | 9:16 | 抖音/小红书/视频号 |
| 横屏宣传片 | 30–60s | 16:9 | B站/电脑/官网 |
| 产品展示 | 6–12s | 1:1 或 9:16 | 详情页/封面 |

### 第 2 步：写分镜（shot list）
每个镜头写清：序号 / 时长 / 内容一句话 / 景别（远中近特）/ 运镜（推拉摇移跟）/ 光 / 作用（钩子/演示/证据/CTA）。
存成项目文件：`/sdcard/DSH Go/视频项目/project.json`
```json
{"title":"项目名","shots":[{"title":"镜1 手机悬浮空镜","status":"todo","prompt":"…","file":""}]}
```

### 第 3 步：写结构化长提示词
模板（中文，豆包可直接用）：
```
画幅9:16，<主体与状态>；<环境与背景细节>；<光线方向与质感>；镜头<景别>，<机位>，<运动>，<景深>；<材质/质感>；风格：<风格词>；画质：<清晰度/帧率/色彩>；画面内无任何文字；负面：文字、水印、logo、字幕、人物、畸形、闪烁、变形
```
要点：
- 负面词必写，尤其「文字、水印、logo」
- 想要产品广告感：加「高端产品广告、干净克制、体积光、轮廓光、浅景深」
- 想真实：加「自然光、生活感、轻微手持」
- 一条不超过 ~300 字，太长模型会丢条件

### 第 4 步：豆包生成（模拟点击）
1. 打开豆包 App → **AI 创作** → **视频生成**
2. 粘贴提示词 → 发送（模型 Seedance 2.0 Mini，免费版约 10s/条，等待 3–5 分钟）
3. 生成好点**保存** → 文件落在 `/sdcard/Movies/<数字>.mp4`
4. 首次会弹系统授权框，需人工点「允许」

> 额度有限：先跑 1 条看风格，满意再批量。

### 第 5 步：收片与后期（全本地，免费）
- 收片：把新视频复制到 `/sdcard/DSH Go/视频项目/镜头N.mp4`
- 拼接：`ffmpeg -f concat -safe 0 -i concat.txt -c:v libx264 -crf 20 -pix_fmt yuv420p -c:a aac 成片.mp4`
- 竖屏统一：`scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2`
- 横屏统一：`scale=1920:1080:...pad=1920:1080:...`
- 加字幕/BGM：用 SRT + `subtitles=` 滤镜；BGM 用 `amix` 并 `loudnorm=I=-16:TP=-1.5`
- 中文文字层：用 PIL 画 PNG 再叠加（保证一字不错），或 `drawtext`

### 第 6 步：质检（交付前必做）
- [ ] 时长/画幅/帧率符合平台
- [ ] 没有 AI 错字（尤其画内文字）
- [ ] 每镜首尾无穿帮、无黑帧
- [ ] 响度 -16 LUFS 左右，峰值 ≤ -1.5 dBTP
- [ ] 抽 3–5 帧看画面（`ffmpeg -ss N`）确认干净
- [ ] 文案与画面对得上

## 四、常见坑
| 坑 | 现象 | 解法 |
|---|---|---|
| AI 写中文字 | 「签名」变「签包」 | 只生成空镜，文字后期叠 |
| 一条提示词塞太多 | 画面混乱/动作错 | 一镜一动作一运镜 |
| 额度/风控 | 生成失败、提示次数不足 | 先跑测试镜；失败重试间隔久一点 |
| 尺寸不统一 | 拼接时变形 | 先统一 scale+pad 再 concat |
| 授权弹窗 | 模拟点击被系统拦 | 需要用户手动点允许 |
| 豆包改版 | 按钮位置变 | 先读屏确认「AI 创作→视频生成」入口 |

## 五、目录约定
```
/sdcard/DSH Go/视频项目/
├── project.json      # 项目与分镜
├── 镜头1.mp4 …
├── concat.txt
└── 成片.mp4
```

## 六、配套
- 可选面板：安装 `dshgo-plugin/`（dsh-go 原生「视频工坊」），提供镜头列表、复制提示词、收最新视频、合成成片
- 提示词进阶：可搭配 `video-prompt-builder`、`seedance-2-prompt-copilot`、`storyboard-craft`、`shot-recipes`、`short-video` 技能

## 七、知识库（已吸收全部 54 个视频技能）

本技能内置一份完整知识库：`docs/knowledge/`（195 篇技能文档，约 25 万字，源自 DirectorX，Apache-2.0，已按本流程重新组织）。
查法：先看 `docs/knowledge/INDEX.md` 找篇名，再读对应 `SKILL.md`。

### 分门别类（按需查）
| 主题 | 代表篇目 |
|---|---|
| **提示词工程** | video-prompt-builder、seedance-2-prompt-copilot、seedance-2-5-prompt-copilot、kling/minimax/banana prompt-copilot、video-prompt-reverse |
| **分镜与镜头** | storyboard-craft、shot-recipes、cinematic-motion-language、directorx-blocking-craft、cinematic-title-sequence |
| **导演与流程** | directorx-chengpian、directorx-production-lead、directorx-methodology、directorx-playbook、directorx-recipes、directorx-workflow |
| **风格与美术** | cinematic-style、set-design、lighting-advanced、novel-art、directorx-director-style |
| **剪辑与节奏** | editing-workflow、motion-design、beat-sync-editor、frame-qa、vfx-compositing、trailer-craft |
| **音频** | ai-audio、audio-sound、directorx-audio-workflow、directorx-mv-workflow |
| **平台与增长** | platform-china、platform-specs、platform-growth、short-video、thumbnail-cover、caption-localization |
| **叙事与短剧** | script-writing、novel-outline/characters/script/storyboard、directorx-short-drama、directorx-series-craft |
| **拆片学习** | video-deconstruct、video-deconstruct、explain-how-it-made |
| **高级玩法** | continuous-video、3d-director-stage、anime-game-pv、directorx-ads-ecommerce、skill-creator、directorx-skill-capture |

### 从全部知识库提炼的核心规则（直接执行）
1. **一条提示词=一个镜头=一个主要动作+一个主要运镜**；多动作用多镜。
2. **提示词九要素**：画幅、主体与状态、环境、光线、镜头（景别/机位/运动/景深）、材质、风格、画质、负面。
3. **锁定连续性**：跨镜头固定「人设/服装/场景/光源方向/色温」，避免风格漂移。
4. **首尾帧定动作**：需要精确起止时给首帧和尾帧，中间交给插值；不要同时塞参考图。
5. **节奏**：短视频 3 秒内出钩子，4–8 秒一次变化（切镜/推拉/信息更新），结尾留 CTA 或回环。
6. **竖屏构图**：主体放中上 1/3，底部 20% 留给字幕与平台 UI；横屏保持视线空间。
7. **字幕**：一行 ≤14 字，单条 ≤2 行，停留 ≥1.2 秒，位置避开平台 UI 安全区。
8. **声音**：人声 -16 LUFS 左右，峰值 ≤-1.5 dBTP；BGM 比人声低 12–18 dB；转场处做 20–40ms 交叉淡化避免爆音。
9. **质检**：抽首/中/尾帧看穿帮与文字；检查黑帧、闪烁、畸形手指、错字；导出前统一分辨率/帧率/色彩空间。
11. **不把真人姓名写进提示词**：需要某种风格时用视觉特征描述（线条/配色/光影/质感），不要写「某某式」；知识库中的艺术家姓名仅作风格参考，非其作品、无关联、无背书。
10. **合规**：不直接生成受版权保护的角色/品牌；需要时走「属性化改写 + 负面词」，不把 IP 名字送进生成模型。

### 用法建议（省额度）
- 先查知识库定「镜头配方」→ 再用第 3 节模板写提示词 → 豆包跑 1 条验证风格 → 批量
- 拿不准的镜头，先 `grep -i "关键词" docs/knowledge -r` 找对应篇目


## 八、外部最佳实践（联网补充，含官方指南）
详见 `docs/网络最佳实践.md`。核心：
1. **官方进阶公式**：精准主体 + 动作细节 + 场景环境 + 光影色调 + 镜头运镜 + 视觉风格 + 画质 + 约束条件
2. **动作四原则**：肢体细化、低缓连续、写过渡、情绪外化（不写"很悲伤"）
3. **一镜一运镜**，多镜头用「镜头1/2/3」时序写，不硬卡秒数
4. **约束词必写**：无字幕、无 Logo、无水印、面部稳定不变形
5. **官方已知坑**：换脸（用大头照+全身照，别用三视图）、双胞胎（绑定参考图+禁令）、风格漂移（写死风格）、衔接跳变（删6帧/1帧）、片尾噪音（音量淡出）、多音字（换同音字）
6. **素材 4–5 个最佳**：角色1-2 + 场景1 + 运镜参考1 + 音频1，角色别超 4 人
7. **短视频钩子**：前 3 秒决定留存，4–8 秒一次变化，结尾 CTA/回环

## 版本
- v0.0.1（2026-11-16）首版：流程、提示词模板、FFmpeg 配方、质检清单、常见坑
