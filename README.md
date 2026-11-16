# free-video-director · 免费视频导演

用 **豆包 App 等免费额度** + 本地 FFmpeg，做出能发布的产品短片。零 API 费用。

> 分镜 → 结构化长提示词 → 豆包模拟点击生成 → 自动收片 → 本地剪辑/字幕/BGM/合成 → 质检交付

## 为什么做这个
视频模型 API 很贵，但豆包免费版每条能出 ~10 秒画面。真正的问题不是"生成"，而是：
- 提示词太短 → 画面简陋
- AI 写中文字会错 → 不能直接当标题
- 缺后期 → 一堆片段拼不成片

这个项目把「导演方法 + 豆包免费生成 + 本地后期」串成一条可复用流程。

## 安装

### 方式 1：作为 DSH 技能插件（市场/仓库）
```sh
dsh plugin --profile web add github:xiaotianya14/free-video-director
```

### 方式 2：手动放技能目录
把 `SKILL.md` 放到 `~/.dsh/skills/free-video-director/SKILL.md`

### 方式 3：装原生面板（可选，dsh-go App）
```sh
dsh plugin --profile web add ./dshgo-plugin
```

## 下载后先校验（两件套：包 + 校验文件）

发布时提供 **`free-video-director-v0.0.1.zip`** 和 **`.sha256`** 两个文件（外加 `SHA256SUMS`）：

```bash
sha256sum -c free-video-director-v0.0.1.zip.sha256
# 或
bash scripts/verify_release.sh free-video-director-v0.0.1.zip
```
校验通过再解压；校验失败说明下载不完整或被篡改，请重新下载。

## 环境自检（装之前先跑）
```bash
bash scripts/env_check.sh      # 检测：装没装/版本/能不能跑
bash scripts/env_install.sh    # 只装缺的，装完复检+冒烟
bash scripts/smoke_test.sh     # 2D 与 3D 各出一次图，证明真能用
```
清单见 `assets/tool-manifest.json`；包里不含二进制，Blender 缺失时按清单自动安装，装完必须冒烟通过。

## 快速开始
1. 打开豆包 → AI 创作 → 视频生成
2. 用 `SKILL.md` 里的提示词模板写一条（示例见 `docs/示例提示词.md`）
3. 生成完保存 → 视频在 `/sdcard/Movies/`
4. 按 SKILL 的 FFmpeg 配方拼接、加字幕、出成片

## 目录
```
SKILL.md          # 核心：流程、模板、配方、坑
docs/示例提示词.md # 可直接抄的提示词
lib/index.js      # DSH 插件入口（注册技能）
dshgo-plugin/     # 可选：dsh-go 原生「视频工坊」面板
```

## 知识库

内置 **54 个视频技能、195 篇文档（约 25 万字）**，源自 DirectorX（Apache-2.0）并重新组织：

- 索引：`docs/knowledge/INDEX.md`
- 外部最佳实践（官方提示词指南吸收）：`docs/网络最佳实践.md`
- 覆盖：提示词工程、分镜镜头、导演流程、风格美术、剪辑节奏、音频、平台规格、叙事短剧、拆片学习

## 版本
- v0.0.1

## 来源与致谢

本项目的知识库（`docs/knowledge/`，54 个技能 / 195 篇文档）来自开源项目：

- **DirectorX** — https://github.com/LaplaceYoung/dsh-directorx
- 许可证：Apache License 2.0（见 `LICENSE-APACHE-2.0.txt`）
- 原文未修改，仅新增索引与分类；版权归原作者所有
- 本项目与 DirectorX 无隶属关系，不使用其名称或 Logo 作背书

如果你复刻/再分发本项目：
- 在本仓库内：GitHub 会自动显示「Forked from xiaotianya14/free-video-director」
- 复制到别处：请保留 `LICENSE`、`NOTICE` 与 `LICENSE-APACHE-2.0.txt` 及来源链接
- 修改过内容：请在显著位置说明改动

## 商标与免责声明

- 本项目是**独立开源项目**，与字节跳动（豆包）、DirectorX 项目及其作者、以及任何生成模型厂商**均无隶属或合作关系**
- 文中出现的第三方名称（豆包/Doubao、Seedance、即梦、Kling、MiniMax、Sora、Netflix、Claude 等）均为其各自所有者的商标或名称，仅用于说明
- 本项目不宣称这些第三方对本项目有任何背书

## 许可
- 本项目原创代码与文档：**MIT**（见 LICENSE）
- `docs/knowledge/` 知识库：**Apache-2.0**，来自 DirectorX（见 NOTICE 与 LICENSE-APACHE-2.0.txt）

本项目与 DirectorX 无隶属关系，未使用其商标或名义背书。
