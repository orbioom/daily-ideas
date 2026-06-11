import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("staleDays") private var staleDays = 60
    @AppStorage("currencyCode") private var currencyCode = "USD"
    @AppStorage("appearance") private var appearance = "system"
    @Query private var items: [Item]

    @State private var confirmDelete = false
    @State private var sampleLoaded = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Business") {
                    Picker("Currency", selection: $currencyCode) {
                        Text("US Dollar ($)").tag("USD")
                        Text("Euro (€)").tag("EUR")
                        Text("British Pound (£)").tag("GBP")
                        Text("Canadian Dollar (C$)").tag("CAD")
                        Text("Australian Dollar (A$)").tag("AUD")
                    }
                    Stepper(value: $staleDays, in: 14...180, step: 7) {
                        HStack {
                            Text("Stale after")
                            Spacer()
                            Text("\(staleDays) days")
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text("Listings older than this appear under “Needs attention” with a price-drop nudge.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Section("Experience") {
                    Toggle("Haptic feedback", isOn: $hapticsEnabled)
                    Picker("Appearance", selection: $appearance) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                }
                Section("Data") {
                    LabeledContent("Items tracked", value: "\(items.count)")
                    Button("Load sample shop") { loadSample() }
                        .disabled(sampleLoaded)
                    Button("Delete all data", role: .destructive) { confirmDelete = true }
                        .disabled(items.isEmpty)
                }
                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    Text("Flipside is offline and account-free. Your margins are nobody's business but yours.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background(scheme))
            .navigationTitle("Settings")
            .confirmationDialog("Delete all \(items.count) items?",
                                isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete everything", role: .destructive) {
                    for item in items { context.delete(item) }
                    sampleLoaded = false
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    /// A believable 18-item resale shop across all statuses and platforms.
    private func loadSample() {
        let calendar = Calendar.current
        func daysAgo(_ d: Int) -> Date {
            calendar.date(byAdding: .day, value: -d, to: Date()) ?? Date()
        }
        // (title, category, source, cost, sourcedDaysAgo, status, listPrice, listedDaysAgo)
        let active: [(String, ItemCategory, SourceType, Double, Int, ItemStatus, Double, Int?)] = [
            ("Patagonia Better Sweater, M", .clothing, .thrift, 9.99, 4, .listed, 64.99, 3),
            ("Levi's 501 vintage, 32×32", .clothing, .thrift, 7.50, 12, .listed, 48.00, 10),
            ("KitchenAid hand mixer", .home, .garage, 5.00, 8, .listed, 34.99, 6),
            ("LEGO Star Wars sets bundle", .toys, .garage, 22.00, 90, .listed, 120.00, 85),
            ("Nintendo GameCube + controller", .electronics, .estate, 35.00, 70, .listed, 139.99, 68),
            ("Coach leather crossbody", .clothing, .thrift, 14.99, 2, .sourced, 0, nil),
            ("Pyrex primary colors bowl set", .home, .estate, 18.00, 25, .sourced, 0, nil),
            ("Air Jordan 1 Mid, sz 10", .shoes, .online, 60.00, 6, .listed, 145.00, 5),
            ("Vintage Polaroid SX-70", .electronics, .estate, 40.00, 30, .sourced, 0, nil),
            ("Carhartt detroit jacket, L", .clothing, .thrift, 24.99, 1, .sourced, 0, nil),
        ]
        for spec in active {
            let item = Item(title: spec.0, category: spec.1, source: spec.2, cost: spec.3,
                            sourcedDate: daysAgo(spec.4), status: spec.5,
                            listPrice: spec.6, listedDate: spec.7.map(daysAgo))
            context.insert(item)
        }
        // (title, category, source, cost, sourcedDaysAgo, listedDaysAgo, soldDaysAgo, soldPrice, platform, shipping)
        let soldSpecs: [(String, ItemCategory, SourceType, Double, Int, Int, Int, Double, Platform, Double)] = [
            ("Nike vintage windbreaker, L", .clothing, .thrift, 6.99, 75, 70, 52, 54.99, .ebay, 8.40),
            ("Ted Lapidus silk scarf", .clothing, .estate, 4.00, 80, 74, 71, 42.00, .poshmark, 0),
            ("Sony Walkman WM-FX290", .electronics, .garage, 8.00, 95, 90, 62, 89.99, .ebay, 6.75),
            ("Le Creuset dutch oven 5.5qt", .home, .estate, 45.00, 60, 55, 41, 189.99, .facebook, 0),
            ("Beanie Babies lot (12)", .toys, .garage, 10.00, 120, 110, 95, 38.00, .mercari, 7.20),
            ("Doc Martens 1460, sz 8", .shoes, .thrift, 19.99, 55, 50, 30, 79.99, .depop, 9.10),
            ("Mid-century brass lamp", .home, .estate, 22.00, 50, 45, 18, 110.00, .facebook, 0),
            ("Pendleton wool shirt, XL", .clothing, .thrift, 11.50, 38, 33, 12, 68.00, .ebay, 7.90),
        ]
        for spec in soldSpecs {
            let item = Item(title: spec.0, category: spec.1, source: spec.2, cost: spec.3,
                            sourcedDate: daysAgo(spec.4), status: .sold,
                            listPrice: spec.7, listedDate: daysAgo(spec.5))
            context.insert(item)
            let sale = Sale(soldPrice: spec.7, fees: (spec.7 * spec.8.defaultFeeRate * 100).rounded() / 100,
                            shipping: spec.9, soldDate: daysAgo(spec.6), platform: spec.8)
            sale.item = item
            context.insert(sale)
        }
        sampleLoaded = true
        Haptics.success()
    }
}
