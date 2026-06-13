import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("buffer") private var buffer = 100.0
    @AppStorage("currencyCode") private var currencyCode = "USD"
    @AppStorage("appearance") private var appearance = AppearanceMode.system.rawValue
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("isPro") private var isPro = false

    @Environment(\.modelContext) private var context
    @Query private var recurring: [RecurringItem]
    @Query private var oneOffs: [OneOffItem]
    @State private var bufferText = ""
    @State private var showPaywall = false
    @State private var showErase = false

    private let currencies = ["USD", "EUR", "GBP", "CAD", "AUD", "JPY", "INR", "BRL", "MXN", "ZAR"]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                Form {
                    if !isPro {
                        Section {
                            Button { showPaywall = true } label: { proBanner }.buttonStyle(.plain)
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    }
                    Section {
                        HStack {
                            Text("Safety buffer")
                            Spacer()
                            Text(symbol).foregroundStyle(Theme.inkSoft)
                            TextField("100", text: $bufferText)
                                .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                                .frame(width: 90)
                                .onChange(of: bufferText) { _, v in
                                    if let n = Double(v.replacingOccurrences(of: ",", with: ".")) { buffer = max(0, n) }
                                }
                        }
                    } header: { Text("Safe to spend") } footer: {
                        Text("Runway keeps this much in reserve when calculating what's safe to spend.")
                    }
                    Section("Currency & look") {
                        Picker("Currency", selection: $currencyCode) {
                            ForEach(currencies, id: \.self) { Text($0).tag($0) }
                        }
                        Picker("Theme", selection: $appearance) {
                            ForEach(AppearanceMode.allCases) { Text($0.label).tag($0.rawValue) }
                        }
                        Toggle("Haptic feedback", isOn: $hapticsEnabled)
                            .onChange(of: hapticsEnabled) { _, v in Haptics.enabled = v }
                    }
                    Section("Your data") {
                        LabeledContent("Recurring items", value: "\(recurring.count)")
                        LabeledContent("One-time items", value: "\(oneOffs.count)")
                        Button("Erase all items", role: .destructive) { showErase = true }
                    }
                    Section {
                        if isPro {
                            Label("Runway Pro unlocked", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(Theme.accent)
                        }
                        LabeledContent("Version", value: "1.0")
                    } header: { Text("About") } footer: {
                        Text("Runway never connects to your bank. Everything you enter stays on this device.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .onAppear { bufferText = String(format: "%.0f", buffer); Haptics.enabled = hapticsEnabled }
            .sheet(isPresented: $showPaywall) { PaywallView(isPro: $isPro) }
            .alert("Erase all items?", isPresented: $showErase) {
                Button("Cancel", role: .cancel) {}
                Button("Erase", role: .destructive) { erase() }
            } message: {
                Text("This removes every recurring and one-time item. Your balance is kept.")
            }
        }
    }

    private var symbol: String {
        let f = NumberFormatter(); f.numberStyle = .currency; f.currencyCode = currencyCode
        return f.currencySymbol ?? "$"
    }

    private func erase() {
        recurring.forEach { context.delete($0) }
        oneOffs.forEach { context.delete($0) }
        try? context.save(); Haptics.warning()
    }

    private var proBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "sparkles").font(.system(size: 26)).foregroundStyle(Theme.accent)
            VStack(alignment: .leading, spacing: 3) {
                Text("Runway Pro").font(Theme.num(19)).foregroundStyle(Theme.ink)
                Text("Multiple accounts, a home-screen widget, and a 6-month horizon.")
                    .font(.system(size: 13)).foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.accent.opacity(0.14)))
    }
}

struct PaywallView: View {
    @Binding var isPro: Bool
    @Environment(\.dismiss) private var dismiss
    private let perks: [(String, String)] = [
        ("building.columns", "Track multiple accounts together"),
        ("calendar.badge.clock", "Forecast up to 6 months ahead"),
        ("apps.iphone", "A safe-to-spend home-screen widget"),
        ("lock.shield", "Always on-device — no bank login")
    ]
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 22) {
                Spacer()
                Image(systemName: "sparkles").font(.system(size: 52)).foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text("Runway Pro").font(Theme.num(32)).foregroundStyle(Theme.ink)
                Text("One payment. No subscription.").font(.system(size: 16)).foregroundStyle(Theme.inkSoft)
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(perks, id: \.0) { p in
                        HStack(spacing: 12) {
                            Image(systemName: p.0).foregroundStyle(Theme.accent).frame(width: 26)
                            Text(p.1).font(.system(size: 15)).foregroundStyle(Theme.ink)
                        }
                    }
                }.padding(.horizontal, 34)
                Spacer()
                Button { isPro = true; Haptics.success(); dismiss() } label: {
                    Text("Unlock for $8.99").font(.system(size: 17, weight: .bold))
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.accent))
                        .foregroundStyle(.white)
                }.padding(.horizontal, 24)
                Button("Maybe later") { dismiss() }
                    .font(.system(size: 15)).foregroundStyle(Theme.inkFaint).padding(.bottom, 24)
            }
        }
    }
}
