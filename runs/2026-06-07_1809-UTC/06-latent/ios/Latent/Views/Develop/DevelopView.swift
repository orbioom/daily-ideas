import SwiftUI
import SwiftData

/// The Develop tab. If a run is already active (e.g. after relaunch), it jumps
/// straight to the full-screen timer; otherwise it shows the setup screen.
struct DevelopView: View {
    @EnvironmentObject private var timer: TimerEngine

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if timer.isActive {
                    TimerView()
                } else {
                    DevelopSetupView(prefill: nil)
                }
            }
            .navigationTitle(timer.isActive ? "Developing" : "Develop")
            .navigationBarTitleDisplayMode(timer.isActive ? .inline : .large)
        }
    }
}

/// Values used to prefill the develop setup from a recipe.
struct DevelopPrefill {
    let recipe: Recipe
}
