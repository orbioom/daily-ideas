import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var preferences: [AppPreferences]
    @Environment(\.modelContext) private var modelContext

    var prefs: AppPreferences {
        if let p = preferences.first { return p }
        let p = AppPreferences()
        modelContext.insert(p)
        return p
    }

    var body: some View {
        MainMenuView()
    }
}
