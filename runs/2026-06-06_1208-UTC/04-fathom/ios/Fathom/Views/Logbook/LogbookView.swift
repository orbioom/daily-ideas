import SwiftUI
import SwiftData

/// The dive logbook — every dive, newest first, numbered.
struct LogbookView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Dive.date, order: .reverse) private var dives: [Dive]
    @AppStorage("unitSystem") private var unitRaw = UnitSystem.metric.rawValue

    @State private var newDive: Dive?

    private var unit: UnitSystem { UnitSystem(rawValue: unitRaw) ?? .metric }
    private var fmt: DiveFmt { DiveFmt(unit: unit) }
    private var totalBottomMin: Int { dives.reduce(0) { $0 + $1.durationMin } }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Group {
                    if dives.isEmpty {
                        EmptyStateView(icon: "book",
                                       title: "No dives logged",
                                       message: "Add your first dive to start your logbook.")
                    } else { list }
                }
            }
            .navigationTitle("Logbook")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { create() } label: { Image(systemName: "plus") }.accessibilityLabel("Log dive")
                }
            }
            .navigationDestination(for: Dive.self) { DiveDetailView(dive: $0) }
            .sheet(item: $newDive) { DiveEditView(dive: $0, isNew: true) }
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                HStack(spacing: 10) {
                    StatTile(value: "\(dives.count)", label: "Dives")
                    StatTile(value: "\(totalBottomMin / 60)h \(totalBottomMin % 60)m", label: "Bottom time", tint: Brand.live)
                    StatTile(value: fmt.depth(dives.map(\.maxDepthM).max() ?? 0), label: "Deepest")
                }
                ForEach(Array(dives.enumerated()), id: \.element.id) { idx, dive in
                    NavigationLink(value: dive) {
                        DiveRow(number: dives.count - idx, dive: dive, fmt: fmt)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) { delete(dive) } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
            .padding(.horizontal, 16).padding(.bottom, 28)
        }
    }

    private func create() {
        let d = Dive(date: Date(), maxDepthM: 0, durationMin: 0)
        context.insert(d); newDive = d; Haptics.tap()
    }
    private func delete(_ d: Dive) { context.delete(d); try? context.save(); Haptics.warning() }
}

private struct DiveRow: View {
    let number: Int
    let dive: Dive
    let fmt: DiveFmt
    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 2) {
                Text("#\(number)").font(Brand.mono(13, weight: .semibold)).foregroundStyle(Brand.text)
                Image(systemName: dive.type.symbol).font(.caption).foregroundStyle(Brand.text3)
            }
            .frame(width: 40)
            VStack(alignment: .leading, spacing: 3) {
                Text(dive.site?.name ?? "Unnamed site").font(.headline).foregroundStyle(Brand.text).lineLimit(1)
                Text(dive.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption).foregroundStyle(Brand.text3)
                HStack(spacing: 6) {
                    Pill(text: dive.gas.label, tint: dive.gas.isAir ? Brand.text2 : Brand.live)
                    if dive.rating > 0 {
                        Text(String(repeating: "★", count: dive.rating))
                            .font(.caption2).foregroundStyle(Brand.magic)
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(fmt.depth(dive.maxDepthM)).font(Brand.mono(16, weight: .semibold)).foregroundStyle(Brand.text)
                Text(fmt.duration(dive.durationMin)).font(.caption).foregroundStyle(Brand.text3)
            }
        }
        .glassCard()
    }
}
