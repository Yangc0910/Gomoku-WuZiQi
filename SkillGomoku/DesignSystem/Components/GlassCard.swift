import SwiftUI

struct GlassCard<Content: View>: View {
    let isActive: Bool
    let accent: Color
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .fill(AppColor.elevatedSurface.opacity(isActive ? 0.96 : 0.62))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .stroke(isActive ? accent : Color.white.opacity(0.08), lineWidth: isActive ? 2 : 1)
            )
            .shadow(color: isActive ? accent.opacity(0.2) : AppShadow.card, radius: isActive ? 18 : 10, y: 8)
            .saturation(isActive ? 1 : 0.25)
            .opacity(isActive ? 1 : 0.72)
    }
}
