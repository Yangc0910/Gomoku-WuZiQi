import SwiftUI

struct MatchResultView: View {
    @Environment(\.dismiss) private var dismiss
    let status: MatchStatus
    let turnCount: Int
    let playerOne: PlayerProfileEntity
    let playerTwo: PlayerProfileEntity

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()
            VStack(spacing: AppSpacing.lg) {
                Image(systemName: isDraw ? "equal.circle.fill" : "crown.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(isDraw ? AppColor.textSecondary : winningSide.themeColor)

                Text(title)
                    .font(.largeTitle.bold())
                    .foregroundStyle(AppColor.textPrimary)

                Text(reasonText)
                    .font(.headline)
                    .foregroundStyle(AppColor.textSecondary)

                Text("回合数 \(turnCount)")
                    .font(.subheadline)
                    .foregroundStyle(AppColor.textSecondary)

                Button("回到对局") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(AppSpacing.xl)
        }
    }

    private var isDraw: Bool {
        if case .draw = status { return true }
        return false
    }

    private var winningSide: PlayerSide {
        if case let .won(winner, _) = status { return winner }
        return .playerOne
    }

    private var title: String {
        switch status {
        case let .won(winner, _):
            return "\(winner == .playerOne ? playerOne.displayName : playerTwo.displayName) 获胜"
        case .draw:
            return "平局"
        case .inProgress:
            return "对局进行中"
        }
    }

    private var reasonText: String {
        switch status {
        case .won(_, .fiveInRow): "五子连珠"
        case .won(_, .skillResolved): "技能结算后获胜"
        case .won(_, .boardFull): "棋盘已满"
        case .won(_, .simultaneousFive): "双方同时形成五连"
        case .draw(.boardFull): "棋盘已满"
        case .draw(.simultaneousFive): "双方同时形成五连"
        case .draw(.fiveInRow): "五子连珠"
        case .draw(.skillResolved): "技能结算后平局"
        case .inProgress: "继续完成当前对局"
        }
    }
}
