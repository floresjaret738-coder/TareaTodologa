import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var app: AppContainer
    private var favorites: [TaskSolution] { app.tasks.filter(\.isFavorite) }

    var body: some View {
        List {
            if favorites.isEmpty {
                ContentUnavailableView("Sin favoritos", systemImage: "star", description: Text("Guarda una solución como favorita para verla aquí."))
            } else {
                ForEach(favorites) { task in
                    NavigationLink {
                        ResultsView(solution: task, image: app.image(for: task))
                    } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Label(task.subject.rawValue, systemImage: "star.fill").foregroundStyle(.yellow)
                            Text(task.question).lineLimit(2)
                            Text(task.finalAnswer).foregroundStyle(.green).font(.headline)
                        }
                    }
                }
            }
        }
        .navigationTitle("Favoritos")
    }
}
