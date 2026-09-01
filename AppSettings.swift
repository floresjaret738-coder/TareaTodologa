import Foundation
import Combine
import SwiftUI

enum ExplanationLevel: String, CaseIterable, Codable, Identifiable {
    case easy = "Fácil"
    case normal = "Normal"
    case detailed = "Detallado"
    var id: String { rawValue }
}

enum AppLanguage: String, CaseIterable, Codable, Identifiable {
    case spanish = "Español"
    case english = "English"
    var id: String { rawValue }
}

@MainActor
final class AppSettings: ObservableObject {
    @Published var language: AppLanguage { didSet { save() } }
    @Published var explanationLevel: ExplanationLevel { didSet { save() } }
    @Published var useDarkMode: Bool { didSet { save() } }
    @Published var saveImagesLocally: Bool { didSet { save() } }
    @Published var allowRemoteImages: Bool { didSet { save() } }
    @Published var apiEndpoint: String { didSet { save() } }

    private let key = "TareaTodologa.Settings.v3"

    private struct Stored: Codable {
        var language: AppLanguage
        var level: ExplanationLevel
        var dark: Bool
        var saveImages: Bool
        var remoteImages: Bool
        var endpoint: String
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let stored = try? JSONDecoder().decode(Stored.self, from: data) {
            language = stored.language
            explanationLevel = stored.level
            useDarkMode = stored.dark
            saveImagesLocally = stored.saveImages
            allowRemoteImages = stored.remoteImages
            apiEndpoint = stored.endpoint
        } else {
            language = .spanish
            explanationLevel = .normal
            useDarkMode = true
            saveImagesLocally = true
            allowRemoteImages = false
            apiEndpoint = ""
        }
    }

    var colorScheme: ColorScheme? { useDarkMode ? .dark : .light }

    private func save() {
        let stored = Stored(
            language: language,
            level: explanationLevel,
            dark: useDarkMode,
            saveImages: saveImagesLocally,
            remoteImages: allowRemoteImages,
            endpoint: apiEndpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        if let data = try? JSONEncoder().encode(stored) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
