import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("retirementAge") private var retirementAge = 65.0
    @AppStorage("appearance") private var appearance = "system"
    @Query private var profiles: [Profile]
    @Query private var entries: [NetWorthEntry]
    @Query private var milestones: [Milestone]

    @State private var confirmReset = false
    @State private var sampleLoaded = false

    private var profile: Profile? { profiles.first }

    var body: some View {
        NavigationStack {
            Form {
                Section("Plan") {
                    if let profile {
                        Picker("Currency", selection: Binding(
                            get: { profile.currencyCode },
                            set: { profile.currencyCode = $0 })) {
                            Text("US Dollar ($)").tag("USD")
                            Text("Euro (€)").tag("EUR")
                            Text("British Pound (£)").tag("GBP")
                            Text("Canadian Dollar (C$)").tag("CAD")
                            Text("Australian Dollar (A$)").tag("AUD")
                        }
                    }
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Traditional retirement age")
                            Spacer()
                            Text("\(Int(retirementAge))")
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $retirementAge, in: 55...75, step: 1)
                            .tint(Theme.teal)
                    }
                    Text("Coast FI is calculated against this age — the point where compounding alone carries you to FI without further contributions.")
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
                    LabeledContent("Net-worth entries", value: "\(entries.count)")
                    LabeledContent("Custom milestones", value: "\(milestones.count)")
                    Button("Load sample journey") { loadSample() }
                        .disabled(sampleLoaded)
                    Button("Reset everything", role: .destructive) { confirmReset = true }
                }
                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    Text("Coast is fully offline — no bank connections, no account, no analytics. The math is the classic 4%-rule / Coast-FI model; it's a planning tool, not financial advice.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background(scheme))
            .navigationTitle("Settings")
            .confirmationDialog("Reset your plan, history, and milestones?",
                                isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Reset everything", role: .destructive) { resetAll() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func loadSample() {
        guard let profile else { return }
        profile.currentAge = 31
        profile.annualExpenses = 42_000
        profile.currentInvested = 118_000
        profile.annualContribution = 30_000
        profile.realReturn = 0.05
        profile.withdrawalRate = 0.04
        // 16 months of net-worth history climbing from ~75k to 118k.
        let calendar = Calendar.current
        var value = 75_000.0
        for monthsAgo in stride(from: 16, through: 0, by: -1) {
            let date = calendar.date(byAdding: .month, value: -monthsAgo, to: Date()) ?? Date()
            let entry = NetWorthEntry(date: date, amount: value.rounded(),
                                      note: monthsAgo == 16 ? "Started tracking" : "")
            context.insert(entry)
            // ~+2.7k/month with a little market noise.
            value += 2_700 + Double.random(in: -900...1_200)
        }
        profile.currentInvested = value.rounded()
        context.insert(Milestone(title: "Emergency fund topped up", targetAmount: 90_000, emoji: "🛟"))
        context.insert(Milestone(title: "House down payment", targetAmount: 150_000, emoji: "🏠"))
        sampleLoaded = true
        Haptics.success()
    }

    private func resetAll() {
        for e in entries { context.delete(e) }
        for m in milestones { context.delete(m) }
        if let profile {
            profile.currentAge = 32
            profile.annualExpenses = 45_000
            profile.currentInvested = 60_000
            profile.annualContribution = 24_000
            profile.realReturn = 0.05
            profile.withdrawalRate = 0.04
        }
        sampleLoaded = false
    }
}
