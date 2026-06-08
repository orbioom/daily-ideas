import SwiftUI

struct OnboardingView: View {
    @Binding var done: Bool
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pages: [(symbol: String, title: String, body: String)] = [
        ("tree.fill", "Plant focus, grow a grove",
         "Set a timer and a tree starts growing. Stay focused for the full block and it takes root in your grove."),
        ("hand.raised.fill", "Leave and it withers",
         "Switch away from Grove mid-session and your tree wilts. A gentle stake in the ground that keeps you present."),
        ("chart.bar.doc.horizontal.fill", "Watch the forest fill in",
         "Every block adds focused minutes, a streak, and a tree. Tag sessions to see where your attention really goes."),
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
                        }
                        .tag(i).padding()
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 360)
                Spacer()
                Button(page == pages.count - 1 ? "Plant your first tree" : "Continue") {
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
