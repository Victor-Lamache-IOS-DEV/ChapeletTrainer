import SwiftUI
import SwiftData

public struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext

    public init() {}

    public var body: some View {
        TabView {
            ChapeletView()
                .tabItem {
                    Label("Chapelet", systemImage: "square.grid.2x2")
                }

            IndicesView()
                .tabItem {
                    Label("Indices", systemImage: "lightbulb.fill")
                }

            TestRootView()
                .tabItem {
                    Label("Test", systemImage: "play.circle.fill")
                }

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.xaxis")
                }
        }
        .tint(Color.accentColor)
        .onAppear {
            DeckStore.ensureInitialized(modelContext: modelContext)
            Haptics.shared.prepare()
        }
    }
}
