import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var app: AppContainer
    @State private var search = ""

    private var filtered: [TaskSolution] {
        if search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return app.tasks }
        let q = search.lowercased()
        return app.tasks.filter { $0.question.lowercased().contains(q) || $0.subject.rawValue.lowercased().contains(q) }
    }

    var body: some View {
        List {
            if filtered.isEmpty {
                ContentUnavailableView("Sin tareas", systemImage: "clock", description: Text("Las tareas que guardes aparecerán aquí."))
            } else {
                ForEach(filtered) { task in
                    NavigationLink {
                        ResultsView(solution: task, image: app.image(for: task))
                    } label: {
                        HStack(spacing: 12) {
                            if let image = app.image(for: task) {
                                Image(uiImage: image).resizable().scaledToFill().frame(width: 54, height: 54).clipShape(RoundedRectangle(cornerRadius: 10))
                            } else {
                                Image(systemName: task.subject.icon).frame(width: 54, height: 54).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.subject.rawValue).font(.headline)
                                Text(task.question).lineLimit(2).foregroundStyle(.secondary)
                                Text(task.createdAt.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { app.deleteTask(task) } label: { Label("Borrar", systemImage: "trash") }
                    }
                    .swipeActions(edge: .leading) {
                        Button { app.toggleFavorite(task.id) } label: { Label("Favorito", systemImage: task.isFavorite ? "star.slash" : "star") }.tint(.yellow)
                    }
                }
            }
        }
        .searchable(text: $search, prompt: "Buscar tarea")
        .navigationTitle("Historial")
    }
}
