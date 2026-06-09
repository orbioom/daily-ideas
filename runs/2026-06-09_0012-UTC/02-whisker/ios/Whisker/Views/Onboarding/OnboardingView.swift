import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("whisker.onboarded") private var onboarded = false
    @State private var page = 0

    private let pages: [(icon: String, title: String, body: String)] = [
        ("pawprint.fill", "Every pet, in one calm place",
         "Whisker keeps weight, vet visits, meds and routines for all your animals — private and on this device."),
        ("checklist", "Never miss the recurring stuff",
         "Set up feeding, flea & tick, grooming and check-ups once. Whisker tells you what's due and reschedules with a tap."),
        ("chart.xyaxis.line", "Watch their health over time",
         "Log weights and symptoms; spot trends early with clear charts you actually understand.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { i in
                    VStack(spacing: 22) {
                        Spacer()
                        Image(systemName: pages[i].icon)
                            .font(.system(size: 70, weight: .light))
                            .foregroundStyle(Brand.magic)
                            .accessibilityHidden(true)
                        Text(pages[i].title)
                            .font(.title.weight(.bold))
                            .foregroundStyle(Brand.text)
                            .multilineTextAlignment(.center)
                        Text(pages[i].body)
                            .font(.body)
                            .foregroundStyle(Brand.text2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                        Spacer()
                    }
                    .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack(spacing: 12) {
                Button(page == pages.count - 1 ? "Get started" : "Continue") {
                    if page == pages.count - 1 {
                        Haptics.success()
                        onboarded = true
                    } else {
                        withAnimation(Brand.ease()) { page += 1 }
                    }
                }
                .buttonStyle(InkButtonStyle())

                if page == pages.count - 1 {
                    Button("Explore with sample pets") {
                        SeedData.loadSample(context)
                        Haptics.success()
                        onboarded = true
                    }
                    .buttonStyle(GlassButtonStyle())
                }

                HStack(spacing: 7) {
                    ForEach(pages.indices, id: \.self) { i in
                        Circle().fill(i == page ? Brand.text : Brand.text3.opacity(0.4))
                            .frame(width: 7, height: 7)
                    }
                }
                .accessibilityHidden(true)
            }
        }
        .padding(24)
    }
}
