// dsh-go 原生插件：视频工坊 —— 分镜/提示词/收片/合成（免费：豆包 App + 本地 FFmpeg）
import fs from 'node:fs'
import path from 'node:path'
import { spawnSync } from 'node:child_process'

export const name = 'local-video-studio'
const DIR = '/sdcard/DSH Go/视频项目'
const PROJECT = path.join(DIR, 'project.json')
const MOVIES = '/sdcard/Movies'

let mode = 'list'
let cur = 0

function load() {
  try { return JSON.parse(fs.readFileSync(PROJECT, 'utf8')) } catch { return null }
}
function save(p) { fs.mkdirSync(DIR, { recursive: true }); fs.writeFileSync(PROJECT, JSON.stringify(p, null, 2)) }
function shuffleFile(shot, project) {
  if (!shot.file) return null
  const f = path.join(DIR, shot.file)
  return fs.existsSync(f) ? f : null
}
function latestMovie() {
  try {
    const files = fs.readdirSync(MOVIES).filter((f) => f.toLowerCase().endsWith('.mp4'))
      .map((f) => path.join(MOVIES, f)).map((p) => ({ p, t: fs.statSync(p).mtimeMs }))
      .sort((a, b) => b.t - a.t)
    return files[0] ? files[0].p : null
  } catch { return null }
}

function listView(project) {
  const shots = project ? project.shots || [] : []
  const items = shots.map((s, i) => ({
    title: `${i + 1}. ${s.title}${s.status === 'done' ? ' ✅' : ''}`,
    subtitle: (s.prompt || '').replace(/\s+/g, ' ').slice(0, 60) || '（还没写提示词）',
    icon: 'skill',
    action: { id: 'shot', args: { i } },
  }))
  return {
    v: 2, type: 'stack', title: '视频工坊',
    children: [
      { type: 'text', text: project ? `项目「${project.title}」 · ${shots.length} 个镜头` : '还没有项目：先让我在聊天里写分镜和提示词，或点「新建项目」', tone: 'muted' },
      ...(items.length ? [{ type: 'list', items }] : []),
      { type: 'actions', items: [
        { label: '新建项目', action: 'new' },
        { label: '收最新视频', action: 'collect' },
        { label: '合成成片', action: 'compose', style: 'primary' },
      ]},
      { type: 'text', text: `目录：${DIR}`, tone: 'muted' },
    ],
  }
}

function shotView(project) {
  const shots = project ? project.shots || [] : []
  const s = shots[cur]
  if (!s) return listView(project)
  return {
    v: 2, type: 'stack', title: `镜头 ${cur + 1}`,
    children: [
      { type: 'text', text: s.title, style: { size: 'title', weight: 'bold' } },
      { type: 'text', text: s.prompt || '（没有提示词）' },
      { type: 'text', text: s.status === 'done' ? `已收片：${s.file}` : '状态：未收片', tone: 'muted' },
      { type: 'actions', items: [
        { label: '复制提示词', action: 'copyPrompt', style: 'primary' },
        { label: '收最新视频', action: 'collectHere' },
        { label: '返回列表', action: 'back' },
      ]},
    ],
  }
}

function compose(project) {
  const shots = (project?.shots || []).map((s) => shuffleFile(s, project)).filter(Boolean)
  if (shots.length === 0) return { toast: '还没有已收片的镜头', refresh: true }
  const listFile = path.join(DIR, 'concat.txt')
  fs.writeFileSync(listFile, shots.map((f) => `file '${f.replace(/'/g, "'\\''")}'`).join('\n') + '\n')
  const out = path.join(DIR, '成片.mp4')
  const r = spawnSync('ffmpeg', ['-y', '-f', 'concat', '-safe', '0', '-i', listFile, '-c:v', 'libx264', '-crf', '20', '-pix_fmt', 'yuv420p', '-c:a', 'aac', '-shortest', out], { timeout: 600000, encoding: 'utf8' })
  if (r.status !== 0) return { toast: `合成失败：${(r.stderr || '').slice(-80)}`, refresh: true }
  return { toast: `成片已生成：${out}`, refresh: true }
}

export function apply(ctx) {
  ctx.inject(['dshGo'], (ctx) => {
    ctx.dshGo.on('video-studio', () => ({ open: 'panel:video-studio-panel' }))
    ctx.dshGo.panel('video-studio-panel', {
      view: () => {
        const p = load()
        return mode === 'shot' ? shotView(p) : listView(p)
      },
      data: (scope, emit) => { emit({}); return () => {} },
      actions: {
        shot: (scope, e) => { cur = Number(e?.value?.i ?? 0); mode = 'shot'; return { refresh: true } },
        back: () => { mode = 'list'; return { refresh: true } },
        new: () => { save({ title: '新项目 ' + new Date().toLocaleDateString('zh-CN'), shots: [] }); mode = 'list'; return { toast: '已新建项目，让我写分镜吧', refresh: true } },
        copyPrompt: () => {
          const p = load(); const s = p?.shots?.[cur]
          if (!s?.prompt) return { toast: '这个镜头还没提示词', refresh: true }
          return { copy: s.prompt, toast: '提示词已复制，去豆包粘贴' }
        },
        collect: () => {
          const p = load(); if (!p) return { toast: '先新建项目', refresh: true }
          const f = latestMovie(); if (!f) return { toast: '/sdcard/Movies 里没有视频', refresh: true }
          p.shots = p.shots || []
          const idx = p.shots.findIndex((s) => s.status !== 'done')
          const target = idx >= 0 ? idx : p.shots.length
          if (target >= p.shots.length) p.shots.push({ title: `镜头 ${target + 1}`, prompt: '', status: 'todo' })
          const name = `镜头${target + 1}.mp4`
          fs.copyFileSync(f, path.join(DIR, name))
          p.shots[target].file = name; p.shots[target].status = 'done'
          save(p)
          return { toast: `已收：${name}`, refresh: true }
        },
        collectHere: () => {
          const p = load(); if (!p?.shots?.[cur]) return { refresh: true }
          const f = latestMovie(); if (!f) return { toast: '/sdcard/Movies 里没有视频', refresh: true }
          const name = `镜头${cur + 1}.mp4`
          fs.copyFileSync(f, path.join(DIR, name))
          p.shots[cur].file = name; p.shots[cur].status = 'done'
          save(p)
          return { toast: `已收：${name}`, refresh: true }
        },
        compose: () => compose(load()),
      },
    })
  })
}
