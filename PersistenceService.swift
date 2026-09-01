import Foundation

final class PersistenceService {
    private let key = "TareaTodologa.Tasks.v2"

    func load() -> [TaskSolution] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let tasks = try? JSONDecoder().decode([TaskSolution].self, from: data) else { return [] }
        return tasks.sorted { $0.createdAt > $1.createdAt }
    }

    func save(_ tasks: [TaskSolution]) throws {
        let data = try JSONEncoder().encode(tasks)
        UserDefaults.standard.set(data, forKey: key)
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
