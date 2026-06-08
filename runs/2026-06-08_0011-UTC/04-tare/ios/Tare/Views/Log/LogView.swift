import SwiftUI
import SwiftData

struct LogView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WeightEntry.date, order: .reverse) private var entries: [WeightEntry]
    @AppStorage("tare.unit") private var unitRaw = WeightUnit.kg.rawValue
    @AppStorage("tare.smoothing") private var smoothing = 0.1

    @State private var editing: WeightEntry?

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .kg }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if entries.isEmpty {
                    EmptyStateView(icon: "list.bullet", title: "No weigh-ins",
                                   message: "Add weigh-ins on the Today tab and they'll be listed here.")
                } else {
                    List {
                        ForEach(rows, id: \.entry.id) { row in
                            Button { editing = row.entry } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(Units.display(row.entry.kilograms, unit: unit))
                                            .font(Brand.mono(17, weight: .semibold)).foregroundStyle(Brand.text)
                                        Text(Format.dayTime.string(from: row.entry.date))
                                            .font(.footnote).foregroundStyle(Brand.text2)
                                        if !row.entry.note.isEmpty {
                                            Text(row.entry.note).font(.caption).foregroundStyle(Brand.text3).lineLimit(1)
                                        }
                                    }
                                    Spacer()
                                    if let d = row.delta, abs(d) > 0.05 {
                                        Text(Units.deltaDisplay(d, unit: unit))
                                            .font(Brand.mono(13))
                                            .foregroundStyle(d < 0 ? Brand.live : Brand.warn)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.clear)
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Log")
            .sheet(item: $editing) { AddWeightSheet(existing: $0, defaultKg: nil) }
        }
    }

    // Each row with the delta vs the chronologically previous entry.
    private var rows: [(entry: WeightEntry, delta: Double?)] {
        var result: [(WeightEntry, Double?)] = []
        for (i, e) in entries.enumerated() {
            let prev = i + 1 < entries.count ? entries[i + 1] : nil
            result.append((e, prev.map { e.kilograms - $0.kilograms }))
        }
        return result
    }

    private func delete(_ offsets: IndexSet) {
        for i in offsets { context.delete(entries[i]) }
        try? context.save(); Haptics.tap()
    }
}
