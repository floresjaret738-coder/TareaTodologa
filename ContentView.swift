import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var app: AppContainer

    var body: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem { Label("Inicio", systemImage: "house.fill") }
            NavigationStack { SubjectsView() }
                .tabItem { Label("Materias", systemImage: "books.vertical.fill") }
            NavigationStack { HistoryView() }
                .tabItem { Label("Historial", systemImage: "clock.arrow.circlepath") }
            NavigationStack { FavoritesView() }
                .tabItem { Label("Favoritos", systemImage: "star.fill") }
            NavigationStack { SettingsView() }
                .tabItem { Label("Ajustes", systemImage: "gearshape.fill") }
        }
        .tint(.indigo)
    }
}
