import Foundation

enum Subject: String, CaseIterable, Codable, Identifiable, Hashable {
    case automatic = "Detectar automáticamente"
    case mathematics = "Matemáticas"
    case algebra = "Álgebra"
    case geometry = "Geometría"
    case calculus = "Cálculo básico"
    case physics = "Física"
    case chemistry = "Química"
    case biology = "Biología"
    case history = "Historia"
    case spanish = "Español"
    case english = "Inglés"
    case literature = "Literatura"
    case other = "Otras"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .automatic: return "sparkles"
        case .mathematics, .algebra, .calculus: return "function"
        case .geometry: return "triangle"
        case .physics: return "atom"
        case .chemistry: return "flask"
        case .biology: return "leaf.fill"
        case .history: return "building.columns.fill"
        case .spanish, .english: return "text.book.closed.fill"
        case .literature: return "book.closed.fill"
        case .other: return "square.grid.2x2.fill"
        }
    }
}
