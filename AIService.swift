import Foundation
import UIKit

protocol AIService {
    func solve(
        question: String,
        subject: Subject,
        level: ExplanationLevel,
        image: UIImage?,
        ocrItems: [OCRItem]
    ) async throws -> TaskSolution
}

enum AIServiceError: LocalizedError {
    case invalidEndpoint
    case serverError(Int)
    case invalidResponse
    case emptyQuestion

    var errorDescription: String? {
        switch self {
        case .invalidEndpoint:
            return "El endpoint de IA no es válido."
        case .serverError(let status):
            return "El servidor de IA respondió con el código \(status)."
        case .invalidResponse:
            return "El servidor devolvió una respuesta que la app no pudo interpretar."
        case .emptyQuestion:
            return "No se encontró una pregunta para resolver."
        }
    }
}

@MainActor
struct AIServiceFactory {
    static func make(settings: AppSettings, keychain: KeychainService) -> AIService {
        let endpoint = settings.apiEndpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        if endpoint.isEmpty {
            return MockAIService()
        }
        return RemoteAIService(
            endpoint: endpoint,
            tokenProvider: { keychain.getToken() },
            allowImages: settings.allowRemoteImages
        )
    }
}

final class RemoteAIService: AIService {
    private let endpoint: String
    private let tokenProvider: () -> String?
    private let allowImages: Bool

    init(endpoint: String, tokenProvider: @escaping () -> String?, allowImages: Bool) {
        self.endpoint = endpoint
        self.tokenProvider = tokenProvider
        self.allowImages = allowImages
    }

    private struct RequestBody: Encodable {
        let question: String
        let subject: String
        let level: String
        let ocrItems: [OCRItem]
        let imageBase64JPEG: String?
    }

    private struct ResponseBody: Decodable {
        let question: String
        let subject: String
        let finalAnswer: String
        let summary: String
        let steps: [SolutionStep]
        let why: [String]
        let easyExplanation: String
        let directExplanation: String
        let annotations: [WorksheetAnnotation]?
    }

    func solve(
        question: String,
        subject: Subject,
        level: ExplanationLevel,
        image: UIImage?,
        ocrItems: [OCRItem]
    ) async throws -> TaskSolution {
        let trimmedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuestion.isEmpty || image != nil else {
            throw AIServiceError.emptyQuestion
        }
        guard let url = URL(string: endpoint), url.scheme?.lowercased() == "https" else {
            throw AIServiceError.invalidEndpoint
        }

        var imageData: String?
        if allowImages, let image, let data = image.jpegData(compressionQuality: 0.72) {
            imageData = data.base64EncodedString()
        }

        let body = RequestBody(
            question: trimmedQuestion,
            subject: subject.rawValue,
            level: level.rawValue,
            ocrItems: ocrItems,
            imageBase64JPEG: imageData
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = tokenProvider(), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONEncoder().encode(body)
        request.timeoutInterval = 60

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw AIServiceError.serverError(http.statusCode)
        }

        let decoded: ResponseBody
        do {
            decoded = try JSONDecoder().decode(ResponseBody.self, from: data)
        } catch {
            throw AIServiceError.invalidResponse
        }

        return TaskSolution(
            question: decoded.question.isEmpty ? trimmedQuestion : decoded.question,
            subject: Subject.fromBackendValue(decoded.subject) ?? (subject == .automatic ? .other : subject),
            finalAnswer: decoded.finalAnswer,
            summary: decoded.summary,
            steps: decoded.steps,
            why: decoded.why,
            easyExplanation: decoded.easyExplanation,
            directExplanation: decoded.directExplanation,
            ocrItems: ocrItems,
            annotations: decoded.annotations ?? [],
            createdAt: .now
        )
    }
}

