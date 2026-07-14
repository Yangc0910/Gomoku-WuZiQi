import SwiftUI

struct PlayerPanel: View {
    let player: PlayerProfileEntity
    let side: PlayerSide
    let state: GameState

    var body: some View {
        GlassCard(isActive: state.currentPlayer == side && !state.status.isFinished, accent: side.themeColor) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                playerHeader
                stats
                SkillReserveStrip()
                Spacer(minLength: 0)
            }
        }
    }

    private var playerHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AvatarView(player: player, size: 76)
            Text(player.displayName)
                .font(.title2.bold())
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(2)
            if state.currentPlayer == side && !state.status.isFinished {
                Label("当前回合", systemImage: "sparkle")
                    .font(.caption.bold())
                    .foregroundStyle(side.themeColor)
            }
        }
    }

    private var stats: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label("棋子数 \(state.board.coordinates(for: side).count)", systemImage: "circle.grid.3x3.fill")
            Label(side == state.firstPlayer ? "先手" : "后手", systemImage: "flag.fill")
        }
        .font(.subheadline)
        .foregroundStyle(AppColor.textSecondary)
    }
}

struct PlayerSummaryCard: View {
    let player: PlayerProfileEntity
    let side: PlayerSide
    let state: GameState

    var body: some View {
        GlassCard(isActive: state.currentPlayer == side && !state.status.isFinished, accent: side.themeColor) {
            HStack(spacing: AppSpacing.md) {
                AvatarView(player: player, size: 50)
                VStack(alignment: .leading, spacing: 2) {
                    Text(player.displayName)
                        .font(.headline)
                        .foregroundStyle(AppColor.textPrimary)
                    Text("棋子 \(state.board.coordinates(for: side).count) · \(side == state.firstPlayer ? "先手" : "后手")")
                        .font(.caption)
                        .foregroundStyle(AppColor.textSecondary)
                }
                Spacer()
                Text(side.stoneSymbol)
                    .font(.title2.bold())
                    .foregroundStyle(side.themeColor)
            }
        }
    }
}

struct TurnBanner: View {
    let state: GameState
    let playerOne: PlayerProfileEntity
    let playerTwo: PlayerProfileEntity

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppColor.textPrimary)
                Text("第 \(state.turnCount) 回合")
                    .font(.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
            Spacer()
            Image(systemName: state.status.isFinished ? "checkmark.seal.fill" : "hand.tap.fill")
                .foregroundStyle(currentSide.themeColor)
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                .fill(AppColor.surface)
        )
    }

    private var currentSide: PlayerSide {
        switch state.status {
        case let .won(winner, _): winner
        default: state.currentPlayer
        }
    }

    private var title: String {
        switch state.status {
        case .inProgress:
            return "\(currentSide == .playerOne ? playerOne.displayName : playerTwo.displayName) 行动"
        case let .won(winner, _):
            return "\(winner == .playerOne ? playerOne.displayName : playerTwo.displayName) 获胜"
        case .draw:
            return "本局平局"
        }
    }
}

struct SkillReserveStrip: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label("技能区预留", systemImage: "rectangle.stack.badge.plus")
                .font(.subheadline.bold())
                .foregroundStyle(AppColor.textPrimary)
            Text("经典模式不会启用技能；后续阶段将在这里显示技能卡状态。")
                .font(.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }
}
