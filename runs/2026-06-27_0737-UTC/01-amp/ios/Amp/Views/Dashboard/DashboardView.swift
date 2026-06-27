import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: \ChargingSession.date, order: .reverse) private var sessions: [ChargingSession]
    @Query private var vehicles: [Vehicle]
    @Query private var settingsArr: [AmpSettings]
    @State private var showAddSession = false

    private var settings: AmpSettings? { settingsArr.first }
    private var currencySymbol: String { settings?.currencySymbol ?? "$" }

    private var allStats: ChargingStats { ChargingEngine.stats(from: sessions) }

    private var thisMonthSessions: [ChargingSession] {
        let start = Calendar.current.startOfMonth(Date())
        return sessions.filter { $0.date >= start }
    }
    private var monthStats: ChargingStats { ChargingEngine.stats(from: thisMonthSessions) }
    private var lastSession: ChargingSession? { sessions.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    heroCard
                    monthSummaryRow
                    if let last = lastSession {
                        lastSessionCard(last)
                    }
                    lifetimeRow
                    savingsCard
                }
                .padding()
            }
            .navigationTitle("Amp")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddSession = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .accessibilityLabel("Add charging session")
                }
            }
            .sheet(isPresented: $showAddSession) {
                AddSessionView()
            }
        }
    }

    private var heroCard: some View {
        ZStack {
            AmpTheme.gradient()
            VStack(spacing: 8) {
                Image(systemName: "bolt.batteryblock.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.white.opacity(0.9))
                Text(String(format: "%.1f kWh", allStats.totalKWh))
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("Total energy charged")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
            }
            .padding(28)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        .accessibilityElement(children: .combine)
    }

    private var monthSummaryRow: some View {
        HStack(spacing: 12) {
            statCard(title: "This Month", value: String(format: "%.1f kWh", monthStats.totalKWh), icon: "bolt.fill", color: .blue)
            statCard(title: "Cost", value: "\(currencySymbol)\(String(format: "%.2f", monthStats.totalCost))", icon: "creditcard.fill", color: .purple)
            statCard(title: "Sessions", value: "\(monthStats.sessionCount)", icon: "list.bullet", color: .orange)
        }
    }

    private var lifetimeRow: some View {
        HStack(spacing: 12) {
            statCard(title: "Lifetime Cost", value: "\(currencySymbol)\(String(format: "%.0f", allStats.totalCost))", icon: "dollarsign.circle", color: .green)
            statCard(title: "Avg kWh/Session", value: String(format: "%.1f", allStats.avgKWhPerSession), icon: "chart.bar.fill", color: .cyan)
        }
    }

    private var savingsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Environmental Impact", systemImage: "leaf.fill")
                .font(.headline)
                .foregroundStyle(Color("AmpGreen"))
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text(String(format: "%.0f kg", allStats.co2SavedKg))
                        .font(.title2.bold())
                    Text("CO₂ offset (est.)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text(String(format: "%.0f gal", allStats.gasEquivSaved))
                        .font(.title2.bold())
                    Text("Gas equivalent saved")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(AmpTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func lastSessionCard(_ s: ChargingSession) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Last Charge", systemImage: "clock.arrow.circlepath")
                .font(.headline)
            HStack {
                VStack(alignment: .leading) {
                    Text(s.vehicle?.displayName ?? "Vehicle")
                        .font(.subheadline.bold())
                    Text(s.locationName.isEmpty ? "Unknown location" : s.locationName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(s.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(String(format: "%.1f kWh", s.kwhAdded))
                        .font(.title3.bold())
                    Text("\(currencySymbol)\(String(format: "%.2f", s.cost))")
                        .foregroundStyle(.secondary)
                    Label(s.chargerType.rawValue, systemImage: s.chargerType.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(AmpTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AmpTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private extension Calendar {
    func startOfMonth(_ date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps) ?? date
    }
}
