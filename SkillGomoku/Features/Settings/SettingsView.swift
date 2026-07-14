import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var players: [PlayerProfileEntity]
    @Query private var matches: [PersistedMatchEntity]
    @State private var showingDeleteConfirmation = false

    var body: some View {
        Form {
            Section("隐私") {
                Text("玩家照片只保存在本机，用于设置本机玩家头像，不会上传服务器。")
                Text("相机权限用途：用于设置本机玩家头像。")
            }

            Section("数据") {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("删除所有玩家和对局数据", systemImage: "trash")
                }
            }

            Section("版本") {
                LabeledContent("当前阶段", value: "Phase 0 + Phase 1")
                LabeledContent("可用模式", value: "经典五子棋")
            }
        }
        .navigationTitle("设置")
        .confirmationDialog("删除所有本地数据？", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("删除", role: .destructive) {
                players.forEach { modelContext.delete($0) }
                matches.forEach { modelContext.delete($0) }
                try? modelContext.save()
            }
            Button("取消", role: .cancel) {}
        }
    }
}
