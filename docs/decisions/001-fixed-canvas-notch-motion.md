---
status: active
contract_ids: [NOTCH-MOTION-002]
supersedes: []
superseded_by: null
owner: project-maintainer
created_at: 2026-07-17
last_verified_commit: 0d37196
---

# 固定画布，内部岛体展开

## 背景

早期版本通过定时器和 AppKit 动画持续调整 `NSPanel` 的 frame。该方案在 SwiftUI 文本布局时会产生重入布局崩溃，并且视觉上像窗口从物理刘海中间炸开，和 Atoll 的分层体验不一致。

## 决策

展开前由 `NotchWindowController.prepare` 一次性分配最终透明画布；随后由 `NotchView` 和 `NotchPresentationMotion` 在画布内动画可见岛体。收起后 `settleFrame` 延迟回收多余透明画布，避免拦截紧凑刘海外的鼠标。

## 被拒绝的方案

- **逐帧设置 panel frame**：会与 SwiftUI 布局竞争，曾导致崩溃和闪烁。
- **只用 AppKit 缩放整个窗口**：不会崩溃，但视觉仍是窗口在动，而不是岛体自然向下展开。

## 后果与验证

- 任何后续动画调整都不得恢复计时器驱动的 `NSPanel.setFrame` 循环。
- 自动层面运行 `NotchGeometryTests`；真实物理刘海上仍需验证悬停展开、收起和鼠标命中区域。
