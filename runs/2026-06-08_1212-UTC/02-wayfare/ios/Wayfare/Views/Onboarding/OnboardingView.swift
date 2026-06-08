import SwiftUI
import SwiftData

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var page = 0
    @State private var includeSample = true
    @State private var drift = false

    private let pages: [(symbol: String, title: String, body: String)] = [
        ("map.fill", "Plan it once, clearly",
         "Wayfare keeps every trip in one calm place — a day-by-day itinerary you can actually read at a glance."),
        ("bed.double.fill", "Know where you sleep",
         "See exactly which place covers each night, and spot gaps before you're standing in a station at midnight."),
        ("eurosign.circle.fill", "Stay on budget, no nagging",
         "Track spend by category against a budget you set. No pop-ups, no upsells — it's all on your device."),
    ]

    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 0) {
                Spacer()
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        VStack(spacing: 24) {
                            ZStack {
                                Circle().fill(.ultraThinMaterial)
                                    .frame(width: 150, height: 150)
                                    .overlay(Circle().strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
                                    .offset(y: drift && !reduceMotion ? -6 : 6)
                                Image(systemName: pages[i].symbol)
                                    .font(.system(size: 54, weight: .light))
                                    .foregroundStyle(Color.accentColor)
                                    .accessibilityHidden(true)
                            }
                            VStack(spacing: 12) {
                                Text(pages[i].title)
                                    .font(.title.weight(.bold))
                                    .foregroundStyle(Brand.text)
                                    .multilineTextAlignment(.center)
                                Text(pages[i].body)
                                    .font(.body)
                                    .foregroundStyle(Brand.text2)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                        }
                        .padding()
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 420)
                Spacer()
                VStack(spacing: 16) {
                    if page == pages.count - 1 {
                        Toggle(isOn: $includeSample) {
                            Text("Load an example trip to explore")
                                .font(.subheadline).foregroundStyle(Brand.text2)
                        }
                        .tint(Color.accentColor)
                    }
                    Button(page == pages.count - 1 ? "Start planning" : "Continue") {
                        Haptics.tap()
                        if page < pages.count - 1 {
                            withAnimation(Brand.ease()) { page += 1 }
                        } else {
                            if includeSample { SeedData.populate(context) }
                            withAnimation(Brand.ease()) { hasOnboarded = true }
                        }
                    }
                    .buttonStyle(InkButtonStyle())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) { drift = true }
        }
    }
}
