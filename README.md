# Skill Gomoku / 技能五子棋

A modern offline Gomoku game for iPhone and iPad, with local two-player and computer-opponent play.

## Product Direction

- Native SwiftUI Universal App
- Same-device two-player play
- Offline single-player AI with three difficulty levels across classic, standard-skill, and advanced-skill rules
- Local player names and avatars
- Classic Gomoku
- Standard Skill Gomoku
- Advanced Skill Gomoku
- No networking, account, ads, or backend

## Planning Documents

- [Product Requirements](docs/PRD.md)
- [Codex Kickoff Prompt](CODEX_KICKOFF_PROMPT.md)
- [GitHub Setup](GITHUB_SETUP.md)
- [2.0 AI Mode Design](docs/V2_AI_MODE.md)

## Reference Images

The files in `docs/reference/` are layout references only. Do not copy their visual assets or exact styling.

## Current Status

Version 2.0 builds on the V1.1 visual and gameplay-clarity update:

- New abstract skill-seal App Icon and matching in-app brand mark
- Layered East Asian match atmosphere with ink mountains, water lines, wood grain, and accessible falling-leaf motion
- Explicit current-player, turn-count, and placement guidance in classic mode
- Independent always-visible skill decks for both players
- Rebuilt dark match setup with readable, category-colored skill cards
- Refined board, stones, last-move marker, player identity colors, and responsive layouts

The current app includes:

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
- Opponent-first mode navigation: Offline AI or Local Two Player, followed by a rule set
- Offline computer opponent with easy, medium, and hard difficulty
- Skill-capable AI that can choose legal skill actions and targets in standard and advanced modes
- Human first/second-player selection and automatic AI turns
- Saved/resumable single-player matches and human-only profile statistics
