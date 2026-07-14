import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct PlayerEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let player: PlayerProfileEntity?

    @State private var name = ""
    @State private var selectedTheme: PlayerSide = .playerOne
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var previewImage: UIImage?
    @State private var showingCamera = false
    @State private var errorMessage: String?

    private let avatarService = AvatarService()
    private let cameraAvailability = DeviceCameraAvailability()

    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    avatarPreview
                    Spacer()
                }
                TextField("姓名或昵称", text: $name)
                Picker("玩家主题", selection: $selectedTheme) {
                    Text("电光蓝").tag(PlayerSide.playerOne)
                    Text("珊瑚橙").tag(PlayerSide.playerTwo)
                }
                .pickerStyle(.segmented)
            }

            Section("头像") {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("从照片选择", systemImage: "photo.on.rectangle")
                }

                Button {
                    showingCamera = true
                } label: {
                    Label("使用相机拍照", systemImage: "camera")
                }
                .disabled(!cameraAvailability.isCameraAvailable)

                if !cameraAvailability.isCameraAvailable {
                    Text("当前设备或模拟器无法使用相机，可以先从照片选择头像。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Button(role: .destructive) {
                    previewImage = nil
                    player?.avatarFilename = nil
                } label: {
                    Label("使用默认头像", systemImage: "person.crop.circle")
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(player == nil ? "新建玩家" : "编辑玩家")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") { save() }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onAppear {
            name = player?.displayName ?? ""
            selectedTheme = PlayerSide(rawValue: player?.themeToken ?? "") ?? .playerOne
            previewImage = avatarService.image(for: player?.avatarFilename)
        }
        .onChange(of: selectedPhoto) { _, item in
            loadPhoto(item)
        }
        .sheet(isPresented: $showingCamera) {
            CameraPicker { image in
                previewImage = image
            }
        }
    }

    private var avatarPreview: some View {
        Group {
            if let previewImage {
                Image(uiImage: previewImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Circle().fill(selectedTheme.themeColor.opacity(0.24))
                    Image(systemName: "person.fill")
                        .font(.largeTitle)
                        .foregroundStyle(selectedTheme.themeColor)
                }
            }
        }
        .frame(width: 112, height: 112)
        .clipShape(Circle())
        .overlay(Circle().stroke(selectedTheme.themeColor, lineWidth: 3))
    }

    private func loadPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else { return }
                await MainActor.run {
                    previewImage = image
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func save() {
        do {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let target = player ?? PlayerProfileEntity(displayName: trimmedName, themeToken: selectedTheme.rawValue)
            target.displayName = trimmedName
            target.themeToken = selectedTheme.rawValue
            target.lastUsedAt = Date()
            if let previewImage {
                target.avatarFilename = try avatarService.saveAvatarImage(previewImage, for: target.id)
            }
            if player == nil {
                modelContext.insert(target)
            }
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
