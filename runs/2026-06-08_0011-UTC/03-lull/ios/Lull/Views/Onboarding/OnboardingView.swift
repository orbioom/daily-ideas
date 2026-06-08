import SwiftUI

struct OnboardingView: View {
    @Binding var done: Bool
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pages: [(symbol: String, title: String, body: String)] = [
        ("wind", "Breathe with the orb",
         "Lull guides each breath with a calm, growing orb — in as it expands, out as it settles. No counting in your head."),
        ("square.on.square", "Patterns for any moment",
         "Box breathing to focus, 4-7-8 to sleep, coherent breathing to steady. Or shape your own."),
        ("moon.stars.fill", "A quiet daily habit",
         "Short sessions build a streak and minutes you can see. Everything stays private on your device."),
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
                                .font(.system(size: 64, weight: .light))
                                .foregroundStyle(Brand.inkGradient)
                                .accessibilityHidden(true)
                            Text(pages[i].title)
                                .font(.largeTitle.weight(.bold))
                                .foregroundStyle(Brand.text)
                                .multilineTextAlignment(.center)
                            Text(pages[i].body)
                                .font(.body).foregroundStyle(Brand.text2)
                                .multilineTextAlignment(.center).padding(.horizontal, 28)
                        }
                        .tag(i).padding()
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 360)
                Spacer()
                Button(page == pages.count - 1 ? "Begin" : "Continue") {
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