final class MockAIService: AIService {
    func solve(
        question: String,
        subject: Subject,
        level: ExplanationLevel,
        image: UIImage?,
        ocrItems: [OCRItem]
    ) async throws -> TaskSolution {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        let detected = subject == .automatic ? detectSubject(trimmed) : subject

        if let linear = solveLinearEquation(trimmed) {
            return TaskSolution(
                question: trimmed,
                subject: detected == .automatic ? .algebra : detected,
                finalAnswer: linear.answer,
                summary: "Despejamos la variable paso a paso.",
                steps: linear.steps,
                why: [
                    "Hacemos la misma operación en ambos lados para mantener la igualdad.",
                    "Al final dejamos la variable sola para obtener su valor."
                ],
                easyExplanation: "Piensa en una balanza: lo que hagas de un lado también tienes que hacerlo del otro.",
                directExplanation: linear.answer,
                ocrItems: ocrItems,
                annotations: [],
                createdAt: .now
            )
        }

        if let factor = factorQuadratic(trimmed) {
            return TaskSolution(
                question: trimmed,
                subject: detected == .automatic ? .algebra : detected,
                finalAnswer: factor.answer,
                summary: "Buscamos dos números que multipliquen el término independiente y sumen el coeficiente de x.",
                steps: factor.steps,
                why: [
                    "La factorización convierte el polinomio en un producto más fácil de usar.",
                    "Comprobamos que al multiplicar los factores recuperamos el polinomio original."
                ],
                easyExplanation: "Busca dos números que al multiplicarse den el último número y al sumarse den el número de x.",
                directExplanation: factor.answer,
                ocrItems: ocrItems,
                annotations: [],
                createdAt: .now
            )
        }

        return TaskSolution(
            question: trimmed.isEmpty ? "Tarea escaneada" : trimmed,
            subject: detected == .automatic ? .other : detected,
            finalAnswer: genericAnswer(for: detected),
            summary: "La versión local resuelve algunos ejercicios comunes sin una API. Para preguntas abiertas, configura un backend en Ajustes.",
            steps: [
                SolutionStep(title: "Identifica lo que pide la pregunta", explanation: "Separamos los datos, la pregunta y la información necesaria."),
                SolutionStep(title: "Aplica la regla adecuada", explanation: "Usa la definición, fórmula o procedimiento correspondiente a la materia."),
                SolutionStep(title: "Comprueba", explanation: "Revisa que la respuesta tenga sentido y coincida con los datos.")
            ],
            why: [
                "Separar el problema en pasos reduce errores.",
                "Comprobar la respuesta ayuda a detectar operaciones incorrectas."
            ],
            easyExplanation: "Primero mira qué te preguntan, luego usa la regla que corresponde y al final revisa tu resultado.",
            directExplanation: genericAnswer(for: detected),
            ocrItems: ocrItems,
            annotations: [],
            createdAt: .now
        )
    }

    private func detectSubject(_ text: String) -> Subject {
        let t = text.lowercased()
        if t.contains("ecuación") || t.contains("factoriza") || t.contains("polinomio") || t.range(of: #"\bx\b"#, options: .regularExpression) != nil {
            return .algebra
        }
        if t.contains("triángulo") || t.contains("ángulo") || t.contains("perímetro") || t.contains("área") {
            return .geometry
        }
        if t.contains("fuerza") || t.contains("velocidad") || t.contains("aceleración") || t.contains("newton") {
            return .physics
        }
        if t.contains("átomo") || t.contains("mol") || t.contains("reacción") || t.contains("balancea") {
            return .chemistry
        }
        if t.contains("célula") || t.contains("dna") || t.contains("mitosis") {
            return .biology
        }
        if t.contains("guerra") || t.contains("revolución") || t.contains("siglo") {
            return .history
        }
        if t.contains("translate") || t.contains("grammar") || t.contains("verb") || t.contains("english") {
            return .english
        }
        if t.contains("sintaxis") || t.contains("verbo") || t.contains("sustantivo") || t.contains("gramática") {
            return .spanish
        }
        return .automatic
    }

