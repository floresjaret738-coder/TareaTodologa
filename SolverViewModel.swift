import Foundation
import Combine
import SwiftUI
import UIKit

@MainActor
final class SolverViewModel: ObservableObject {
    @Published var question = ""
    @Published var selectedSubject: Subject = .automatic
    @Published var image: UIImage?
    @Published var ocrItems: [OCRItem] = []
    @Published var solution: TaskSolution?
    @Published var isWorking = false
    @Published var errorMessage: String?

    private let ocrService: OCRService
    private let aiServiceProvider: () -> AIService
    private weak var app: AppContainer?

    init(app: AppContainer? = nil) {
        self.app = app
        if let app {
            ocrService = app.ocrService
            aiServiceProvider = { app.aiService() }
        } else {
            ocrService = OCRService()
            aiServiceProvider = { MockAIService() }
        }
    }

    func setImage(_ image: UIImage) {
        self.image = image
        solution = nil
        errorMessage = nil
        ocrItems = []
        question = ""
        Task { await recognize() }
    }

    func analyzeImage(_ image: UIImage) {
        setImage(image)
    }

    func recognize() async {
        guard let image else { return }
        do {
            let items = try await ocrService.recognize(image: image)
            ocrItems = items
            question = items.map(\.text).joined(separator: "\n")
            if selectedSubject == .automatic {
                selectedSubject = ocrService.detectedSubject(from: question)
            }
        } catch {
            ocrItems = []
            errorMessage = error.localizedDescription
        }
    }

    func solve() async {
        let trimmedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuestion.isEmpty || image != nil else {
            errorMessage = "Escribe una pregunta o sube una foto."
            return
        }

        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            let service = aiServiceProvider()
            let level = app?.settings.explanationLevel ?? .normal
            let solved = try await service.solve(
                question: trimmedQuestion,
                subject: selectedSubject,
                level: level,
                image: image,
                ocrItems: ocrItems
            )
            solution = solved
            app?.saveTask(solved, image: image)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
