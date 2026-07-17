# CodexNotch 项目交接记忆

## 这是什么

CodexNotch 是一个独立、开源的原生 macOS SwiftUI/AppKit 应用；不依赖 Atoll。它围绕 MacBook 的物理刘海展示当前 ChatGPT/Codex 的周额度、运行中的任务以及最近完成的对话，并可点击回到对应 ChatGPT 任务。

## 当前位置与 Git

- 当前可工作的仓库：`/Users/david/projects/codex-notch`
- 个人远端：`https://github.com/fengdwx/codex-notch.git`，默认分支为 `main`
- 当前开发分支：`feat/codex-notch-v1`；此前按用户要求通过 `git push origin HEAD:main` 直接同步到远端 `main`。推送前先检查工作区，并仅在用户要求时推送。
- `/Users/david/projects/tmp/codex-notch` 是另一个 `main` 工作树；不要删除或混淆两个工作树。
- 用户希望每个有意义的改动单独提交；仓库必须推送到个人仓库，不要推组织仓库。

## 常用命令

```bash
swift test
./scripts/build_app.sh
open dist/CodexNotch.app
```

- `./scripts/build_app.sh` 会运行测试并构建 `dist/CodexNotch.app`。
- 最近一次完整验证：63 个测试通过。
- 改 UI 后应重新构建、重启该 `.app`，再让用户在真实刘海上确认；不要只凭截图声称动画正确。

## 运行与状态模型

- 当前 ChatGPT/Codex app 的 bundle identifier 是 `com.openai.codex`；`com.openai.chatgpt.classic` 是 Classic，不应当作当前目标。
- 额度来自本机 Codex/ChatGPT 登录态；绝不提交认证文件、access token 或任何 `~/.codex` 私密内容。
- 会话活动来自本机 rollout/session 日志。`ActiveSessionStore` 保留最近完成记录 24 小时。
- 有活动任务时一定显示运行态；没有活动任务但有最近完成记录时，紧凑刘海保持完成态和绿色对号；新任务开始后立即切回运行动画。

## 已确认的视觉与交互约束

- 额度始终显示在右侧刘海安全区，数字位于圆环/波浪球内部，不显示旁边的重复数字。
- 额度环缺口在 12 点方向，按顺时针表达进度；颜色从高额度绿色平滑过渡到低额度红色。
- 左右图标必须始终在各自安全区居中，不能下沉到刘海下方，也不能被物理摄像头切口遮住。
- 悬停展开必须从原有紧凑岛体向下展开，不能从物理刘海中间炸开、向上展开或出现窗口跳动。
- 展开实现刻意采用 Atoll 的分层思路：`NotchWindowController` 先一次性准备最终透明画布，SwiftUI 在画布内展开可见岛体。不要恢复旧版按帧调整 `NSPanel` 尺寸的做法；它既不顺滑，也曾在 SwiftUI 文本布局期间导致崩溃。
- 收起后应回收透明画布，避免在紧凑刘海外拦截鼠标。
- 运行态左侧为蓝色 ChatGPT 图形回声；完成态为一次绿色图形回声和清晰的绿色对号。减少动态效果时保留静态状态。
- 展开卡片展示周额度、精确重置时间和最近对话；“最近对话数”由设置控制（1–5）。设置窗口必须能自动置前。

## 用户协作偏好

- 用中文、简洁地先说明结果再说明做法；用户会直接给截图做像素级反馈。
- 不要擅自扩大为 Atoll 插件或引入 Atoll 依赖；这是用户自己的独立 app。
- 用户更重视真实机器上的观感、平滑和刘海几何，而不接受只靠参数猜测的改动。
- 遇到 UI 回归，先检查真实运行状态与对应状态机，而不是只改样式。
