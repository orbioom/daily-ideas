import SwiftUI

struct OnboardingView: View {
    @Binding var done: Bool
    @AppStorage("tare.unit") private var unitRaw = WeightUnit.kg.rawValue
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pages: [(symbol: String, title: String, body: String)] = [
        ("scalemass.fill", "Weigh in, calmly",
         "Daily weight bounces with water, food, and sleep. Tare reads through the noise so a bad morning doesn't ruin your week."),
        ("chart.line.downtrend.xyaxis", "See the real trend",
         "A smoothed trend line shows where you're actually heading — then projects when you'll reach your goal at your current pace."),
        ("lock.fill", "Yours alone",
         "No account, no cloud, no ads. Your weight history never leaves this device."),
    ]

    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 0) {
                Spacer()
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        VStack(spacing: 22) {
                            Image(systemName: pages[i].symbol)
                                .font(.system(size: 60, weight: .light))
                                .foregroundStyle(Brand.inkGradient)
                                .accessibilityHidden(true)
                            Text(pages[i].title).font(.largeTitle.weight(.bold))
                                .foregroundStyle(Brand.text).multilineTextAlignment(.center)
                            Text(pages[i].body).font(.body).foregroundStyle(Brand.text2)
                                .multilineTextAlignment(.center).padding(.horizontal, 28)
                            if i == pages.count - 1 {
                                Picker("Units", selection: $unitRaw) {
                                    ForEach(WeightUnit.allCases) { Text($0.short).tag($0.rawValue) }
                                }
                                .pickerStyle(.segmented).padding(.horizontal, 40).padding(.top, 8)
                            }
                        }
                        .tag(i).padding()
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 380)
                Spacer()
                Button(page == pages.count - 1 ? "Start tracking" : "Continue") {
                    if page == pages.count - 1 {
                        Haptics.success()
                        withAnimation(reduceMotion ? nil : Brand.ease()) { done = true }
                    } else {
                        withAnimation(reduceMotion ? nil : Brand.ease()) { page += 1 }
                    }
                }
                .buttonStyle(InkButtonStyle())
                .padding(.horizontal, 24).padding(.bottom, 20)
            }
        }
    }
}
