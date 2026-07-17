---
status: active
owner: project-maintainer
created_at: 2026-07-17
last_verified_commit: 0d37196
---

# CodexNotch Agent 变更 Harness

## 目标与采用级别

CodexNotch 采用“轻量模式 + 可执行验收”。它是持续维护的原生 macOS 应用，但当前没有线上服务、数据库迁移或 CI required check。Harness 的目标是防止每次修复刘海视觉或状态机时覆盖已确认的用户体验、隐私边界和打包行为。

完成不等于“代码能编译”。完成必须同时证明：本次要求已发生、保持项未回归、历史错误有 guard、以及未执行的真实硬件验证被明确标出。

## 权威顺序

当前行为发生冲突时，按以下顺序处理：

1. `docs/contracts/behavior-contracts.yaml` 中 `active` 的契约；
2. `docs/decisions/` 中 `active` 的决策；
3. 可执行测试、fixture 和验证脚本；
4. 当前代码与配置；
5. README、已完成 plans、聊天记录和 agent 记忆。

测试与契约冲突时，不要直接删测试或改测试来适配实现；先明确哪条契约被替换，并在契约中记录 `supersedes`。

## 每次变更前

所有 L1 及以上变更都先写出以下内容（可以放在当轮说明、计划或提交说明中）：

| 项目 | 要求 |
|---|---|
| 改变 | 本次要改变的可观察结果 |
| 保持 | 关联但不能回归的契约 ID |
| 不做 | 未授权的重构、视觉重做、数据清理、发布或权限变化 |
| 风险 | L0 / L1 / L2 / L3 |
| 验收 | 自动 guard、完整检查与必要的真实硬件检查 |

风险按影响而非改动行数判断：

- **L0**：文档、注释、不改变行为的整理；复核 diff 即可。
- **L1**：局部实现或低风险 bug；运行聚焦测试和 `swift test`。
- **L2**：用户可见 UI、额度语义、会话状态、设置、打包；新增或定位正反 guard，运行 `./scripts/verify.sh`，并在物理刘海上检查受影响状态。
- **L3**：认证、隐私、令牌处理、外部接口权限、正式公开发布；完整检查外还需人工审阅与明确回退路径。当前项目没有自动部署，不能把“本地打包”说成已发布。

## 实现和回归规则

1. 编辑前先检查工作树，保留无关用户修改。
2. 对可复现 bug，先让测试或 fixture 在修复前失败；不能自动复现时，记录最小手工复现步骤与替代验收方式。
3. 修改最小完整行为，不顺手改变相邻交互或架构。
4. 修复过的 bug 必须保留结果导向的回归 guard；不要只断言内部调用。
5. UI 变更必须考虑紧凑、展开、运行、完成、无额度、无刘海 fallback 和 Reduce Motion 状态。
6. 绝不提交 `CODEX_HOME/auth.json`、Authorization header、access token、完整 usage 响应或用户消息正文。
7. 每个有意义的改动单独提交；仅在用户明确要求时推送到个人 GitHub 仓库。

## 验证入口

| 层级 | 命令 | 适用范围 |
|---|---|---|
| contracts | `./scripts/check_contracts.sh` | 校验行为契约 YAML 的结构和必填字段 |
| fast | `swift test` | 所有代码改动的快速确定性检查 |
| full | `./scripts/verify.sh` | L2/L3：测试、release 构建、app bundle 与签名验证 |
| release | `./scripts/release.sh` | 需要生成可分发 zip 时；仅生成本地工件，不会上传发布 |

`full` 默认不发送通知、不请求真实任务操作，也不改变远端状态。只有本机打包目录 `dist/` 会更新，且该目录被 Git 忽略。

## 真实硬件验收

自动测试不能替代真实刘海视觉检查。触及以下契约时，完成报告必须写明已检查或待用户检查：

- 左右图标是否在刘海安全区居中；
- 是否被摄像头切口遮挡或落到刘海下方；
- 悬停是否从紧凑岛体只向下展开、收起后是否还拦截鼠标；
- 运行动画、完成对号、额度环/波浪球和 Reduce Motion 是否清晰可辨。

不要用静态截图证明动画正确；需说明观察的状态与触发方式。

## 文档生命周期

- 新行为或重要 bug 修复：更新相应行为契约，并将真实错误转为测试或 fixture。
- 关键实现选择：在 `docs/decisions/` 新建带 `status`、契约 ID 和替代方案的决策记录。
- 旧计划仅供历史参考；没有 `active` 状态的 plan 不能单独解释当前行为。
- 契约被替换时保留旧条目、标记 `superseded` 并填写替代 ID。

## 本项目适配表

| 项目问题 | 当前答案 |
|---|---|
| 关键用户与入口 | 已登录 ChatGPT/Codex 的有刘海 Mac 用户；紧凑刘海、悬停展开、设置和菜单栏 fallback |
| 最不能回归 | 物理刘海几何、只向下展开、活动/完成状态优先级、周额度语义、隐私边界、可运行 release app |
| 高频热点 | `NotchView`、`NotchRuntimeCoordinator`、`NotchWindowController`、`NotchPresentationReducer`、额度解析 |
| 当前契约 | `docs/contracts/behavior-contracts.yaml` |
| L3 | 认证/令牌处理、隐私数据、usage 接口权限、正式对外发布 |
| CI required check | 未配置；不得声称 CI 已兜底 |
| 部署目标 | none；release 是本地可分发压缩包，不是自动发布 |
| 未采用的模板章节 | CI required check、线上部署证明、canary、数据迁移：当前项目没有对应运行环境或数据层 |
