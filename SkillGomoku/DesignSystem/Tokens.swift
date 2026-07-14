import SwiftUI

enum AppColor {
    static let background = Color(red: 0.05, green: 0.07, blue: 0.12)
    static let surface = Color(red: 0.09, green: 0.12, blue: 0.19)
    static let elevatedSurface = Color(red: 0.13, green: 0.16, blue: 0.24)
    static let board = Color(red: 0.89, green: 0.91, blue: 0.94)
    static let grid = Color(red: 0.36, green: 0.41, blue: 0.48)
    static let playerOne = Color(red: 0.23, green: 0.65, blue: 1.0)
    static let playerTwo = Color(red: 1.0, green: 0.42, blue: 0.42)
    static let accent = Color(red: 0.48, green: 0.36, blue: 0.99)
    static let success = Color(red: 0.21, green: 0.79, blue: 0.56)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.68)
}

enum AppSpacing {
    static let xs: CGFloat = 6
    static let sm: CGFloat = 10
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

enum AppRadius {
    static let card: CGFloat = 22
    static let control: CGFloat = 14
    static let board: CGFloat = 18
}

enum AppShadow {
    static let card = Color.black.opacity(0.24)
}

extension PlayerSide {
    var themeColor: Color {
        self == .playerOne ? AppColor.playerOne : AppColor.playerTwo
    }
}
