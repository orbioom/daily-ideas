import SwiftUI

struct OnboardingView: View {
    @Binding var done: Bool
    @AppStorage("luna.defaultCycle") private var defaultCycle = 28
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pages: [(symbol: String, title: String, body: String)] = [
        ("moon.stars.fill", "Your cycle, understood",
         "Log your period in a tap and Luna learns your rhythm — predicting your next period, fertile window, and ovulation."),
        ("lock.shield.fill", "Private by design",
         "No account, no cloud, no data sales. Everything you log stays on your iPhone. The opposite of the big period apps."),
        ("calendar", "See the whole month",
         "A calm calendar shows logged and predicted days, plus symptoms and mood patterns over time."),
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
                                .foregroundStyle(Brand.inkGradient).accessibilityHidden(true)
                            Text(pages[i].title).font(.largeTitle.weight(.bold))
                                .foregroundStyle(Brand.text).multilineTextAlignment(.center)
                            Text(pages[i].body).font(.body).foregroundStyle(Brand.text2)
                                .multilineTextAlignment(.center).padding(.horizontal, 28)
                            if i == pages.count - 1 {
                                Stepper(value: $defaultCycle, in: 20...40) {
                                    HStack { Text("Usual cycle length"); Spacer()
                                        Text("\(defaultCycle) days").font(Brand.mono(15)).foregroundStyle(Brand.text2) }
                                }
                                .padding(.horizontal, 40).padding(.top, 8)
                            }
                        }
                        .tag(i).padding()
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 400)
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
