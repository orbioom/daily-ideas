import SwiftUI

/// App-wide calm gradient background that adapts to light/dark.
struct DriftBackground: View {
    var body: some View {
        Theme.backgroundPrimary
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [Theme.dusk.opacity(0.18), .clear],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()
            }
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}
