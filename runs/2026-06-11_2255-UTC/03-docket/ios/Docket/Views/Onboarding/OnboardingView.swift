import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var page = 0

    private let pages: [(icon: String, title: String, message: String)] = [
        ("doc.viewfinder", "Scan anything, instantly",
         "Receipts, contracts, IDs, whiteboards — Docket's document camera finds the edges, straightens the page, and files it."),
        ("text.viewfinder", "Every word, searchable",
         "On-device text recognition reads each page, so you can find \u{201C}that invoice from March\u{201D} by typing any word on it."),
        ("lock.shield", "Private by architecture",
         "No account. No cloud. No upsells on your own paperwork. Scans live in this app's sandbox and export as clean PDFs."),
    ]

    var body: some View {
        ZStack {
            Theme.bgPrimary.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                        VStack(spacing: 22) {
                            Image(systemName: item.icon)
                                .font(.system(size: 64, weight: .light))
                                .foregroundStyle(Theme.accent)
                                .accessibilityHidden(true)
                            Text(item.title)
                                .font(.largeTitle.weight(.bold))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Theme.textPrimary)
                            Text(item.message)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Theme.textSecondary)
                                .padding(.horizontal, 32)
                        }
                        .tag(index)
                        .padding(.bottom, 60)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                Button {
                    if page < pages.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        Haptics.success()
                        hasOnboarded = true
                    }
                } label: {
                    Text(page < pages.count - 1 ? "Continue" : "Start scanning")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
                .accessibilityHint(page < pages.count - 1 ? "Shows the next page" : "Finishes onboarding")
            }
        }
    }
}
