import SwiftUI
import SwiftData

@main
struct ChapeletTrainerApp: App {
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([
                CardProgress.self,
                TestSession.self
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])

            // Initialiser les 52 cartes du chapelet si premier lancement
            Task { @MainActor in
                DeckStore.ensureInitialized(modelContext: container.mainContext)
            }
        } catch {
            fatalError("Impossible d'initialiser le conteneur SwiftData : \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(container)
    }
}
