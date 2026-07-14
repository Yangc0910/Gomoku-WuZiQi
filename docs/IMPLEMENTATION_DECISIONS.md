# Implementation Decisions

## 工程结构

- 本轮建立原生 SwiftUI Universal App 结构，Product Name 使用 `SkillGomoku`。
- 规则引擎位于 `SkillGomoku/Core/GameEngine`，不依赖 SwiftUI、SwiftData、PhotosUI 或页面 ViewModel。
- 技能相关类型先保留 `GameMode`、`SkillIdentifier`、`SkillState`、`RandomSource` 和可编码状态字段，但不实现九项技能效果。

## 状态管理

- 对局页面使用 `MatchViewModel` 接收 UI 动作，再交给 `RuleEngine` 校验并产生新 `GameState`。
- View 只发送 `GameAction` 对应的意图，不直接修改棋盘数组。

## SwiftData 边界

- SwiftData 模型只用于本地存储：玩家档案、未完成对局和对战记录。
- 未完成对局保存为编码后的 `GameState` JSON Data，通过 `MatchRepository` 转换，避免 SwiftData 模型成为核心规则对象。

## 响应式布局

- iPad / 宽屏采用三列布局：玩家一、棋盘、玩家二。
- iPhone / 窄屏采用固定上下玩家摘要卡，中间棋盘和动作区，不随回合交换位置。
- 当前玩家使用主题色边框与饱和度突出，非当前玩家降低饱和度与透明度。

## 头像本地保存

- PhotosPicker 和相机入口得到的图片会处理为正方形 JPEG 缩略图，保存到 Application Support 的 `Avatars` 目录。
- SwiftData 只保存本地文件名，不保存系统相册引用，也不上传任何服务。
- 当前 Windows 环境无法实际验证相机硬件行为，已通过协议和 `UIImagePickerController` fallback 保持可替换。

## 自动保存

- 每次成功落子后保存未完成对局。
- App 进入非 active 场景时再次保存当前 `GameState`。
- 首页在存在未完成对局时显示“继续上次对局”。
- 对局完成后会将未完成对局标记为结束，写入 `MatchRecordEntity`，并更新双方玩家的胜负平统计。

## 对局交互

- 当前运行中的经典对局支持撤销上一步；撤销只基于本次运行内的 `GameState` 历史快照。
- 对局已经结束后不允许撤销或继续落子，避免改变已记录结果。
- 棋盘支持按下/拖动时显示即将落子的预览点；点击已占位置会显示短暂非法反馈。

## 当前环境限制

- 当前执行环境是 Windows，没有 macOS 和 Xcode，无法运行 iOS 构建、模拟器、XCTest 或相机/照片系统 UI 验证。
- `.xcodeproj` 采用手工维护的标准工程文件，后续建议在 Mac Xcode 中打开并让 Xcode 进行一次工程格式确认。

## 临时取舍

- 长按放大落子预览未在本轮实现；当前先实现点击吸附最近交叉点、按下预览、非法落点反馈和最后一步标识。
- 结算页先作为结果 sheet 展示，Phase 2/打磨阶段可扩展为完整结算流程、再来一局和换模式入口。
