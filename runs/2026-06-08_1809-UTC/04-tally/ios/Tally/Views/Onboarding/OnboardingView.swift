import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("tally.onboarded") private var onboarded = false
    @AppStorage("tally.currency") private var currency = Locale.current.currency?.identifier ?? "USD"
    @State private var page = 0
    @State private var loadSample = true

    private let currencies = ["USD", "EUR", "GBP", "CAD", "AUD", "INR", "JPY", "BRL", "MXN", "ZAR", "NGN"]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                intro(icon: "wallet.bifold", title: "Money, made calm",
                      body: "Tally is a fast, private spending tracker. Log in seconds, see where it really goes.").tag(0)
                intro(icon: "chart.bar.fill", title: "Budgets that breathe",
                      body: "Set gentle monthly limits per category and watch them fill — never a nag, just clarity.").tag(1)
                setup.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            VStack(spacing: 10) {
                Button(page < 2 ? "Continue" : "Start") {
                    if page < 2 { withAnimation(Brand.ease()) { page += 1 } }
                    else { finish() }
                }
                .buttonStyle(InkButtonStyle())
            }
            .padding(.horizontal, 28).padding(.bottom, 26)
        }
    }

    private func intro(icon: String, title: String, body: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: icon).font(.system(size: 64, weight: .light))
                .foregroundStyle(Color(hex: 0x3E9E78)).accessibilityHidden(true)
            Text(title).font(.largeTitle.weight(.bold)).foregroundStyle(Brand.text).multilineTextAlignment(.center)
            Text(body).font(.body).foregroundStyle(Brand.text2)
                .multilineTextAlignment(.center).padding(.horizontal, 36)
            Spacer()
        }
        .padding()
    }

    private var setup: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("A couple of basics").font(.title.weight(.bold)).foregroundStyle(Brand.text)
            VStack(alignment: .leading, spacing: 14) {
                Text("Currency").font(.caption).foregroundStyle(Brand.text3)
                Picker("Currency", selection: $currency) {
                    ForEach(currencies, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)

                Toggle("Start with sample data", isOn: $loadSample)
                    .tint(Color(hex: 0x3E9E78))
                Text("You can erase everything anytime in Settings.")
                    .font(.caption).foregroundStyle(Brand.text3)
            }
            .padding()
            .glassCard()
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
