import Foundation
import Combine
import SwiftUI

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published private(set) var tasks: [TaskSolution] = []
    private weak var app: AppContainer?

    init(app: AppContainer) {
        self.app = app
        tasks = app.tasks
    }

    func refresh() {
        tasks = app?.tasks ?? []
    }

    func delete(_ task: TaskSolution) {
        app?.deleteTask(task)
        refresh()
    }

    func toggleFavorite(_ task: TaskSolution) {
        app?.toggleFavorite(task.id)
        refresh()
    }
}
