import SwiftUI
import UIKit

struct ScanView: View {
    @EnvironmentObject private var app: AppContainer
    @ObservedObject var vm: SolverViewModel
    let initialImage: UIImage?

    init(vm: SolverViewModel, initialImage: UIImage? = nil) {
        self.vm = vm
        self.initialImage = initialImage
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let image = vm.image ?? initialImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Texto detectado", systemImage: "text.viewfinder")
                            .font(.headline)
                        if vm.question.isEmpty {
                            ProgressView("Leyendo la imagen…")
                        } else {
                            Text(vm.question)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Picker("Materia", selection: $vm.selectedSubject) {
                    ForEach(Subject.allCases) { subject in
                        Text(subject.rawValue).tag(subject)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)

                PrimaryButton(title: vm.isWorking ? "Analizando…" : "Resolver tarea", icon: "sparkles") {
                    Task { await vm.solve() }
                }
                .disabled(vm.isWorking)

                if let error = vm.errorMessage {
                    Text(error).foregroundStyle(.red)
                }

                if let solution = vm.solution {
                    NavigationLink {
                        ResultsView(solution: solution, image: vm.image ?? initialImage)
                    } label: {
                        Text("Ver resultado")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.indigo, in: RoundedRectangle(cornerRadius: 16))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Escanear tarea")
        .task {
            if vm.image == nil, let initialImage { vm.setImage(initialImage) }
        }
    }
}
