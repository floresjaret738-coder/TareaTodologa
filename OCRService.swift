import Foundation
import Vision
import UIKit
import ImageIO

final class OCRService {
    func recognize(image: UIImage) async throws -> [OCRItem] {
        guard let cgImage = image.cgImage else { throw OCRError.invalidImage }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
                let items = observations.compactMap { observation -> OCRItem? in
                    guard let candidate = observation.topCandidates(1).first else { return nil }
                    let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else { return nil }
                    return OCRItem(
                        text: text,
                        normalizedRect: CGRectCodable(observation.boundingBox.standardized)
                    )
                }
                continuation.resume(returning: items)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.minimumTextHeight = 0.008
            request.recognitionLanguages = ["es-ES", "en-US"]

            let orientation = image.cgImageOrientation
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func detectedSubject(from text: String) -> Subject {
        let t = text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let scores: [(Subject, [String])] = [
            (.algebra, ["ecuacion", "factoriza", "polinomio", "variable"]),
            (.geometry, ["triangulo", "angulo", "perimetro", "area", "circunferencia"]),
            (.physics, ["velocidad", "aceleracion", "fuerza", "newton", "masa", "energia"]),
            (.chemistry, ["mol", "atomo", "elemento", "reaccion", "quimica", "balancea"]),
            (.biology, ["celula", "dna", "ecosistema", "mitosis", "biologia"]),
            (.history, ["guerra", "revolucion", "siglo", "presidente", "historia"]),
            (.english, ["translate", "grammar", "verb", "present perfect", "english"]),
            (.spanish, ["sintaxis", "verbo", "sustantivo", "gramatica", "espanol"])
        ]

        var best: (Subject, Int) = (.automatic, 0)
        for (subject, words) in scores {
            let score = words.reduce(0) { $0 + (t.contains($1) ? 1 : 0) }
            if score > best.1 { best = (subject, score) }
        }
        return best.1 > 0 ? best.0 : .automatic
    }
}

enum OCRError: LocalizedError {
    case invalidImage

    var errorDescription: String? {
        switch self {
        case .invalidImage: return "No se pudo leer la imagen."
        }
    }
}

private extension UIImage {
    var cgImageOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
