# Skill Gomoku / 技能五子棋

A modern same-device family Gomoku game for iPhone and iPad.

## Product Direction

- Native SwiftUI Universal App
- Same-device two-player play
- Local player names and avatars
- Classic Gomoku
- Standard Skill Gomoku
- Advanced Skill Gomoku
- No bot, networking, account, ads, or backend in V1

## Planning Documents

- [Product Requirements](docs/PRD.md)
- [Codex Kickoff Prompt](CODEX_KICKOFF_PROMPT.md)
- [GitHub Setup](GITHUB_SETUP.md)

## Reference Images

The files in `docs/reference/` are layout references only. Do not copy their visual assets or exact styling.

## Current Status

V1.1 visual and gameplay-clarity update:

- New abstract skill-seal App Icon and matching in-app brand mark
- Layered East Asian match atmosphere with ink mountains, water lines, wood grain, and accessible falling-leaf motion
- Explicit current-player, turn-count, and placement guidance in classic mode
- Independent always-visible skill decks for both players
- Rebuilt dark match setup with readable, category-colored skill cards
- Refined board, stones, last-move marker, player identity colors, and responsive layouts

The local App Store candidate includes:

- Native SwiftUI project scaffold
- Classic Gomoku engine
- Standard Skill Gomoku with five fixed skills
- Advanced Skill Gomoku with player-selected skill loadouts
- Local player profiles and avatars
- iPhone / iPad responsive match layout
- SwiftData persistence for players and unfinished matches
- Completed match records and local win/loss/draw stats
- In-match undo, placement preview, invalid-position feedback, sound, and haptics
- App Store metadata, privacy text, review notes, icons, and screenshot assets
