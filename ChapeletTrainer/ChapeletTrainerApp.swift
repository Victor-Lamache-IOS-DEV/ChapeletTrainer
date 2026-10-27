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
            let newContainer = try ModelContainer(for: schema, configurations: [config])
            self.container = newContainer
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
