import Foundation
import SwiftUI
import UIKit

protocol AvatarStoring {
    func saveAvatarImage(_ image: UIImage, for playerID: UUID) throws -> String
    func image(for filename: String?) -> UIImage?
    func deleteAvatar(filename: String?) throws
}

final class AvatarService: AvatarStoring {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func saveAvatarImage(_ image: UIImage, for playerID: UUID) throws -> String {
        let square = image.squareThumbnail(side: 512)
        let filename = "\(playerID.uuidString).jpg"
        let url = try avatarDirectory().appendingPathComponent(filename)
        guard let data = square.jpegData(compressionQuality: 0.86) else {
            throw CocoaError(.fileWriteUnknown)
        }
        try data.write(to: url, options: .atomic)
        return filename
    }

    func image(for filename: String?) -> UIImage? {
        guard let filename,
              let directory = try? avatarDirectory(),
              let data = try? Data(contentsOf: directory.appendingPathComponent(filename))
        else { return nil }
        return UIImage(data: data)
    }

    func deleteAvatar(filename: String?) throws {
        guard let filename else { return }
        let url = try avatarDirectory().appendingPathComponent(filename)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    private func avatarDirectory() throws -> URL {
        let base = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = base.appendingPathComponent("Avatars", isDirectory: true)
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }
}

private extension UIImage {
    func squareThumbnail(side: CGFloat) -> UIImage {
        let sourceSize = size
        let cropSide = min(sourceSize.width, sourceSize.height)
        let cropRect = CGRect(
            x: (sourceSize.width - cropSide) / 2,
            y: (sourceSize.height - cropSide) / 2,
            width: cropSide,
            height: cropSide
        )

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { _ in
            draw(in: CGRect(
                x: -cropRect.origin.x * side / cropSide,
                y: -cropRect.origin.y * side / cropSide,
                width: sourceSize.width * side / cropSide,
                height: sourceSize.height * side / cropSide
            ))
        }
    }
}
