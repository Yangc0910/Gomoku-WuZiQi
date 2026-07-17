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
                    .fill(isActive ? AppColor.elevatedSurface : AppColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .stroke(isActive ? accent.opacity(0.78) : AppColor.divider, lineWidth: isActive ? 1.5 : 1)
            )
            .shadow(color: isActive ? accent.opacity(0.12) : AppShadow.card, radius: isActive ? 18 : 12, y: 8)
    }
}
