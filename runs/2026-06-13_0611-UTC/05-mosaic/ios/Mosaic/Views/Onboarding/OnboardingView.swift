import SwiftUI
import SwiftData

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0
    @State private var loadSample = true

    private let pages: [(String, String, String)] = [
        ("square.grid.3x3.fill", "One day, one tile",
         "Mosaic turns your year into a grid of colored days. A glance shows you the whole shape of your life."),
        ("camera", "A photo and a feeling",
         "Each day, capture one moment and one mood. Thirty seconds is all it takes to keep the streak alive."),
        ("clock.arrow.circlepath", "Watch it fill in",
         "Revisit “on this day” memories and your year-in-pixels grid. Everything stays private, on your device.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack {
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        VStack(spacing: 24) {
                            Spacer()
                            ZStack {
                                Circle().fill(Theme.accent.opacity(0.15)).frame(width: 150, height: 150)
                                Image(systemName: pages[i].0).font(.system(size: 58, weight: .light))
                                    .foregroundStyle(Theme.accent).accessibilityHidden(true)
                            }
                            Text(pages[i].1).font(Theme.rounded(28)).foregroundStyle(Theme.ink)
                                .multilineTextAlignment(.center)
                            Text(pages[i].2).font(.system(size: 17)).foregroundStyle(Theme.inkSoft)
                                .multilineTextAlignment(.center).padding(.horizontal, 36)
                            if i == pages.count - 1 {
                                Toggle("Fill in sample months to explore", isOn: $loadSample)
                                    .padding(.horizontal, 40).tint(Theme.accent).font(.system(size: 15))
                            }
                            Spacer(); Spacer()
                        }.tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                Button {
                    if page < pages.count - 1 { withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 } }
                    else { start() }
                } label: {
                    Text(page < pages.count - 1 ? "Continue" : "Start my mosaic")
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
        if loadSample {
            let count = (try? context.fetchCount(FetchDescriptor<DayEntry>())) ?? 0
            if count == 0 { SeedData.populate(context) }
        }
        Haptics.success()
        hasOnboarded = true
    }
}
