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
