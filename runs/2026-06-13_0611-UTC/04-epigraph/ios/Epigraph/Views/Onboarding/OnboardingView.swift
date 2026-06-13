import SwiftUI
import SwiftData

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let pages: [(String, String, String)] = [
        ("quote.opening", "Keep what moves you",
         "Epigraph is a commonplace book — a home for the lines worth remembering from everything you read."),
        ("books.vertical", "Organized by book",
         "Save highlights under each title, annotate them in your own words, and tag the themes that run between them."),
        ("arrow.triangle.2.circlepath", "Resurfaced daily",
         "A quote a day, plus a short review that brings old highlights back — so your reading keeps working on you. No subscription.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack {
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        VStack(spacing: 26) {
                            Spacer()
                            ZStack {
                                Circle().fill(Theme.accentSoft).frame(width: 150, height: 150)
                                Image(systemName: pages[i].0).font(.system(size: 58, weight: .light))
                                    .foregroundStyle(Theme.accent).accessibilityHidden(true)
                            }
                            Text(pages[i].1).font(Theme.serif(30, .bold)).foregroundStyle(Theme.ink)
                                .multilineTextAlignment(.center)
                            Text(pages[i].2).font(.system(size: 17)).foregroundStyle(Theme.inkSoft)
                                .multilineTextAlignment(.center).padding(.horizontal, 36)
                            Spacer(); Spacer()
                        }.tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                Button {
                    if page < pages.count - 1 { withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 } }
                    else { start() }
                } label: {
                    Text(page < pages.count - 1 ? "Continue" : "Begin")
                        .font(.system(size: 17, weight: .semibold)).frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.accent))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 24).padding(.bottom, 20)
            }
        }
    }

    private func start() {
        let count = (try? context.fetchCount(FetchDescriptor<Book>())) ?? 0
        if count == 0 { SeedData.populate(context) }
        Haptics.success()
        hasOnboarded = true
    }
}
