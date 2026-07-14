# Implementation Decisions

## 工程结构

- 本轮建立原生 SwiftUI Universal App 结构，Product Name 使用 `SkillGomoku`。
- 规则引擎位于 `SkillGomoku/Core/GameEngine`，不依赖 SwiftUI、SwiftData、PhotosUI 或页面 ViewModel。
- 技能相关类型由核心层统一维护：`GameMode`、`SkillIdentifier`、`SkillState`、`RandomSource` 和可编码 `GameState` 字段共同支持经典、标准技能和高阶技能模式。

## 状态管理

- 对局页面使用 `MatchViewModel` 接收 UI 动作，再交给 `RuleEngine` 校验并产生新 `GameState`。
- View 只发送 `GameAction` 对应的意图，不直接修改棋盘数组。
- 技能动作与落子一样进入 `RuleEngine`，并写入同一套历史快照、自动保存和结算流程。

## SwiftData 边界

- SwiftData 模型只用于本地存储：玩家档案、未完成对局和对战记录。
- 未完成对局保存为编码后的 `GameState` JSON Data，通过 `MatchRepository` 转换，避免 SwiftData 模型成为核心规则对象。
- 技能冷却、已移除棋子、禁手点和保护状态都会随 `GameState` 一起保存，恢复对局后继续生效。

## 响应式布局

- iPad / 宽屏采用三列布局：玩家一、棋盘、玩家二。
- iPhone / 窄屏采用固定上下玩家摘要卡，中间棋盘和动作区，不随回合交换位置。
- 当前玩家使用主题色边框与饱和度突出，非当前玩家降低饱和度与透明度。

## 头像本地保存

- PhotosPicker 和相机入口得到的图片会处理为正方形 JPEG 缩略图，保存到 Application Support 的 `Avatars` 目录。
- SwiftData 只保存本地文件名，不保存系统相册引用，也不上传任何服务。
- 相机入口使用 `UIImagePickerController` fallback；无相机设备和模拟器会显示不可用提示，避免请求不存在的硬件能力。

## 自动保存

- 每次成功落子后保存未完成对局。
- 每次成功使用技能后保存未完成对局。
- App 进入非 active 场景时再次保存当前 `GameState`。
- 首页在存在未完成对局时显示“继续上次对局”。
- 对局完成后会将未完成对局标记为结束，写入 `MatchRecordEntity`，并更新双方玩家的胜负平统计。

## 对局交互

- 当前运行中的对局支持撤销上一步；落子和技能都会作为一步进入本次运行内的 `GameState` 历史快照。
- 对局已经结束后不允许撤销或继续落子，避免改变已记录结果。
- 棋盘支持按下/拖动时显示即将落子的预览点；点击已占位置会显示短暂非法反馈。
- 技能选择后棋盘会高亮合法目标；无需选择目标的全局技能会先展示确认弹层，防止误触。
- 音效和触感反馈由设置开关控制，只在本机播放，不涉及网络或数据采集。

## 技能规则

- 标准技能模式固定启用：飞沙走石、拾金不昧、保洁上门、两极反转、力拔山兮。
- 高阶技能模式允许开局选择三项技能，可选池包含九项技能。
- 飞沙走石、保洁上门和拾金不昧会通过已移除棋子池完成移除与恢复，保证自动保存和恢复后状态一致。
- 移形换位只允许移动己方棋子到相邻空点；画地为牢只限制目标玩家下一次完成回合前的对应落点；金钟罩保护己方棋子并随对手回合递减。
- 具备随机效果的技能使用可编码随机种子，便于测试和保存恢复。

## 当前环境限制

- 工程验证以 macOS + Xcode 的 `xcodebuild`、iPhone/iPad Simulator 和 XCTest 结果为准。
- 真机相机与 App Store Connect 上传仍依赖本机 Apple Developer 账号、签名证书、Provisioning Profile 和人工 2FA。

## 临时取舍

- 长按放大落子预览未在本轮实现；当前先实现点击吸附最近交叉点、按下预览、非法落点反馈和最后一步标识。
- 结算页先作为结果 sheet 展示；后续可扩展为更完整的再来一局、换模式和分享入口。
