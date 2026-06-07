import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("ledger.hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("ledger.appearance") private var appearance = "system"
    @AppStorage("ledger.currency") private var currency = "USD"
    @AppStorage("ledger.compactNumbers") private var compactNumbers = true
    @AppStorage("ledger.confirmDeletes") private var confirmDeletes = true
    @Query private var accounts: [Account]
    @Query private var snapshots: [Snapshot]
    @State private var showResetConfirm = false

    private let currencies = ["USD", "EUR", "GBP", "JPY"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionTitle(text: "Preferences")
                        Toggle("Haptics", isOn: $hapticsEnabled)
                            .onChange(of: hapticsEnabled) { _, v in Haptics.enabled = v; if v { Haptics.tap() } }
                        Divider().overlay(Brand.hairline)
                        HStack {
                            Text("Appearance").foregroundStyle(Brand.text)
                            Spacer()
                            Picker("Appearance", selection: $appearance) {
                                Text("System").tag("system"); Text("Light").tag("light"); Text("Dark").tag("dark")
                            }.pickerStyle(.menu).tint(Brand.text2)
                        }
                        Divider().overlay(Brand.hairline)
                        HStack {
                            Text("Currency").foregroundStyle(Brand.text)
                            Spacer()
                            Picker("Currency", selection: $currency) {
                                ForEach(currencies, id: \.self) { Text($0).tag($0) }
                            }.pickerStyle(.menu).tint(Brand.text2)
                        }
                        Divider().overlay(Brand.hairline)
                        Toggle("Compact large numbers", isOn: $compactNumbers)
                        Divider().overlay(Brand.hairline)
                        Toggle("Confirm before deleting", isOn: $confirmDeletes)
                    }
                    .tint(Brand.live).glassCard()

                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle(text: "Portfolio")
                        InfoRow(label: "Accounts", value: "\(accounts.count)", mono: true)
                        Divider().overlay(Brand.hairline)
                        InfoRow(label: "Snapshots", value: "\(snapshots.count)", mono: true)
                    }.glassCard()

                    VStack(alignment: .leading, spacing: 10) {
                        SectionTitle(text: "Data")
                        Button(role: .destructive) { showResetConfirm = true } label: {
                            Label("Erase all data", systemImage: "trash").frame(maxWidth: .infinity)
                        }.buttonStyle(GlassButtonStyle())
                    }.glassCard()

                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle(text: "About")
                        Text("Ledger tracks your net worth and asset allocation entirely on-device. No accounts, no sync, no bank logins.")
                            .font(.caption).foregroundStyle(Brand.text2)
                        Text("Version 1.0 · Orbioom").font(Brand.mono(11)).foregroundStyle(Brand.text3)
                    }.glassCard()
                }
                .padding()
            }
            .navigationTitle("Settings")
            .background(Brand.pageBackground)
            .confirmationDialog("Erase all accounts, snapshots and targets? This cannot be undone.",
                                isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Erase everything", role: .destructive) { erase() }
                Button("Cancel", role: .cancel) { }
            }
        }
    }

    private func erase() {
        do {
            try context.delete(model: SnapshotEntry.self)
            try context.delete(model: Snapshot.self)
            try context.delete(model: Account.self)
            try context.delete(model: Target.self)
            try context.save()
        } catch { }
        Haptics.warning()
    }
}
