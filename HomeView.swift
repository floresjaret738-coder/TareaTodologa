import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject private var app: AppContainer
    @State private var showCamera = false
    @State private var showCameraUnavailable = false
    @State private var selectedImage: UIImage?
    @State private var showScan = false
    @State private var showText = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("¡Qué onda! 👋")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("Tu asistente para resolver tareas de casi cualquier materia.")
                        .foregroundStyle(.secondary)
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Label("Escanear tarea", systemImage: "camera.viewfinder")
                            .font(.title3.bold())
                        Text("Toma una foto o elige una imagen. Vision detecta el texto y prepara la solución.")
                            .foregroundStyle(.secondary)

                        Button {
                            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                showCamera = true
                            } else {
                                showCameraUnavailable = true
                            }
                        } label: {
                            Label("Tomar foto", systemImage: "camera.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                        }
                        .buttonStyle(.borderedProminent)

                        PhotoPickerButton(image: $selectedImage)
                            .onChange(of: selectedImage) { _, newImage in
                                if newImage != nil { showScan = true }
                            }
                    }
                }

                Button { showText = true } label: {
                    GlassCard {
                        Label("Escribir pregunta", systemImage: "pencil.line")
                            .font(.headline)
                        Text("Ejemplo: Resuelve 3x + 6 = 15")
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                    }
                }
                .buttonStyle(.plain)

                NavigationLink { SubjectsView() } label: {
                    GlassCard {
                        Label("Elegir materia", systemImage: "books.vertical.fill")
                            .font(.headline)
                        Text("Matemáticas, física, química, biología, historia, idiomas y más.")
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .navigationTitle("Tarea Todóloga")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCamera) {
            CameraPicker { image in
                selectedImage = image
                showScan = true
            }
        }
        .navigationDestination(isPresented: $showScan) {
            if let image = selectedImage {
                ScanView(vm: SolverViewModel(app: app), initialImage: image)
            }
        }
        .navigationDestination(isPresented: $showText) {
            TextQuestionView(vm: SolverViewModel(app: app))
        }
        .alert("Cámara no disponible", isPresented: $showCameraUnavailable) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Puedes seleccionar una foto desde tu biblioteca.")
        }
    }
}
