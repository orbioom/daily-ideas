import SwiftUI
import SwiftData
import Charts

struct ProgressTabView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme
    @Query private var profiles: [Profile]
    @Query(sort: \NetWorthEntry.date) private var entries: [NetWorthEntry]
    @State private var showAdd = false

    private var profile: Profile? { profiles.first }

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "chart.line.uptrend.xyaxis",
                                       title: "Track your real progress",
                                       message: "Log your net worth whenever you check it. Coast charts your actual climb and projects an FI date from your true pace — not just assumptions.")
                        Button { showAdd = true } label: {
                            Label("Log net worth", systemImage: "plus")
                                .font(.headline)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.teal)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            paceCard
                            chartCard
                            entryList
                        }
                        .padding()
                    }
                }
            }
            .background(Theme.background(scheme))
            .navigationTitle("Progress")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Log net worth")
                }
            }
            .sheet(isPresented: $showAdd) {
                NetWorthEntrySheet()
            }
        }
    }

    private var paceCard: some View {
        let rate = FIEngine.monthlyGrowthRate(entries: entries)
        let code = profile?.currencyCode ?? "USD"
        return VStack(alignment: .leading, spacing: 8) {
            Text("Your real pace").font(.headline)
            if let rate, let profile {
                Text("You're growing about \(FIEngine.money(rate, code: code))/month.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft(scheme))
                if let date = FIEngine.fiDateFromHistory(entries: entries, fiNumber: profile.fiNumber) {
                    Text("At this pace you hit FI around \(date.formatted(.dateTime.month(.wide).year())).")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.teal)
                } else if rate <= 0 {
                    Text("Your logged pace is flat or down — keep logging as you invest to see a projection.")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSoft(scheme))
                }
            } else {
                Text("Log at least two entries to see your real growth pace.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft(scheme))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .coastCard()
    }

    private var chartCard: some View {
        let code = profile?.currencyCode ?? "USD"
        let fiNumber = profile?.fiNumber ?? 0
        return VStack(alignment: .leading, spacing: 10) {
            Text("Net worth logged").font(.headline)
            Chart {
                ForEach(entries) { entry in
                    LineMark(x: .value("Date", entry.date),
                             y: .value("Amount", entry.amount))
                    .foregroundStyle(Theme.teal)
                    .interpolationMethod(.monotone)
                    PointMark(x: .value("Date", entry.date),
                              y: .value("Amount", entry.amount))
                    .foregroundStyle(Theme.teal)
                }
                if fiNumber > 0 {
                    RuleMark(y: .value("FI", fiNumber))
                        .foregroundStyle(Theme.coral)
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                        .annotation(position: .top, alignment: .leading) {
                            Text("FI")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Theme.coral)
                        }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(FIEngine.money(v, code: code, compact: true))
                        }
                    }
                }
            }
            .frame(height: 200)
            .accessibilityLabel("Line chart of logged net worth over time against your FI line")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .coastCard()
    }

    private var entryList: some View {
        let code = profile?.currencyCode ?? "USD"
        return VStack(alignment: .leading, spacing: 10) {
            Text("History").font(.headline)
            ForEach(entries.sorted { $0.date > $1.date }) { entry in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(FIEngine.money(entry.amount, code: code))
                            .font(.subheadline.weight(.semibold))
                        Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(Theme.inkSoft(scheme))
                        if !entry.note.isEmpty {
                            Text(entry.note)
                                .font(.caption)
                                .foregroundStyle(Theme.inkSoft(scheme))
                        }
                    }
                    Spacer()
                    Button(role: .destructive) {
                        context.delete(entry)
                    } label: {
                        Image(systemName: "trash").font(.caption)
                    }
                    .accessibilityLabel("Delete entry from \(entry.date.formatted(date: .abbreviated, time: .omitted))")
                }
                .padding(.vertical, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .coastCard()
    }
}

struct NetWorthEntrySheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [Profile]
    @State private var amountText = ""
    @State private var date = Date()
    @State private var note = ""
    @State private var error: String?
    @AppStorage("syncProfileOnLog") private var syncProfile = true

    var body: some View {
        NavigationStack {
            Form {
                HStack {
                    Text("Net worth")
                    Spacer()
                    Text(FIEngine.currencySymbol(profiles.first?.currencyCode ?? "USD"))
                        .foregroundStyle(.secondary)
                    TextField("0", text: $amountText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 130)
                        .accessibilityLabel("Net worth amount")
                }
                DatePicker("As of", selection: $date, in: ...Date(), displayedComponents: .date)
                TextField("Note (optional)", text: $note)
                Section {
                    Toggle("Update my plan's invested total", isOn: $syncProfile)
                } footer: {
                    Text("Keeps your Plan tab in sync with the latest figure you log.")
                }
                if let error {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.subheadline)
                }
            }
            .navigationTitle("Log net worth")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
        }
        .presentationDetents([.medium])
    }

    private func save() {
        let cleaned = amountText.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces)
        guard let amount = Double(cleaned), amount >= 0, amount < 1_000_000_000 else {
            error = "Enter a valid net-worth amount."
            return
        }
        context.insert(NetWorthEntry(date: date, amount: amount, note: note.trimmingCharacters(in: .whitespaces)))
        if syncProfile, let profile = profiles.first {
            profile.currentInvested = amount
        }
        Haptics.success()
        dismiss()
    }
}
