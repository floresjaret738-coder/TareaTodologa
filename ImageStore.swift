import Foundation
import UIKit

final class ImageStore {
    private let directory: URL

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        directory = base.appendingPathComponent("TaskImages", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func save(_ image: UIImage, id: UUID) throws -> String {
        let filename = "\(id.uuidString).jpg"
        let url = directory.appendingPathComponent(filename)
        guard let data = image.jpegData(compressionQuality: 0.86) else {
            throw ImageStoreError.encodingFailed
        }
        try data.write(to: url, options: .atomic)
        return filename
    }

    func load(_ filename: String) -> UIImage? {
        UIImage(contentsOfFile: directory.appendingPathComponent(filename).path)
    }

    func delete(_ filename: String) {
        try? FileManager.default.removeItem(at: directory.appendingPathComponent(filename))
    }

    func deleteAll() {
        guard let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else { return }
        for file in files { try? FileManager.default.removeItem(at: file) }
    }
}

enum ImageStoreError: LocalizedError {
    case encodingFailed
    var errorDescription: String? { "No se pudo guardar la imagen." }
}