    private func genericAnswer(for subject: Subject) -> String {
        switch subject {
        case .physics: return "Necesita los datos y la fórmula del ejercicio."
        case .chemistry: return "Necesita los reactivos y datos del ejercicio."
        case .biology: return "Identifica el concepto clave y relaciónalo con la pregunta."
        default: return "Conecta una API de IA en Ajustes para resolver preguntas abiertas."
        }
    }

    private func solveLinearEquation(_ text: String) -> (answer: String, steps: [SolutionStep])? {
        let cleaned = text.replacingOccurrences(of: " ", with: "")
        let pattern = #"^([+-]?\d*\.?\d*)x([+-]\d*\.?\d*)=([+-]?\d*\.?\d*)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: cleaned, range: NSRange(location: 0, length: cleaned.utf16.count)),
              match.numberOfRanges == 4 else { return nil }

        func value(_ index: Int) -> Double? {
            guard let range = Range(match.range(at: index), in: cleaned) else { return nil }
            let value = String(cleaned[range])
            if value.isEmpty || value == "+" { return 1 }
            if value == "-" { return -1 }
            return Double(value)
        }

        guard let a = value(1), let b = value(2), let c = value(3), a != 0 else { return nil }
        let x = (c - b) / a
        let answer = "x = \(formatNumber(x))"
        let bText = formatNumber(b)
        let firstExplanation = b >= 0 ? "Restamos \(bText) a ambos lados." : "Sumamos \(formatNumber(-b)) a ambos lados."
        let firstEquation = "\(cleaned)  →  \(formatNumber(a))x = \(formatNumber(c - b))"
        let secondExplanation = a == 1 ? "x ya está despejada." : "Dividimos ambos lados entre \(formatNumber(a))."
        let secondEquation = "\(formatNumber(a))x = \(formatNumber(c - b))  →  \(answer)"

        return (
            answer,
            [
                SolutionStep(title: "Aísla el término con x", explanation: firstExplanation, equation: firstEquation),
                SolutionStep(title: "Despeja x", explanation: secondExplanation, equation: secondEquation)
            ]
        )
    }

    private func factorQuadratic(_ text: String) -> (answer: String, steps: [SolutionStep])? {
        let cleaned = text.replacingOccurrences(of: " ", with: "")
        let pattern = #"^x\^2([+-]\d*\.?\d*)x([+-]\d*\.?\d*)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: cleaned, range: NSRange(location: 0, length: cleaned.utf16.count)),
              match.numberOfRanges == 3 else { return nil }

        func number(_ index: Int) -> Int? {
            guard let range = Range(match.range(at: index), in: cleaned) else { return nil }
            let value = String(cleaned[range])
            return Int(value)
        }

        guard let b = number(1), let c = number(2) else { return nil }
        for first in -abs(c)...abs(c) where first != 0 || c == 0 {
            if first == 0 { continue }
            guard c % first == 0 else { continue }
            let second = c / first
            if first + second == b {
                let factor = "(x \(first >= 0 ? "+" : "−") \(abs(first)))(x \(second >= 0 ? "+" : "−") \(abs(second)))"
                return (
                    factor,
                    [
                        SolutionStep(title: "Busca dos números", explanation: "Necesitamos dos números que multipliquen \(c) y sumen \(b).", equation: "\(first) × \(second) = \(c),   \(first) + \(second) = \(b)"),
                        SolutionStep(title: "Escribe los factores", explanation: "Colocamos esos números junto a x.", equation: "\(cleaned) = \(factor)")
                    ]
                )
            }
        }
        return nil
    }

    private func formatNumber(_ number: Double) -> String {
        if number.rounded() == number { return String(Int(number)) }
        return String(format: "%.4g", number)
    }
}

private extension Subject {
    static func fromBackendValue(_ value: String) -> Subject? {
        if let subject = Subject(rawValue: value) { return subject }
        let normalized = value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        return Subject.allCases.first {
            $0.rawValue.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current) == normalized
        }
    }
}
