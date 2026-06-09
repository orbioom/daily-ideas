import SwiftUI
import SwiftData

struct LogView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \VitalEntry.date, order: .reverse) private var entries: [VitalEntry]

    @AppStorage("cuff.weightUnit") private var weightUnitRaw = WeightUnit.kg.rawValue
    @AppStorage("cuff.glucoseUnit") private var glucoseUnitRaw = GlucoseUnit.mgdl.rawValue

    @State private var filter: VitalKind? = nil
    @State private var showAdd = false

    private var weightUnit: WeightUnit { WeightUnit.from(weightUnitRaw) }
    private var glucoseUnit: GlucoseUnit { GlucoseUnit.from(glucoseUnitRaw) }

    private var filtered: [VitalEntry] {
        guard let filter else { return entries }
        return entries.filter { $0.kind == filter }
    }

    /// Entries grouped by calendar day, newest day first.
    private var grouped: [(day: Date, items: [VitalEntry])] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: filtered) { cal.startOfDay(for: $0.date) }
        return groups.map { (day: $0.key, items: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.day > $1.day }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filtered.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "list.bullet.rectangle",
                                       title: filter == nil ? "No readings yet" : "Nothing here yet",
                                       message: filter == nil
                                            ? "Log a reading and it will appear here, grouped by day."
                                            : "No \((filter?.label ?? "").lowercased()) readings. Try a different filter.")
                            .glassCard()
                            .padding(20)
                    }
                } else {
                    List {
                        ForEach(grouped, id: \.day) { group in
                            Section {
                                ForEach(group.items) { entry in
                                    NavigationLink {
                                        EntryDetailView(entry: entry)
                                    } label: {
                                        LogRow(entry: entry, weightUnit: weightUnit, glucoseUnit: glucoseUnit)
                                    }
                                    .listRowBackground(Color.clear)
                                }
                                .onDelete { offsets in delete(in: group.items, at: offsets) }
                            } header: {
                                Text(Format.relativeDay(group.day))
                                    .font(Brand.mono(12, weight: .medium))
                                    .foregroundStyle(Brand.text3)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Brand.pageBackground)
            .navigationTitle("Log")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { filterMenu }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        showAdd = true
                    } label: { Image(systemName: "plus.circle.fill") }
                        .accessibilityLabel("Add reading")
                }
            }
            .sheet(isPresented: $showAdd) { AddEntryView() }
        }
    }

    private var filterMenu: some View {
        Menu {
            Button { filter = nil } label: {
                Label("All metrics", systemImage: filter == nil ? "checkmark" : "")
            }
            Divider()
            ForEach(VitalKind.allCases) { kind in
                Button { filter = kind } label: {
                    Label(kind.label, systemImage: filter == kind ? "checkmark" : kind.symbol)
                }
            }
        } label: {
            Label(filter?.shortLabel ?? "Filter", systemImage: "line.3.horizontal.decrease.circle")
        }
    }

    private func delete(in items: [VitalEntry], at offsets: IndexSet) {
        for i in offsets { context.delete(items[i]) }
        try? context.save()
        Haptics.warning()
    }
}

/// One compact row in the Log list.
struct LogRow: View {
    let entry: VitalEntry
    let weightUnit: WeightUnit
    let glucoseUnit: GlucoseUnit

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.kind.symbol)
                .foregroundStyle(entry.kind.tint)
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                if entry.kind == .bloodPressure {
                    Text("\(entry.systolic)/\(entry.diastolic) mmHg")
                        .font(Brand.mono(16, weight: .semibold)).foregroundStyle(Brand.text)
                } else {
                    Text(Format.value(entry, weight: weightUnit, glucose: glucoseUnit))
                        .font(Brand.mono(16, weight: .semibold)).foregroundStyle(Brand.text)
                }
                HStack(spacing: 6) {
                    Text(Format.time.string(from: entry.date))
                    Text("·")
                    Text(entry.tag.label)
                }
                .font(Brand.mono(11)).foregroundStyle(Brand.text3)
            }
            Spacer()
            if entry.kind == .bloodPressure {
                BPCategoryBadge(category: entry.category, compact: true)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        let when = "\(Format.time.string(from: entry.date)), \(entry.tag.label)"
        if entry.kind == .bloodPressure {
            return "Blood pressure \(entry.systolic) over \(entry.diastolic), \(entry.category.label), \(when)"
        }
        return "\(entry.kind.label) \(Format.value(entry, weight: weightUnit, glucose: glucoseUnit)), \(when)"
    }
}
