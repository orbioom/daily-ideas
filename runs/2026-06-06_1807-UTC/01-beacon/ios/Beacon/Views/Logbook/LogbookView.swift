import SwiftUI
import SwiftData

struct LogbookView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \QSO.dateTime, order: .reverse) private var qsos: [QSO]
    @AppStorage("distanceUnit") private var unitRaw = DistanceUnit.km.rawValue
    @AppStorage("myGrid") private var myGrid = ""

    @State private var search = ""
    @State private var bandFilter: Band? = nil
    @State private var modeFilter: Mode? = nil
    @State private var showAdd = false

    private var unit: DistanceUnit { DistanceUnit(rawValue: unitRaw) ?? .km }

    private var filtered: [QSO] {
        qsos.filter { q in
            (bandFilter == nil || q.band == bandFilter)
            && (modeFilter == nil || q.mode == modeFilter)
            && (search.isEmpty
                || q.callsign.localizedCaseInsensitiveContains(search)
                || q.theirName.localizedCaseInsensitiveContains(search)
                || q.theirQTH.localizedCaseInsensitiveContains(search)
                || q.theirGrid.localizedCaseInsensitiveContains(search))
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if qsos.isEmpty {
                    EmptyStateView(icon: "dot.radiowaves.left.and.right",
                                   title: "No contacts yet",
                                   message: "Tap the + to log your first QSO. Everything stays on your device.")
                } else {
                    ScrollView {
                        filterBar
                        LazyVStack(spacing: 10) {
                            if filtered.isEmpty {
                                Text("No contacts match your filters.")
                                    .font(.subheadline).foregroundStyle(Brand.text2)
                                    .padding(.top, 40)
                            }
                            ForEach(filtered) { q in
                                NavigationLink(value: q) { QSORow(qso: q, unit: unit, myGrid: myGrid) }
                                    .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16).padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Logbook")
            .navigationDestination(for: QSO.self) { QSODetailView(qso: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Log a contact")
                }
            }
            .searchable(text: $search, prompt: "Callsign, name, grid")
            .sheet(isPresented: $showAdd) { QSOEditView(qso: nil) }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Menu {
                    Button("All bands") { bandFilter = nil }
                    ForEach(Band.allCases) { b in Button(b.label) { bandFilter = b } }
                } label: {
                    Chip(text: bandFilter?.label ?? "All bands", system: "antenna.radiowaves.left.and.right",
                         tint: bandFilter == nil ? Brand.text2 : Brand.text)
                }
                Menu {
                    Button("All modes") { modeFilter = nil }
                    ForEach(Mode.allCases) { m in Button(m.rawValue) { modeFilter = m } }
                } label: {
                    Chip(text: modeFilter?.rawValue ?? "All modes", system: "waveform",
                         tint: modeFilter == nil ? Brand.text2 : Brand.text)
                }
                if bandFilter != nil || modeFilter != nil {
                    Button { bandFilter = nil; modeFilter = nil } label: {
                        Chip(text: "Clear", system: "xmark", tint: Brand.danger)
                    }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
        }
    }
}

private struct QSORow: View {
    let qso: QSO
    let unit: DistanceUnit
    let myGrid: String

    private var distance: String? {
        guard !myGrid.isEmpty, !qso.theirGrid.isEmpty,
              let km = GridMath.distanceKm(from: myGrid, to: qso.theirGrid) else { return nil }
        return unit.format(km: km)
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(qso.callsign).font(.headline).foregroundStyle(Brand.text)
                    if qso.confirmed {
                        Image(systemName: "checkmark.seal.fill").font(.caption)
                            .foregroundStyle(Brand.live).accessibilityLabel("Confirmed")
                    }
                }
                HStack(spacing: 6) {
                    Chip(text: qso.band.label)
                    Chip(text: qso.mode.rawValue)
                    if !qso.theirGrid.isEmpty { Chip(text: qso.theirGrid) }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(qso.dateTime, format: .dateTime.month().day())
                    .font(Brand.mono(13)).foregroundStyle(Brand.text2)
                if let distance {
                    Text(distance).font(Brand.mono(12)).foregroundStyle(Brand.text3)
                }
            }
        }
        .glassCard()
    }
}
