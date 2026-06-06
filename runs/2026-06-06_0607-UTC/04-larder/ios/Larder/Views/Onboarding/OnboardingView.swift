import SwiftUI

/// First-run welcome. Three calm pages explaining the larder, then a single ink CTA
/// that sets the persisted `hasOnboarded` flag. Honors Reduce Motion.
struct OnboardingView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private struct Panel {
        var icon: String
        var title: String
        var body: String
    }

    private let panels: [Panel] = [
        Panel(icon: "cabinet.fill",
              title: "Your whole larder, at a glance",
              body: "Track what you have, where it lives, and how much is left — across the pantry, fridge, freezer, and any shelf you like."),
        Panel(icon: "clock.badge.exclamationmark.fill",
              title: "Know what's about to go off",
              body: "Larder buckets everything by date, so you can use things before they expire and waste a little less."),
        Panel(icon: "cart.fill",
              title: "A shopping list that writes itself",
              body: "Items at or below their low-stock level join your list automatically. Check one off and it restocks straight back in.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(panels.enumerated()), id: \.offset) { index, panel in
                    panelView(panel)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            VStack(spacing: 12) {
                InkButton(title: page == panels.count - 1 ? "Get Started" : "Continue",
                          systemImage: page == panels.count - 1 ? "checkmark" : "arrow.right") {
                    advance()
                }
                Button("Skip") { finish() }
                    .font(.subheadline)
                    .tint(Brand.text2)
                    .opacity(page == panels.count - 1 ? 0 : 1)
                    .disabled(page == panels.count - 1)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
    }

    private func panelView(_ panel: Panel) -> some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Brand.glassStroke.opacity(0.25))
                    .frame(width: 132, height: 132)
                Image(systemName: panel.icon)
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(Brand.text)
            }
            .accessibilityHidden(true)
            VStack(spacing: 12) {
                Text(panel.title)
                    .font(.title.weight(.bold))
                    .foregroundStyle(Brand.text)
                    .multilineTextAlignment(.center)
                Text(panel.body)
                    .font(.body)
                    .foregroundStyle(Brand.text2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)
            Spacer()
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    private func advance() {
        if page < panels.count - 1 {
            withAnimation(reduceMotion ? nil : Brand.ease()) { page += 1 }
        } else {
            finish()
        }
    }

    private func finish() {
        Haptics.success(enabled: settings.hapticsEnabled)
        settings.hasOnboarded = true
    }
}

#Preview {
    OnboardingView()
        .environment(SettingsStore())
        .background(Brand.pageBackground)
}
