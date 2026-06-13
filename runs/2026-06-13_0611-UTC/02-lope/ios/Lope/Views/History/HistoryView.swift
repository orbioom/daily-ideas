import SwiftUI
import SwiftData
import Charts

struct HistoryView: View {
    @AppStorage("useMetric") private var useMetric = true
    @Query(sort: \RunLog.date, order: .reverse) private var logs: [RunLog]
    @State private var editing: RunLog?

    private var totalSeconds: Int { logs.reduce(0) { $0 + $1.activeSeconds } }
    private var totalMeters: Double { logs.reduce(0) { $0 + $1.distanceMeters } }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if logs.isEmpty {
                    EmptyState(icon: "chart.bar.fill", title: "No runs yet",
                               message: "Your finished runs appear here with weekly progress charts. Start your first run from the Today tab.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            statsRow
                            weeklyChart
                            logList
                        }
                        .padding(.horizontal, 16).padding(.vertical, 12)
                    }
                }
            }
            .navigationTitle("History")
            .sheet(item: $editing) { LogEditView(log: $0) }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            StatTile(value: "\(logs.count)", label: "Runs", color: Theme.accent)
            StatTile(value: "\(totalSeconds / 60)", label: "Minutes")
            StatTile(value: useMetric ? String(format: "%.0f", totalMeters / 1000)
                                      : String(format: "%.0f", totalMeters / 1609.344),
                     label: useMetric ? "km" : "mi")
        }
    }

    private struct WeekBucket: Identifiable { let id: Date; let minutes: Int }

    private var weekly: [WeekBucket] {
        let cal = Calendar.current
        var buckets: [Date: Int] = [:]
        for log in logs {
            guard let start = cal.dateInterval(of: .weekOfYear, for: log.date)?.start else { continue }
            buckets[start, default: 0] += log.activeSeconds / 60
        }
        // last 8 weeks
        var result: [WeekBucket] = []
        let thisWeek = cal.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
        for i in stride(from: 7, through: 0, by: -1) {
            if let d = cal.date(byAdding: .weekOfYear, value: -i, to: thisWeek) {
                result.append(WeekBucket(id: d, minutes: buckets[d] ?? 0))
            }
        }
        return result
    }

    private var weeklyChart: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Active minutes per week").font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Chart(weekly) { bucket in
                    BarMark(
                        x: .value("Week", bucket.id, unit: .weekOfYear),
                        y: .value("Minutes", bucket.minutes)
                    )
                    .foregroundStyle(Theme.accent.gradient)
                    .cornerRadius(4)
                }
                .chartYAxis { AxisMarks(position: .leading) }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .weekOfYear, count: 2)) { value in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .frame(height: 170)
            }
        }
    }

    private var logList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("All runs").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.inkFaint)
                .padding(.leading, 4)
            ForEach(logs) { log in
                Button { editing = log } label: { LogRow(log: log, useMetric: useMetric) }
                    .buttonStyle(.plain)
            }
        }
    }
}

struct LogRow: View {
    let log: RunLog
    let useMetric: Bool
    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 0) {
                Text(log.date, format: .dateTime.day()).font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text(log.date, format: .dateTime.month(.abbreviated)).font(.system(size: 11))
                    .foregroundStyle(Theme.inkFaint)
            }
            .frame(width: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(log.title).font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.ink)
                HStack(spacing: 8) {
                    Label(Format.clock(log.activeSeconds), systemImage: "clock")
                    if log.distanceMeters > 50 {
                        Label(Format.distance(log.distanceMeters, metric: useMetric), systemImage: "ruler")
                    }
                }
                .font(.system(size: 12)).foregroundStyle(Theme.inkSoft).labelStyle(.titleAndIcon)
            }
            Spacer()
            HStack(spacing: 1) {
                ForEach(0..<log.rating, id: \.self) { _ in
                    Image(systemName: "figure.run").font(.system(size: 10)).foregroundStyle(Theme.accent)
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surface))
        .accessibilityElement(children: .combine)
    }
}

struct LogEditView: View {
    @Bindable var log: RunLog
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage("useMetric") private var useMetric = true
    @State private var distanceText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Run") {
                    LabeledContent("Session", value: log.title)
                    LabeledContent("Date", value: log.date.formatted(date: .abbreviated, time: .shortened))
                    LabeledContent("Active time", value: Format.clock(log.activeSeconds))
                }
                Section("How it felt") {
                    Picker("Rating", selection: $log.rating) {
                        ForEach(1...5, id: \.self) { Text("\($0)").tag($0) }
                    }.pickerStyle(.segmented)
                }
                Section("Distance") {
                    HStack {
                        TextField("0.0", text: $distanceText).keyboardType(.decimalPad)
                        Text(useMetric ? "km" : "mi").foregroundStyle(Theme.inkSoft)
                    }
                }
                Section("Notes") {
                    TextField("Notes", text: $log.note, axis: .vertical).lineLimit(2...5)
                }
                Section {
                    Button("Delete run", role: .destructive) {
                        context.delete(log); dismiss()
                    }
                }
            }
            .navigationTitle("Edit run")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { commit() } }
            }
            .onAppear {
                if log.distanceMeters > 0 {
                    let v = useMetric ? log.distanceMeters / 1000 : log.distanceMeters / 1609.344
                    distanceText = String(format: "%.2f", v)
                }
            }
        }
    }

    private func commit() {
        if let v = Double(distanceText.replacingOccurrences(of: ",", with: ".")) {
            log.distanceMeters = useMetric ? v * 1000 : v * 1609.344
        } else if distanceText.trimmingCharacters(in: .whitespaces).isEmpty {
            log.distanceMeters = 0
        }
        try? context.save()
        dismiss()
    }
}
