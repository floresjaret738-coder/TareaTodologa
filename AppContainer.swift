import Foundation
import Combine
import SwiftUI
import UIKit

@MainActor
final class AppContainer: ObservableObject {
    @Published private(set) var tasks: [TaskSolution]

    let settings: AppSettings
    let persistence: PersistenceService
    let imageStore: ImageStore
    let keychain: KeychainService
    let ocrService: OCRService

    init() {
        settings = AppSettings()
        persistence = PersistenceService()
        imageStore = ImageStore()
        keychain = KeychainService()
        ocrService = OCRService()
        tasks = persistence.load()
    }

    func saveTask(_ solution: TaskSolution, image: UIImage?) {
        var saved = solution
        let existing = tasks.first(where: { $0.id == solution.id })

        if settings.saveImagesLocally, let image {
            if let old = existing?.imageFileName, old != saved.imageFileName {
                imageStore.delete(old)
            }
            if let filename = try? imageStore.save(image, id: solution.id) {
                saved.imageFileName = filename
            }
        } else if let old = existing?.imageFileName {
            imageStore.delete(old)
            saved.imageFileName = nil
        }

        if existing?.isFavorite == true {
            saved.isFavorite = true
        }

        tasks.removeAll { $0.id == saved.id }
        tasks.insert(saved, at: 0)
        try? persistence.save(tasks)
    }

    func toggleFavorite(_ id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].isFavorite.toggle()
        try? persistence.save(tasks)
    }

    func deleteTask(_ task: TaskSolution) {
        if let filename = task.imageFileName {
            imageStore.delete(filename)
        }
        tasks.removeAll { $0.id == task.id }
        try? persistence.save(tasks)
    }

    func clearHistory() {
        imageStore.deleteAll()
        tasks.removeAll()
        persistence.clear()
    }

    func image(for task: TaskSolution) -> UIImage? {
        guard let filename = task.imageFileName else { return nil }
        return imageStore.load(filename)
    }

    func aiService() -> AIService {
        AIServiceFactory.make(settings: settings, keychain: keychain)
    }
}
