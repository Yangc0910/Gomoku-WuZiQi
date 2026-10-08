# ASO 营销素材 · 2026-10-08

本次只更新营销内容，不创建 App 新版本，不修改游戏代码。

## 执行状态

- 2.2 (12) 已上线，名称保留「技能五子棋·棋逢对手」。
- 简体中文推广文本已在 App Store Connect 保存。
- `header-zh-Hans.png`：3840 × 1646、21:9、RGB PNG，产品页顶部 Banner。
- `search-zh-Hans.png`：1920 × 1280、3:2、RGB PNG，搜索结果创意图，含真实 XCTest 游戏画面。
- 上述两张图片已独立提交，2026-10-08 状态为「等待审核」。提交 ID：`ec960613-17f4-4cde-8b4a-9cc458467af7`。
- 审核通过不等于已展示：通过后，在上线的 2.2 产品页「标题和搜索结果」分别选取两张已获批素材并发布即可，无需提交新版本。
- 副标题、81 字关键词和新版描述仅为优化草稿，位于 `AppStoreSubmission/metadata.zh-Hans.md`；当前版本锁定，不宣称已生效。

## 设计与营销方向

使用 frontend-design 指导信息层级与品牌一致性，imagegen 生成品牌概念视觉；搜索图保留真实游戏界面。统一墨黑、玉绿、米白和克制金色，标题短而易读。不使用假奖项、排名、联机或当前不存在的玩法承诺。

Banner 主句「五子棋，玩出新策略」降低理解门槛，技能组合是差异点，离线人机与本机双人是使用场景。搜索图「不只落子，还能出招」与技能结算画面对应。保留现有六张真实界面截图，不替换为概念图。

`key-art-source.png` 是内置 imagegen 生成的品牌插画，不是游戏内截图。排版由 `scripts/generate_aso_assets.py` 可重复生成。

### 生成提示词

Use case: ads-marketing. Create a premium App Store creative asset illustration for an actual offline Chinese skill Gomoku game called 技能五子棋·棋逢对手. Brand palette: ink black #050D0F, jade green #5BE1B6, ivory #F7F5EE, restrained brushed gold #FFB85A. Wide landscape 21:9 composition. Right half focal point: a beautifully crafted square wooden 15x15 Gomoku board in subtle perspective, with several round ivory and jade circular stones placed at intersections, simple plausible mid-game pattern. One jade stone has a delicate luminous protective ring and one flowing gold wind trail suggesting skills moving or protecting stones. Quiet, realistic polished 3D game-key-art aesthetic, refined tactile wood and ceramic, restrained bloom, editorial lighting, professional store artwork. Left half is mostly clean dark ink negative space for later Chinese typography, absolutely no writing or letters anywhere. The board and stones must stay in central-right safe area with comfortable margins, no chopped board. No characters, no smartphones, no fake UI, no unrelated fantasy props, no dice/cards/chess pieces, no logos, no awards, no price, no buttons. Full bleed opaque background, no transparency.

## 效果衡量

未获得关键词搜索量或转化基线，因此这是相关性与转化假设，不是下载增长保证。素材发布后，按相同地区、来源、时间窗口比较前后至少 14 天的搜索曝光、产品页访问、首次下载与转化率；同时记录 2.2 更新和其他推广的影响。新创意展示位面向 iOS / iPadOS 27 及以上，旧系统继续看到原有截图。

## Apple 官方依据

- [产品页与关键词规则](https://developer.apple.com/app-store/product-page/)
- [素材与设计最佳实践](https://developer.apple.com/app-store/asset-best-practices/)
- [创意素材规格](https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications)
- [独立审核及上线版本直接更新创意素材](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-your-app-store-assets)
