import SwiftUI
import SwiftData

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let pages: [(symbol: String, title: String, body: String)] = [
        ("text.justify.left", "Think in writing",
         "Verso is a calm, fast home for your notes — plain Markdown that stays readable for decades."),
        ("link", "Connect your ideas",
         "Link any note to another with [[double brackets]] and Verso builds the backlinks automatically."),
        ("lock.open", "Yours, forever",
         "Notes live on your device. No account, no monthly fee to read your own words — a one-time unlock when you're ready.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        VStack(spacing: 26) {
                            Spacer()
                            ZStack {
                                Circle().fill(Theme.accentSoft).frame(width: 150, height: 150)
                                Image(systemName: pages[i].symbol)
                                    .font(.system(size: 60, weight: .light))
                                    .foregroundStyle(Theme.accent)
                                    .accessibilityHidden(true)
                            }
                            Text(pages[i].title)
                                .font(Theme.serifTitle(30))
                                .foregroundStyle(Theme.ink)
                                .multilineTextAlignment(.center)
                            Text(pages[i].body)
                                .font(.system(size: 17))
                                .foregroundStyle(Theme.inkSoft)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 36)
                            Spacer(); Spacer()
                        }
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                Button {
                    if page < pages.count - 1 {
                        withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 }
                    } else {
                        start()
                    }
                } label: {
                    Text(page < pages.count - 1 ? "Continue" : "Start writing")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.accent))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 14)

                Button("Skip") { start() }
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.inkFaint)
                    .padding(.bottom, 20)
                    .opacity(page < pages.count - 1 ? 1 : 0)
            }
        }
    }

    private func start() {
        // Seed sample content once.
        let count = (try? context.fetchCount(FetchDescriptor<Note>())) ?? 0
        if count == 0 { SeedData.populate(context) }
        Haptics.success()
        hasOnboarded = true
    }
}
