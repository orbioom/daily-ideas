import SwiftUI
import SwiftData
import Charts

/// The stargazing journal (Pro). Lists observations, supports add/delete,
/// and shows a small Swift Charts summary of activity.
struct JournalView: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ObservationLog.date, order: .reverse) private var logs: [ObservationLog]

    @State private var showAdd = false
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            if !isPro {
                lockedState
            } else if logs.isEmpty {
                EmptyStateView(symbol: "book.closed",
                               title: "Your journal is empty",
                               message: "Record what you observe — the object, the conditions, the wonder.",
                               ctaTitle: "Add an entry") { showAdd = true }
            } else {
                journalList
            }
        }
        .navigationTitle("Journal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isPro {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add observation")
                }
            }
        }
        .sheet(isPresented: $showAdd) { LogObservationSheet() }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    private var lockedState: some View {
        EmptyStateView(symbol: "lock",
                       title: "Journal is a Pro feature",
                       message: "Keep a private record of everything you observe, with date, place and notes.",
                       ctaTitle: "Unlock Pro — \(Pro.priceLabel)") { showPaywall = true }
    }

    private var journalList: some View {
        List {
            Section {
                activityChart
                    .listRowBackground(Theme.surface)
            } header: {
                Text("Last 6 months")
            }

            Section("Entries (\(logs.count))") {
                ForEach(logs) { log in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(log.objectName).font(Theme.rounded(16, .semibold)).foregroundStyle(Theme.ink)
                            Spacer()
                            Text(Fmt.date(log.date)).font(.caption).foregroundStyle(Theme.inkSoft)
                        }
                        if !log.note.isEmpty {
                            Text(log.note).font(.callout).foregroundStyle(Theme.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Label(log.locationName, systemImage: "mappin")
                            .font(.caption2).foregroundStyle(Theme.inkFaint)
                    }
                    .padding(.vertical, 3)
                    .listRowBackground(Theme.surface)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(log.objectName) on \(Fmt.date(log.date)) at \(log.locationName). \(log.note)")
                }
                .onDelete(perform: delete)
            }
        }
        .scrollContentBackground(.hidden)
    }

    private var activityChart: some View {
        let data = monthlyCounts()
        return Chart(data, id: \.label) { item in
            BarMark(
                x: .value("Month", item.label),
                y: .value("Observations", item.count)
            )
            .foregroundStyle(Theme.accent.gradient)
            .cornerRadius(4)
        }
        .frame(height: 130)
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .padding(.vertical, 6)
        .accessibilityLabel("Observations per month for the last six months.")
        .accessibilityValue(data.map { "\($0.label): \($0.count)" }.joined(separator: ", "))
    }

    private struct MonthBucket { let label: String; let count: Int }

    private func monthlyCounts() -> [MonthBucket] {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        let now = Date()
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM"
        var buckets: [MonthBucket] = []
        for offset in stride(from: 5, through: 0, by: -1) {
            guard let monthDate = cal.date(byAdding: .month, value: -offset, to: now) else { continue }
            let comps = cal.dateComponents([.year, .month], from: monthDate)
            let count = logs.filter {
                let c = cal.dateComponents([.year, .month], from: $0.date)
                return c.year == comps.year && c.month == comps.month
            }.count
            buckets.append(MonthBucket(label: fmt.string(from: monthDate), count: count))
        }
        return buckets
    }

    private func delete(_ offsets: IndexSet) {
        for i in offsets {
            guard logs.indices.contains(i) else { continue }
            modelContext.delete(logs[i])
        }
        try? modelContext.save()
        Haptics.selection(settings.hapticsEnabled)
    }
}
