import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(ProStore.self) private var pro
    @Environment(\.modelContext) private var context
    @Query private var accounts: [Account]
    @Query private var entries: [BalanceEntry]

    @AppStorage("haptics") private var haptics = true
    @AppStorage("currencyCode") private var currencyCode = "USD"
    @AppStorage("hideBalances") private var hideBalances = false

    @State private var showPaywall = false
    @State private var confirmReset = false

    private let currencies = ["USD", "EUR", "GBP", "CAD", "AUD", "INR", "JPY", "BRL", "MXN", "ZAR", "SGD", "CHF"]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                Form {
                    if !pro.isPro {
                        Section {
                            Button { showPaywall = true } label: { proBanner }.buttonStyle(.plain)
                        }.listRowBackground(Color.clear)
                    }

                    Section("Display") {
                        Picker("Currency", selection: $currencyCode) {
                            ForEach(currencies, id: \.self) { Text($0).tag($0) }
                        }
                        Toggle("Hide balances by default", isOn: $hideBalances)
                    }

                    Section("Feedback") {
                        Toggle("Haptics", isOn: $haptics)
                    }

                    Section("Plumb Pro") {
                        if pro.isPro {
                            Label("Plumb Pro unlocked", systemImage: "checkmark.seal.fill").foregroundStyle(Theme.good)
                        } else {
                            Button("Unlock Plumb Pro") { showPaywall = true }.foregroundStyle(Theme.accent)
                        }
                        Button("Restore purchase") { pro.restore() }.foregroundStyle(Theme.inkSoft)
                    }

                    Section("Data") {
                        HStack { Text("Accounts"); Spacer(); Text("\(accounts.count)").foregroundStyle(Theme.inkSoft) }
                        HStack { Text("Balance updates"); Spacer(); Text("\(entries.count)").foregroundStyle(Theme.inkSoft) }
                        Button("Erase all data", role: .destructive) { confirmReset = true }
                    }

                    Section {
                        HStack { Text("Version"); Spacer(); Text("1.0").foregroundStyle(Theme.inkSoft) }
                    } footer: {
                        Text("Plumb never connects to your bank. Your balances stay on this device — no account, no sync, no tracking.")
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
                Text("This permanently deletes every account and balance update. This can’t be undone.")
            }
        }
    }

    private var proBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "crown.fill").font(.system(size: 30)).foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text("Plumb Pro").font(Theme.rounded(17, .bold)).foregroundStyle(.white)
                Text("Unlimited accounts, goals & export").font(Theme.rounded(13, .regular)).foregroundStyle(.white.opacity(0.9))
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.9))
        }
        .padding(16)
        .background(LinearGradient(colors: [Theme.accent, Theme.accent.opacity(0.74)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func reset() {
        for a in accounts { context.delete(a) }
        for e in entries { context.delete(e) }
        try? context.save()
        Haptics.warning()
    }
}

struct PaywallView: View {
    @Environment(ProStore.self) private var pro
    @Environment(\.dismiss) private var dismiss

    private let perks = [
        ("infinity", "Unlimited accounts", "Track every account you own — the free plan covers six."),
        ("target", "Net-worth goals & projections", "Set targets and see the date you’ll hit them at your pace."),
        ("square.and.arrow.up", "Export & backup", "Export a clean snapshot of your net worth — one price, no subscription.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 22) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60)).foregroundStyle(Theme.accent)
                            .padding(.top, 28).accessibilityHidden(true)
                        Text("Plumb Pro").font(Theme.serif(30, .bold)).foregroundStyle(Theme.ink)
                        Text("Your net worth, fully unlocked — and always private.")
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
                        }.padding(.horizontal, 20)
                    }
                }
                VStack(spacing: 10) {
                    Button {
                        pro.unlock(); Haptics.success(); dismiss()
                    } label: {
                        Text("Unlock for $9.99").font(Theme.rounded(18, .bold))
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
