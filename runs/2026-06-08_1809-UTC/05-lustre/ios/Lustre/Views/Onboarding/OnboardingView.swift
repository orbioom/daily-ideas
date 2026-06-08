import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("lustre.onboarded") private var onboarded = false
    @State private var page = 0
    @State private var loadSample = true

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                intro("sparkles", "Your shelf, in order",
                      "Lustre keeps your skincare routine, your product shelf, and your skin in one calm place.").tag(0)
                intro("clock.badge.checkmark", "Never use it expired",
                      "Track when each product was opened and Lustre warns you before it turns.").tag(1)
                last.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button(page < 2 ? "Continue" : "Start glowing") {
                if page < 2 { withAnimation(Brand.ease()) { page += 1 } }
                else { finish() }
            }
            .buttonStyle(InkButtonStyle())
            .padding(.horizontal, 28).padding(.bottom, 26)
        }
    }

    private func intro(_ icon: String, _ title: String, _ body: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: icon).font(.system(size: 64, weight: .light))
                .foregroundStyle(Color(hex: 0x9E7BA8)).accessibilityHidden(true)
            Text(title).font(.largeTitle.weight(.bold)).foregroundStyle(Brand.text).multilineTextAlignment(.center)
            Text(body).font(.body).foregroundStyle(Brand.text2)
                .multilineTextAlignment(.center).padding(.horizontal, 36)
            Spacer()
        }
        .padding()
    }

    private var last: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "cabinet").font(.system(size: 56, weight: .light))
                .foregroundStyle(Color(hex: 0x9E7BA8)).accessibilityHidden(true)
            Text("Start with a sample shelf?").font(.title2.weight(.bold)).foregroundStyle(Brand.text)
            Toggle("Add a sample routine & products", isOn: $loadSample)
                .tint(Color(hex: 0x9E7BA8))
                .padding().glassCard()
            Text("You can edit or erase anything later.")
                .font(.caption).foregroundStyle(Brand.text3)
            Spacer()
        }
        .padding()
    }

    private func finish() {
        if loadSample { SeedData.seed(context) }
        Haptics.success()
        onboarded = true
    }
}
