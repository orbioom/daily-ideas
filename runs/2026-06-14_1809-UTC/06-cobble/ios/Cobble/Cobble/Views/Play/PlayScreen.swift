import SwiftUI

/// The Classic tab: an endless seeded game that resumes on relaunch.
struct PlayScreen: View {
    var body: some View {
        NavigationStack {
            GamePlayView(mode: .classic)
                .navigationTitle("Classic")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}
