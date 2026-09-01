import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var app: AppContainer
    @State private var token = ""
    @State private var showDelete = false
    @State private var savedMessage = false

    var body: some View {
        Form {
            Section("Preferencias") {
                Picker("Idioma", selection: $app.settings.language) {
                    ForEach(AppLanguage.allCases) { Text($0.rawValue).tag($0) }
                }
                Toggle("Modo oscuro", isOn: $app.settings.useDarkMode)
                Picker("Nivel de explicación", selection: $app.settings.explanationLevel) {
                    ForEach(ExplanationLevel.allCases) { Text($0.rawValue).tag($0) }
                }
                Toggle("Guardar imágenes localmente", isOn: $app.settings.saveImagesLocally)
            }

            Section("IA") {
                Toggle("Permitir enviar imágenes", isOn: $app.settings.allowRemoteImages)
                TextField("Endpoint de tu backend", text: $app.settings.apiEndpoint)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                SecureField("Token del backend", text: $token)
                Button("Guardar token") {
                    do {
                        try app.keychain.setToken(token)
                        token = ""
                        savedMessage = true
                    } catch { savedMessage = false }
                }
                Text("No pongas una API key de OpenAI, Gemini u otro proveedor dentro de la app. Usa un backend propio y guarda aquí solo un token de acceso al backend.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Privacidad") {
                Button("Borrar historial y fotos", role: .destructive) { showDelete = true }
            }

            Section("Estado") {
                Label(app.settings.apiEndpoint.isEmpty ? "IA local de demostración" : "Backend de IA configurado", systemImage: app.settings.apiEndpoint.isEmpty ? "cpu" : "cloud.fill")
                if savedMessage { Text("Token guardado de forma segura en Keychain.").foregroundStyle(.green) }
            }
        }
        .navigationTitle("Ajustes")
        .alert("¿Borrar todo?", isPresented: $showDelete) {
            Button("Cancelar", role: .cancel) {}
            Button("Borrar", role: .destructive) { app.clearHistory() }
        } message: {
            Text("Se eliminarán las tareas guardadas y las imágenes locales.")
        }
    }
}
