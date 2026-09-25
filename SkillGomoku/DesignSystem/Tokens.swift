import SwiftUI

enum AppColor {
    static let background = Color(red: 0.025, green: 0.038, blue: 0.050)
    static let backgroundRaised = Color(red: 0.045, green: 0.064, blue: 0.076)
    static let surface = Color(red: 0.065, green: 0.085, blue: 0.098)
    static let elevatedSurface = Color(red: 0.086, green: 0.111, blue: 0.126)
    static let board = Color(red: 0.91, green: 0.88, blue: 0.82)
    static let boardEdge = Color(red: 0.73, green: 0.69, blue: 0.62)
    static let grid = Color(red: 0.25, green: 0.28, blue: 0.28)
    static let playerOne = Color(red: 0.36, green: 0.88, blue: 0.71)
    static let playerTwo = Color(red: 1.0, green: 0.67, blue: 0.37)
    static let accent = Color(red: 0.36, green: 0.88, blue: 0.71)
    static let success = Color(red: 0.36, green: 0.88, blue: 0.71)
    static let warning = Color(red: 1.0, green: 0.72, blue: 0.35)
    static let danger = Color(red: 1.0, green: 0.40, blue: 0.42)
    static let textPrimary = Color(red: 0.96, green: 0.95, blue: 0.92)
    static let textSecondary = Color(red: 0.67, green: 0.71, blue: 0.72)
    static let divider = Color.white.opacity(0.09)
}

enum AppSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 7
    static let sm: CGFloat = 11
    static let md: CGFloat = 16
    static let lg: CGFloat = 22
    static let xl: CGFloat = 30
}

enum AppRadius {
    static let card: CGFloat = 24
    static let control: CGFloat = 16
    static let compact: CGFloat = 12
    static let board: CGFloat = 22
}

enum AppShadow {
    static let card = Color.black.opacity(0.34)
}

struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [AppColor.backgroundRaised, AppColor.background, Color.black.opacity(0.96)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(AppColor.accent.opacity(0.075))
                .frame(width: 360, height: 360)
                .blur(radius: 80)
                .offset(x: 120, y: -150)
        }
        .ignoresSafeArea()
    }
}

extension SkillCategory {
    var themeColor: Color {
        switch self {
        case .destruction: AppColor.danger
        case .recovery: AppColor.success
        case .control: Color(red: 0.64, green: 0.52, blue: 1.0)
        case .defense: Color(red: 0.37, green: 0.70, blue: 1.0)
        case .ultimate: AppColor.warning
        case .movement: Color(red: 0.35, green: 0.82, blue: 0.92)
        }
    }
}

extension PlayerSide {
    var themeColor: Color {
        self == .playerOne ? AppColor.playerOne : AppColor.playerTwo
    }
}
