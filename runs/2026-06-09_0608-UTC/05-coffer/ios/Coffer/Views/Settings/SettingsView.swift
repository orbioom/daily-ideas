import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Room.sortIndex, order: .forward) private var rooms: [Room]
    @Query(sort: \Item.createdAt, order: .reverse) private var items: [Item]

    @AppStorage("coffer.currencyCode") private var currencyCode = "USD"
    @AppStorage("coffer.warrantyWindowDays") private var warrantyWindowDays = 30
    @AppStorage("coffer.haptics") private var haptics = true

    @State private var showResetConfirm = false

    private let currencyOptions = ["USD", "EUR", "GBP", "JPY", "CAD", "AUD", "INR", "CHF"]
    private let windowOptions = [30, 60, 90]

    private var totalValue: Double { InventoryEngine.totalValue(items) }

    private var csvText: String { InventoryEngine.csvSummary(rooms: rooms, items: items) }
    private var summaryText: String {
        InventoryEngine.textSummary(rooms: rooms, items: items, currencyCode: currencyCode)
    }

    var body: some View {
        Form {
            Section("Preferences") {
                Picker("Currency", selection: $currencyCode) {
                    ForEach(currencyOptions, id: \.self) { code in
                        Text("\(code) (\(Format.currencySymbol(for: code)))").tag(code)
                    }
                }
                Picker("Expiring soon window", selection: $warrantyWindowDays) {
                    ForEach(windowOptions, id: \.self) { days in
                        Text("\(days) days").tag(days)
                    }
                }
                Toggle("Haptics", isOn: $haptics)
            }

            Section {
                LabeledContent("Rooms", value: "\(rooms.count)")
                LabeledContent("Items", value: "\(items.count)")
                LabeledContent("Total value",
                               value: Format.currency(totalValue, code: currencyCode))
            } header: {
                Text("Inventory")
            }

            Section {
                ShareLink(item: summaryText,
                          preview: SharePreview("Coffer inventory summary")) {
                    Label("Share text summary", systemImage: "doc.text")
                }
                .disabled(items.isEmpty)
                ShareLink(item: csvText,
                          preview: SharePreview("Coffer inventory CSV")) {
                    Label("Share CSV", systemImage: "tablecells")
                }
                .disabled(items.isEmpty)
            } header: {
                Text("Export")
            } footer: {
                Text("Generate a plain-text or CSV summary to email or save for your insurer. Nothing leaves your device until you share it.")
            }

            Section {
                Button(role: .destructive) {
                    showResetConfirm = true
                } label: {
                    Label("Clear all data", systemImage: "trash")
                }
                .disabled(rooms.isEmpty && items.isEmpty)
            } footer: {
                Text("Permanently deletes all \(rooms.count) rooms and \(items.count) items from this device.")
            }

            Section {
                LabeledContent("Coffer", value: "1.0")
            } footer: {
                Text("On-device only. No account, no cloud, no subscription. Conjured, not just coded.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle("Settings")
        .confirmationDialog("Clear all data?",
                            isPresented: $showResetConfirm,
                            titleVisibility: .visible) {
            Button("Delete everything", role: .destructive) { clearAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes all \(rooms.count) rooms and \(items.count) items. This cannot be undone.")
        }
    }

    private func clearAll() {
        for item in items { context.delete(item) }
        for room in rooms { context.delete(room) }
        try? context.save()
        Haptics.warning()
    }
}
