import SwiftUI
import SwiftData

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("currentBalance") private var currentBalance = 0.0
    @AppStorage("balanceAsOf") private var balanceAsOf = 0.0
    @AppStorage("buffer") private var buffer = 100.0
    @AppStorage("currencyCode") private var currencyCode = Locale.current.currency?.identifier ?? "USD"
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0
    @State private var balanceText = ""
    @State private var loadSample = true

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack {
                TabView(selection: $page) {
                    intro(symbol: "chart.line.uptrend.xyaxis",
                          title: "Know your runway",
                          body: "Runway projects your checking balance day by day, so you can see exactly how far your money stretches before the next payday.")
                        .tag(0)
                    intro(symbol: "checkmark.shield",
                          title: "One honest number",
                          body: "It tells you what's truly safe to spend today after every upcoming bill — no bank login, no data leaving your phone.")
                        .tag(1)
                    balanceStep.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                Button {
                    if page < 2 { withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 } }
                    else { finish() }
                } label: {
                    Text(page < 2 ? "Continue" : "See my runway")
                        .font(.system(size: 17, weight: .bold)).frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.accent))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 24).padding(.bottom, 20)
            }
        }
    }

    private func intro(symbol: String, title: String, body: String) -> some View {
        VStack(spacing: 26) {
            Spacer()
            ZStack {
                Circle().fill(Theme.accent.opacity(0.16)).frame(width: 150, height: 150)
                Image(systemName: symbol).font(.system(size: 60, weight: .medium))
                    .foregroundStyle(Theme.accent).accessibilityHidden(true)
            }
            Text(title).font(Theme.num(30)).foregroundStyle(Theme.ink).multilineTextAlignment(.center)
            Text(body).font(.system(size: 17)).foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center).padding(.horizontal, 36)
            Spacer(); Spacer()
        }
    }

    private var balanceStep: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("What's in your account now?")
                .font(Theme.num(24)).foregroundStyle(Theme.ink).multilineTextAlignment(.center)
            Text("Your current checking balance. You can change it any time.")
                .font(.system(size: 14)).foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center).padding(.horizontal, 30)
            HStack {
                Text(currencySymbol).font(Theme.num(30)).foregroundStyle(Theme.inkSoft)
                TextField("0", text: $balanceText)
                    .keyboardType(.decimalPad)
                    .font(Theme.num(40))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 30)
            Toggle("Start with sample bills to explore", isOn: $loadSample)
                .padding(.horizontal, 30).font(.system(size: 15)).tint(Theme.accent)
            Spacer(); Spacer()
        }
    }

    private var currencySymbol: String {
        let f = NumberFormatter(); f.numberStyle = .currency; f.currencyCode = currencyCode
        return f.currencySymbol ?? "$"
    }

    private func finish() {
        currentBalance = Double(balanceText.replacingOccurrences(of: ",", with: ".")) ?? (loadSample ? 980 : 0)
        balanceAsOf = Date().timeIntervalSince1970
        if loadSample {
            let existing = (try? context.fetchCount(FetchDescriptor<RecurringItem>())) ?? 0
            if existing == 0 { SeedData.populate(context) }
        }
        Haptics.success()
        hasOnboarded = true
    }
}
