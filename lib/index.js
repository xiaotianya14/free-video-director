// DSH skill plugin: 把 SKILL.md 注册成 free-video-director 技能
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const here = path.dirname(fileURLToPath(import.meta.url))
const root = path.resolve(here, '..')
const SKILL_MD = path.join(root, 'SKILL.md')

const CANDIDATE = {
  name: 'free-video-director',
  description:
    '用豆包 App 免费额度做短视频/宣传片的完整导演流程：分镜 → 结构化长提示词 → 模拟点击豆包生成 → 自动收片 → 本地 FFmpeg 剪辑字幕合成 → 质检交付。没有视频模型 API、只有手机和豆包免费版时用。',
}

function readSkill() {
  return fs.readFileSync(SKILL_MD, 'utf8')
}

const provider = {
  name: 'free-video-director',
  async list() {
    return [
      {
        name: CANDIDATE.name,
        description: CANDIDATE.description,
        rank: 0,
      },
    ]
  },
  async get(entry) {
    return {
      content: readSkill(),
      resources: [],
      resourceBase: { path: root + path.sep },
    }
  },
}

export function apply(ctx) {
  ctx.skills.registerProvider(() => provider)
}
