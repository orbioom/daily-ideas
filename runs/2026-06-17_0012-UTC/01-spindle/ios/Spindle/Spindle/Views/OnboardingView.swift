import SwiftUI

/// First-run onboarding, gated by the persisted `hasOnboarded` flag.
struct OnboardingView: View {
    @Environment(\.colorScheme) private var scheme
    @AppStorage(PrefKey.hasOnboarded) private var hasOnboarded: Bool = false
    @State private var page = 0

    private struct Page: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let body: String
    }

    private let pages: [Page] = [
        Page(icon: "rectangle.portrait.on.rectangle.portrait.angled",
             title: "Welcome to Spindle",
             body: "A calm, ad-free Spider Solitaire. Build runs down from King to Ace and clear the table."),
        Page(icon: "rectangle.stack",
             title: "Move smart",
             body: "Tap a card to grab a same-suit run, tap a column to drop it, or double-tap to auto-move. Undo and Hint are always free."),
        Page(icon: "calendar",
             title: "Play the Daily Deal",
             body: "Everyone gets the same board each day. Chase your best score, track your streaks, and pick the felt that suits you.")
    ]

    var body: some View {
        ZStack {
            SpindleTheme.appBackground(scheme).ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, item in
                        pageView(item).tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                Button(page == pages.count - 1 ? "Start Playing" : "Next") {
                    if page < pages.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        hasOnboarded = true
                    }
                }
                .buttonStyle(SpindlePrimaryButtonStyle())
                .padding(.horizontal, 28)

                Button("Skip") { hasOnboarded = true }
                    .font(.subheadline)
                    .foregroundStyle(SpindleTheme.secondaryText(scheme))
                    .padding(.top, 10)
                    .padding(.bottom, 8)
            }
            .padding(.vertical, 24)
        }
    }

    private func pageView(_ item: Page) -> some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle().fill(SpindleTheme.emerald.opacity(0.14)).frame(width: 150, height: 150)
                Image(systemName: item.icon)
                    .font(.system(size: 68))
                    .foregroundStyle(SpindleTheme.emerald)
            }
            .accessibilityHidden(true)
            Text(item.title)
                .font(.title.weight(.bold))
                .foregroundStyle(SpindleTheme.primaryText(scheme))
                .multilineTextAlignment(.center)
            Text(item.body)
                .font(.body)
                .foregroundStyle(SpindleTheme.secondaryText(scheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}
