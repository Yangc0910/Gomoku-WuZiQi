# GitHub Repository Setup

## 1. 新建仓库

建议设置：

- Repository name：`skill-gomoku-ios`
- Description：`A modern same-device family Gomoku game for iPhone and iPad with classic and skill-based modes.`
- Visibility：**Private**
- Initialize repository：
  - Add a README：是
  - Add `.gitignore`：选择 **Swift**
  - License：暂时不添加

工程还没有公开发布计划时，Private 最合适。以后需要公开时再决定开源协议。

## 2. 为什么使用英文仓库名

App 展示名称可以是“技能五子棋”，但仓库、Xcode scheme、目录和代码类型建议使用：

- `SkillGomoku`
- `skill-gomoku-ios`

这样能减少路径、自动化、脚本和编码问题，也方便未来增加英文商店页面。

## 3. Clone 到本地

对不想频繁使用命令行的工作流，推荐 GitHub Desktop：

1. 在 GitHub Desktop 登录账号。
2. 选择 `File > Clone repository`。
3. 选择 `skill-gomoku-ios`。
4. 本地路径不要放在临时下载目录。
5. 如果使用两台电脑和 OneDrive：
   - Git 仓库本身最好放在每台电脑的普通本地开发目录；
   - 通过 GitHub 同步代码；
   - 不要依赖 OneDrive 同时同步 `.git`、Xcode workspace 和 build 中间文件。
6. 每台电脑分别 clone 同一个 GitHub 仓库。

推荐路径示例：

```text
~/Developer/skill-gomoku-ios
```

Windows 侧管理文件时可以使用：

```text
C:\Users\<name>\Developer\skill-gomoku-ios
```

实际 iOS 编译仍需要 macOS 和 Xcode。

## 4. 将本规划包放入仓库

仓库初始结构建议：

```text
skill-gomoku-ios/
├── README.md
├── CODEX_KICKOFF_PROMPT.md
├── GITHUB_SETUP.md
├── .gitignore
└── docs/
    ├── PRD.md
    └── reference/
        ├── skill-cards-a.png
        ├── skill-cards-b.png
        └── web-layout-reference.png
```

第一次提交建议：

```text
docs: add product requirements and Codex kickoff plan
```

## 5. Xcode 工程设置

创建工程时建议：

- Product Name：`SkillGomoku`
- Interface：SwiftUI
- Language：Swift
- Include Tests：是
- Storage：SwiftData
- Organization Identifier：使用你长期控制的反向域名

示例：

```text
com.chengyang
```

对应 Bundle Identifier：

```text
com.chengyang.SkillGomoku
```

Bundle ID 一旦用于签名和发布，不要随意修改。正式创建前确认该标识属于你，并在 Apple Developer 账号中可用。

## 6. 分支策略

个人项目不需要复杂 Git Flow。

推荐：

- `main`：始终保持相对稳定
- `codex/<task-name>`：Codex 开发分支
- `feature/<task-name>`：自己开发的功能分支
- `fix/<task-name>`：修复分支

示例：

```text
codex/phase-0-1-foundation
codex/phase-2-standard-skills
codex/phase-3-advanced-skills
feature/avatar-editor
fix/cooldown-counter
```

Codex 不应直接把大规模改动推到 `main`。每个阶段形成一个 Pull Request，检查后再合并。

## 7. Pull Request 与合并设置

仓库 Settings 中建议：

- 默认分支：`main`
- 允许 Squash merging
- 可以关闭不需要的 merge commit
- 合并后自动删除 head branch
- 开启 Issues
- Wiki 可关闭
- Projects 可暂时关闭或按需要开启

如果你的 GitHub 计划和仓库设置支持 branch rules：

- 禁止删除 `main`
- 禁止 force push 到 `main`
- 要求通过 Pull Request 合并
- 个人项目可以不要求他人 approval
- 后续有 CI 时再要求测试通过

不要一开始设置过多强制规则，避免 Codex 或自己无法完成首次提交。

## 8. 推荐的开发 PR 顺序

### PR 1

```text
feat: build native app foundation and classic gomoku mode
```

内容：

- 工程基础
- 玩家档案
- 经典模式
- iPhone / iPad 布局
- 单元测试

### PR 2

```text
feat: add standard skill gomoku mode
```

内容：

- 技能框架
- 五项标准技能
- 冷却和被移除棋子池
- 技能 UI

### PR 3

```text
feat: add advanced skill loadouts
```

内容：

- 技能选择
- 四项高阶技能
- 状态效果
- 组合测试

### PR 4

```text
feat: polish game experience for family testing
```

内容：

- 动画
- 音效
- 触觉
- 可访问性
- TestFlight 修复

## 9. Issues 建议

可以先建立这些 Issues：

1. `Build universal SwiftUI project foundation`
2. `Implement classic Gomoku game engine`
3. `Create local player profiles and avatars`
4. `Build responsive iPad match layout`
5. `Build compact iPhone match layout`
6. `Implement standard skill framework`
7. `Implement advanced skill loadouts`
8. `Add match persistence and resume`
9. `Add accessibility and reduced motion`
10. `Prepare TestFlight build`

Issues 不是必须，但能帮助 Codex 每次专注一个范围。

## 10. 不要提交到 GitHub 的内容

- `DerivedData`
- `xcuserdata`
- 本地 signing certificate
- provisioning profiles
- API keys
- Apple 登录凭据
- 个人照片测试数据
- 大型构建产物
- `.DS_Store`

本项目 V1 不需要任何 repository secret。

## 11. Codex 启动方式

把仓库连接给 Codex 后，将 `CODEX_KICKOFF_PROMPT.md` 的全文作为第一次开发任务。

第一次不要要求 Codex 同时实现全部技能。先确认：

- 工程能打开
- 经典模式能运行
- 玩家档案能保存
- iPad / iPhone 布局方向正确
- 游戏引擎测试可靠

基础稳定后，再让 Codex执行 Phase 2 和 Phase 3。
