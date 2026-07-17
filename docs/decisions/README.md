# CodexNotch 架构决策

仅将会影响有效行为契约、可能被未来 agent 误改，或记录过历史错误边界的选择写入本目录。

| 决策 | 状态 | 关联契约 | 说明 |
|---|---|---|---|
| [001-fixed-canvas-notch-motion](001-fixed-canvas-notch-motion.md) | active | `NOTCH-MOTION-002` | 固定 NSPanel 画布，内部 SwiftUI 岛体展开 |

新决策必须带有 `status`、`contract_ids`、替代方案和后果。决策改变时保留旧文档，并用 `superseded_by` 指向新文档。
