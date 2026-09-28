import SwiftUI

struct PrimaryButton: View {
    let title: String
    let systemImage: String
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppColor.background)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                .fill(isDisabled ? AppColor.elevatedSurface : AppColor.accent)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                .stroke(.white.opacity(isDisabled ? 0.04 : 0.18), lineWidth: 1)
        )
        .opacity(isDisabled ? 0.55 : 1)
        .disabled(isDisabled)
        .accessibilityLabel(title)
    }
}

struct GameStartActionLabel: View {
    let title: String
    let subtitle: String
    var accent: Color = AppColor.accent

    var body: some View {
        ZStack(alignment: .trailing) {
            StartActionBoardPattern(accent: accent)
                .frame(width: 144)
                .opacity(0.72)
                .accessibilityHidden(true)

            HStack(spacing: AppSpacing.md) {
                Image(systemName: "play.fill")
                    .font(.title2.bold())
                    .foregroundStyle(Color(red: 0.10, green: 0.23, blue: 0.19))
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [AppColor.warning, Color(red: 0.88, green: 0.56, blue: 0.22)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(Color.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppColor.textPrimary.opacity(0.82))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }

                Spacer(minLength: AppSpacing.xs)
                Image(systemName: "arrow.right")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColor.warning)
            }
            .padding(AppSpacing.md)
        }
        .background(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.07, green: 0.37, blue: 0.30),
                            Color(red: 0.055, green: 0.16, blue: 0.15),
                            AppColor.surface
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(AppColor.warning.opacity(0.62), lineWidth: 1)
        )
        .shadow(color: accent.opacity(0.16), radius: 18, y: 8)
    }
}

private struct StartActionBoardPattern: View {
    let accent: Color

    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 18
            var grid = Path()
            stride(from: CGFloat.zero, through: size.width, by: step).forEach { x in
                grid.move(to: CGPoint(x: x, y: 0))
                grid.addLine(to: CGPoint(x: x, y: size.height))
            }
            stride(from: CGFloat.zero, through: size.height, by: step).forEach { y in
                grid.move(to: CGPoint(x: 0, y: y))
                grid.addLine(to: CGPoint(x: size.width, y: y))
            }
            context.stroke(grid, with: .color(.white.opacity(0.055)), lineWidth: 1)

            let stones = [
                CGPoint(x: size.width * 0.54, y: size.height * 0.28),
                CGPoint(x: size.width * 0.68, y: size.height * 0.50),
                CGPoint(x: size.width * 0.82, y: size.height * 0.72)
            ]
            for (index, point) in stones.enumerated() {
                context.fill(
                    Path(ellipseIn: CGRect(x: point.x - 8, y: point.y - 8, width: 16, height: 16)),
                    with: .color(index == 1 ? AppColor.warning.opacity(0.22) : accent.opacity(0.20))
                )
            }
        }
        .mask(
            LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing)
        )
        .allowsHitTesting(false)
    }
}
