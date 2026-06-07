import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Panel: Identifiable {
        let id = UUID()
        let icon: String, eyebrow: String, title: String, body: String
    }

    private let panels: [Panel] = [
        .init(icon: "stopwatch", eyebrow: "Caliber",
              title: "Know your watch to the second",
              body: "Log how many seconds fast or slow each watch reads against a reference. Caliber fits a line through your readings and tells you the true daily rate."),
        .init(icon: "rectangle.stack", eyebrow: "Collection",
              title: "Every piece, graded",
              body: "See each watch ranked from chronometer to needs-regulation, with its drift charted over time — a timegrapher built from how you actually wear it."),
        .init(icon: "wrench.and.screwdriver", eyebrow: "Service",
              title: "Never miss a service",
              body: "Caliber counts down from each watch's last service so you know what's due — and which position runs fastest on the wrist.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(panels.enumerated()), id: \.offset) { idx, p in
                    VStack(spacing: 22) {
                        Spacer()
                        Image(systemName: p.icon)
                            .font(.system(size: 64, weight: .light))
                            .foregroundStyle(Brand.text).accessibilityHidden(true)
                        VStack(spacing: 12) {
                            Eyebrow(text: p.eyebrow)
                            Text(p.title).font(.largeTitle.weight(.bold))
                                .foregroundStyle(Brand.text).multilineTextAlignment(.center)
                            Text(p.body).font(.body).foregroundStyle(Brand.text2)
                                .multilineTextAlignment(.center).padding(.horizontal, 8)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 28).tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            VStack(spacing: 12) {
                Button(page < panels.count - 1 ? "Continue" : "Open the case") {
                    Haptics.tap()
                    if page < panels.count - 1 {
                        withAnimation(reduceMotion ? nil : Brand.ease()) { page += 1 }
                    } else { onFinish() }
                }
                .buttonStyle(InkButtonStyle())
                if page < panels.count - 1 {
                    Button("Skip") { onFinish() }
                        .font(.subheadline).foregroundStyle(Brand.text3)
                }
            }
            .padding(.horizontal, 24).padding(.bottom, 28)
        }
        .background(Brand.pageBackground)
    }
}
