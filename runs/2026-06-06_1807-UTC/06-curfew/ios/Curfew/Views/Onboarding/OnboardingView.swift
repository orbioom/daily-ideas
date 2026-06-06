import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("bedtimeHour") private var bedtimeHour = 23
    @AppStorage("halfLifeHours") private var halfLife = 5.0
    @State private var appear = false
    @State private var bedtime = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: .now) ?? .now

    private let pages: [(icon: String, title: String, body: String)] = [
        ("cup.and.saucer", "Log what you drink",
         "Tap a favorite or add a custom drink. Curfew tracks the milligrams, not just the cups."),
        ("waveform.path.ecg", "Watch it fade",
         "Caffeine halves every few hours. Curfew models the curve so you always know what's still in you."),
        ("moon.stars", "Protect your sleep",
         "Set a bedtime and Curfew tells you the last safe time for that next coffee."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(alignment: .leading, spacing: 22) {
                Eyebrow(text: "Curfew")
                Text("Caffeine, on a clock.")
                    .font(.system(.largeTitle, design: .default, weight: .semibold))
                    .foregroundStyle(Brand.text)
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { idx, page in
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: page.icon).font(.title2).foregroundStyle(Brand.text)
                                .frame(width: 32).accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(page.title).font(.headline).foregroundStyle(Brand.text)
                                Text(page.body).font(.subheadline).foregroundStyle(Brand.text2)
                            }
                        }
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear || reduceMotion ? 0 : 16)
                        .animation(Brand.ease(0.5).delay(Double(idx) * 0.08), value: appear)
                    }
                }
                DatePicker("Your usual bedtime", selection: $bedtime, displayedComponents: .hourAndMinute)
                    .font(.subheadline)
            }
            .padding(28).glassCard(padding: 24).padding(.horizontal, 20)
            Spacer()
            Button("Start") {
                bedtimeHour = Calendar.current.component(.hour, from: bedtime)
                onFinish()
            }
            .buttonStyle(InkButtonStyle()).padding(.horizontal, 20).padding(.bottom, 24)
        }
        .onAppear { appear = true }
    }
}
