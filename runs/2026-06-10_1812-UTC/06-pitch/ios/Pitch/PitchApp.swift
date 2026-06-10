import SwiftUI
import SwiftData

@main
struct PitchApp: App {
    let container: ModelContainer
    @StateObject private var tone = ToneEngine.shared
    @StateObject private var audioInput = AudioInput()

    init() {
        let schema = Schema([CustomTuning.self, MetronomePreset.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        if let c = try? ModelContainer(for: schema, configurations: config) {
            container = c
        } else {
            let mem = ModelConfiguration(isStoredInMemoryOnly: true)
            container = (try? ModelContainer(for: schema, configurations: mem))
                ?? { fatalError("Unable to create in-memory ModelContainer") }()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(tone)
                .environmentObject(audioInput)
        }
        .modelContainer(container)
    }
}
