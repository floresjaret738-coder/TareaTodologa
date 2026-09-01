import SwiftUI
import UIKit

struct ResultsView: View {
    @EnvironmentObject private var app: AppContainer
    let solution: TaskSolution
    let image: UIImage?
    @State private var mode: SolutionMode = .normal

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(solution.subject.rawValue, systemImage: solution.subject.icon)
                            .foregroundStyle(.indigo)
                        Text(solution.question)
                            .font(.headline)
                    }
                }

                GlassCard {
                    Text("Respuesta")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(solution.finalAnswer)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.green)
                        .padding(.vertical, 4)
                    Text(solution.summary)
                        .foregroundStyle(.secondary)
                }

                Picker("Modo", selection: $mode) {
                    ForEach(SolutionMode.allCases) { item in Text(item.rawValue).tag(item) }
                }
                .pickerStyle(.segmented)

                switch mode {
                case .direct:
                    GlassCard { Text(solution.directExplanation).font(.headline) }
                case .easy:
                    ExplanationCard(title: "Más fácil", text: solution.easyExplanation)
                case .normal:
                    StepsCard(steps: solution.steps)
                case .detailed:
                    StepsCard(steps: solution.steps)
                    WhyCard(why: solution.why)
                }

                HStack {
                    Button {
                        app.saveTask(solution, image: image)
                    } label: {
                        Label("Guardar", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        app.toggleFavorite(solution.id)
                    } label: {
                        let favorite = app.tasks.first(where: { $0.id == solution.id })?.isFavorite == true
                        Label("Favorito", systemImage: favorite ? "star.fill" : "star")
                    }
                    .buttonStyle(.bordered)
                }

                HStack {
                    NavigationLink {
                        WhyView(solution: solution)
                    } label: {
                        Label("¿Por qué?", systemImage: "questionmark.circle")
                    }
                    .buttonStyle(.bordered)

                    if let image {
                        NavigationLink {
                            SolvedSheetView(solution: solution, image: image)
                        } label: {
                            Label("Ver resuelto", systemImage: "rectangle.inset.filled")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Resultado")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ExplanationCard: View {
    let title: String
    let text: String
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(.headline)
                Text(text)
            }
        }
    }
}

struct StepsCard: View {
    let steps: [SolutionStep]
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.caption.bold())
                            .frame(width: 28, height: 28)
                            .background(.indigo, in: Circle())
                            .foregroundStyle(.white)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(step.title).font(.headline)
                            Text(step.explanation).foregroundStyle(.secondary)
                            if let equation = step.equation {
                                Text(equation)
                                    .font(.system(.body, design: .monospaced))
                                    .padding(10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(.black.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                    .padding(.vertical, 12)
                    if index < steps.count - 1 { Divider() }
                }
            }
        }
    }
}

struct WhyCard: View {
    let why: [String]
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("¿Por qué?", systemImage: "lightbulb.fill").font(.headline)
                ForEach(Array(why.enumerated()), id: \.offset) { _, item in
                    Text("• \(item)")
                }
            }
        }
    }
}
