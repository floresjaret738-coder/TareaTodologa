import SwiftUI

struct TextQuestionView: View {
    @ObservedObject var vm: SolverViewModel
    var subject: Subject?
    @State private var showResult = false

    init(vm: SolverViewModel, subject: Subject? = nil) {
        self.vm = vm
        self.subject = subject
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Escribe el ejercicio tal como aparece en tu tarea.")
                    .foregroundStyle(.secondary)
                TextEditor(text: $vm.question)
                    .frame(minHeight: 190)
                    .padding(10)
                    .scrollContentBackground(.hidden)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))

                Picker("Materia", selection: $vm.selectedSubject) {
                    ForEach(Subject.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.menu)

                PrimaryButton(title: vm.isWorking ? "Resolviendo…" : "Resolver", icon: "sparkles") {
                    Task {
                        await vm.solve()
                        showResult = vm.solution != nil
                    }
                }
                .disabled(vm.isWorking)

                if let error = vm.errorMessage { Text(error).foregroundStyle(.red) }
            }
            .padding()
        }
        .navigationTitle("Pregunta")
        .onAppear {
            if let subject { vm.selectedSubject = subject }
        }
        .navigationDestination(isPresented: $showResult) {
            if let solution = vm.solution {
                ResultsView(solution: solution, image: nil)
            }
        }
    }
}
