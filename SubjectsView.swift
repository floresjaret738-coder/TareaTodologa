import SwiftUI

struct SubjectsView: View {
    @EnvironmentObject private var app: AppContainer
    private let columns = [GridItem(.adaptive(minimum: 145), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Subject.allCases.filter { $0 != .automatic }) { subject in
                    NavigationLink {
                        TextQuestionView(vm: SolverViewModel(app: app), subject: subject)
                    } label: {
                        VStack(alignment: .leading, spacing: 12) {
                            Image(systemName: subject.icon).font(.title2)
                            Text(subject.rawValue).font(.headline)
                        }
                        .frame(maxWidth: .infinity, minHeight: 105, alignment: .leading)
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle("Materias")
    }
}
