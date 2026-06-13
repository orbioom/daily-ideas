import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(ProStore.self) private var pro
    @Environment(\.modelContext) private var context
    @Query private var debts: [Debt]
    @Query private var logs: [PaymentLog]

    @AppStorage("haptics") private var haptics = true
    @AppStorage("strategyRaw") private var strategyRaw = PayoffStrategy.snowball.rawValue
    @AppStorage("currencyCode") private var currencyCode = "USD"
    @AppStorage("celebrateMilestones") private var celebrate = true

    @State private var showPaywall = false
    @State private var confirmReset = false

    private let currencies = ["USD", "EUR", "GBP", "CAD", "AUD", "INR", "JPY", "BRL", "MXN", "ZAR"]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                Form {
                    if !pro.isPro {
                        Section {
                            Button { showPaywall = true } label: { proBanner }.buttonStyle(.plain)
                        }
                        .listRowBackground(Color.clear)
                    }

                    Section("Defaults") {
                        Picker("Default strategy", selection: $strategyRaw) {
                            ForEach(PayoffStrategy.allCases) { Text($0.label).tag($0.rawValue) }
                        }
                        Picker("Currency", selection: $currencyCode) {
                            ForEach(currencies, id: \.self) { Text($0).tag($0) }
                        }
                    }

                    Section("Feedback") {
                        Toggle("Haptics", isOn: $haptics)
                        Toggle("Celebrate cleared debts", isOn: $celebrate)
                    }

                    Section("Cascade Pro") {
                        if pro.isPro {
                            Label("Cascade Pro unlocked", systemImage: "checkmark.seal.fill").foregroundStyle(Theme.good)
                        } else {
                            Button("Unlock Cascade Pro") { showPaywall = true }.foregroundStyle(Theme.accent)
                        }
                        Button("Restore purchase") { pro.restore() }.foregroundStyle(Theme.inkSoft)
                    }

                    Section("Data") {
                        HStack { Text("Debts"); Spacer(); Text("\(debts.count)").foregroundStyle(Theme.inkSoft) }
                        HStack { Text("Logged payments"); Spacer(); Text("\(logs.count)").foregroundStyle(Theme.inkSoft) }
                        Button("Erase all data", role: .destructive) { confirmReset = true }
                    }

                    Section {
                        HStack { Text("Version"); Spacer(); Text("1.0").foregroundStyle(Theme.inkSoft) }
                    } footer: {
                        Text("Cascade keeps everything on your device. No bank login, no account, no tracking.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .alert("Erase everything?", isPresented: $confirmReset) {
                Button("Erase", role: .destructive) { reset() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This permanently deletes every debt and payment. This can’t be undone.")
            }
        }
    }

    private var proBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "infinity.circle.fill").font(.system(size: 34)).foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text("Cascade Pro").font(Theme.rounded(17, .bold)).foregroundStyle(.white)
                Text("Unlimited debts, custom order & export").font(Theme.rounded(13, .regular)).foregroundStyle(.white.opacity(0.9))
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.9))
        }
        .padding(16)
        .background(LinearGradient(colors: [Theme.accent, Theme.accent.opacity(0.78)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func reset() {
        for d in debts { context.delete(d) }
        for l in logs { context.delete(l) }
        try? context.save()
        Haptics.warning()
    }
}

struct PaywallView: View {
    @Environment(ProStore.self) private var pro
    @Environment(\.dismiss) private var dismiss

    private let perks = [
        ("infinity", "Unlimited debts", "Track every card, loan and balance — the free plan covers four."),
        ("slider.horizontal.3", "Custom payoff order", "Arrange debts by hand and let the cascade follow your priorities."),
        ("square.and.arrow.up", "Export your plan", "Share a clean payoff summary, and one price means no subscription ever.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 22) {
                        Image(systemName: "infinity.circle.fill")
                            .font(.system(size: 64)).foregroundStyle(Theme.accent)
                            .padding(.top, 28).accessibilityHidden(true)
                        Text("Cascade Pro").font(Theme.serif(30, .bold)).foregroundStyle(Theme.ink)
                        Text("The whole planner is free. Pro lifts the limits.")
                            .font(Theme.rounded(16, .regular)).foregroundStyle(Theme.inkSoft)
                            .multilineTextAlignment(.center).padding(.horizontal, 28)
                        VStack(spacing: 14) {
                            ForEach(perks, id: \.0) { perk in
                                HStack(spacing: 14) {
                                    Image(systemName: perk.0).font(.system(size: 24))
                                        .foregroundStyle(Theme.accent).frame(width: 36)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(perk.1).font(Theme.rounded(16, .bold)).foregroundStyle(Theme.ink)
                                        Text(perk.2).font(Theme.rounded(13, .regular)).foregroundStyle(Theme.inkSoft)
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                VStack(spacing: 10) {
                    Button {
                        pro.unlock(); Haptics.success(); dismiss()
                    } label: {
                        Text("Unlock for $7.99").font(Theme.rounded(18, .bold))
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .foregroundStyle(.white)
                    }
                    Button("Maybe later") { dismiss() }
                        .font(Theme.rounded(15, .medium)).foregroundStyle(Theme.inkSoft)
                }
                .padding(.horizontal, 20).padding(.bottom, 20)
            }
        }
    }
}
