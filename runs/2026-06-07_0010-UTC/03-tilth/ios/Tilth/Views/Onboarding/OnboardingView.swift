import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void
    @State private var page = 0
    @State private var springFrost = FrostMath.date(month: 5, day: 10, year: Season.currentYear)
    @State private var fallFrost = FrostMath.date(month: 10, day: 10, year: Season.currentYear)
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                intro.tag(0)
                frostSetup.tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            VStack(spacing: 12) {
                Button(page == 0 ? "Set my frost dates" : "Start planning") {
                    Haptics.tap()
                    if page == 0 {
                        withAnimation(reduceMotion ? nil : Brand.ease()) { page = 1 }
                    } else {
                        persist(); onFinish()
                    }
                }
                .buttonStyle(InkButtonStyle())
            }
            .padding(.horizontal, 24).padding(.bottom, 28)
        }
        .background(Brand.pageBackground)
    }

    private var intro: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: "leaf").font(.system(size: 64, weight: .light))
                .foregroundStyle(Brand.live).accessibilityHidden(true)
            VStack(spacing: 12) {
                Eyebrow(text: "Tilth")
                Text("Plant on the right week, every week")
                    .font(.largeTitle.weight(.bold)).foregroundStyle(Brand.text)
                    .multilineTextAlignment(.center)
                Text("Tilth turns your two frost dates into a sowing calendar — when to start seeds, set them out, sow the next succession, and harvest before the cold returns.")
                    .font(.body).foregroundStyle(Brand.text2)
                    .multilineTextAlignment(.center).padding(.horizontal, 12)
            }
            Spacer()
        }
        .padding(.horizontal, 28)
    }

    private var frostSetup: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "snowflake").font(.system(size: 48, weight: .light))
                .foregroundStyle(Brand.info).accessibilityHidden(true)
            Text("Your frost dates")
                .font(.title.weight(.bold)).foregroundStyle(Brand.text)
            Text("Everything Tilth schedules is relative to these two dates. You can change them any time in Settings.")
                .font(.subheadline).foregroundStyle(Brand.text2)
                .multilineTextAlignment(.center).padding(.horizontal, 20)
            VStack(spacing: 14) {
                DatePicker("Last spring frost", selection: $springFrost, displayedComponents: .date)
                DatePicker("First fall frost", selection: $fallFrost, displayedComponents: .date)
            }
            .glassCard(padding: 18)
            .padding(.horizontal, 20)
            Text("\(FrostMath.daysBetween(springFrost, fallFrost)) frost-free days")
                .font(Brand.mono(14, weight: .medium)).foregroundStyle(Brand.live)
            Spacer()
        }
        .padding(.horizontal, 8)
    }

    private func persist() {
        let cal = Calendar.current
        let s = cal.dateComponents([.month, .day], from: springFrost)
        let f = cal.dateComponents([.month, .day], from: fallFrost)
        let d = UserDefaults.standard
        d.set(s.month ?? 5, forKey: Season.Keys.springMonth)
        d.set(s.day ?? 10, forKey: Season.Keys.springDay)
        d.set(f.month ?? 10, forKey: Season.Keys.fallMonth)
        d.set(f.day ?? 10, forKey: Season.Keys.fallDay)
    }
}
