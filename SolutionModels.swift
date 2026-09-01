import Foundation
import CoreGraphics

enum SolutionMode: String, CaseIterable, Identifiable {
    case direct = "Directo"
    case normal = "Normal"
    case easy = "Más fácil"
    case detailed = "Detallado"
    var id: String { rawValue }
}

struct SolutionStep: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var explanation: String
    var equation: String?

    init(id: UUID = UUID(), title: String, explanation: String, equation: String? = nil) {
        self.id = id
        self.title = title
        self.explanation = explanation
        self.equation = equation
    }
}

struct CGRectCodable: Codable, Hashable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    init(_ rect: CGRect) {
        x = Double(rect.origin.x)
        y = Double(rect.origin.y)
        width = Double(rect.width)
        height = Double(rect.height)
    }

    var cgRect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }
}

struct OCRItem: Identifiable, Codable, Hashable {
    let id: UUID
    var text: String
    var normalizedRect: CGRectCodable

    init(id: UUID = UUID(), text: String, normalizedRect: CGRectCodable) {
        self.id = id
        self.text = text
        self.normalizedRect = normalizedRect
    }
}

struct WorksheetAnnotation: Identifiable, Codable, Hashable {
    let id: UUID
    var rect: CGRectCodable
    var answer: String
    var label: String

    init(id: UUID = UUID(), rect: CGRectCodable, answer: String, label: String = "Respuesta") {
        self.id = id
        self.rect = rect
        self.answer = answer
        self.label = label
    }
}

struct TaskSolution: Identifiable, Codable, Hashable {
    let id: UUID
    var question: String
    var subject: Subject
    var finalAnswer: String
    var summary: String
    var steps: [SolutionStep]
    var why: [String]
    var easyExplanation: String
    var directExplanation: String
    var ocrItems: [OCRItem]
    var annotations: [WorksheetAnnotation]
    var createdAt: Date
    var imageFileName: String?
    var isFavorite: Bool

    init(id: UUID = UUID(), question: String, subject: Subject, finalAnswer: String,
         summary: String, steps: [SolutionStep], why: [String], easyExplanation: String,
         directExplanation: String, ocrItems: [OCRItem] = [], annotations: [WorksheetAnnotation] = [],
         createdAt: Date = .now, imageFileName: String? = nil, isFavorite: Bool = false) {
        self.id = id
        self.question = question
        self.subject = subject
        self.finalAnswer = finalAnswer
        self.summary = summary
        self.steps = steps
        self.why = why
        self.easyExplanation = easyExplanation
        self.directExplanation = directExplanation
        self.ocrItems = ocrItems
        self.annotations = annotations
        self.createdAt = createdAt
        self.imageFileName = imageFileName
        self.isFavorite = isFavorite
    }
}
