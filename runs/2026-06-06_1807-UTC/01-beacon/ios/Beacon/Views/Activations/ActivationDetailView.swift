import SwiftUI
import SwiftData

struct ActivationDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("distanceUnit") private var unitRaw = DistanceUnit.km.rawValue
    @Bindable var activation: Activation
    @State private var showEdit = false
    @State private var showAddQSO = false
    @State private var confirmDelete = false

    private var unit: DistanceUnit { DistanceUnit(rawValue: unitRaw) ?? .km }
    private var sortedQSOs: [QSO] { activation.qsos.sorted { $0.dateTime > $1.dateTime } }

    private var farthestKm: Double? {
        activation.qsos.compactMap { q -> Double? in
            guard !activation.grid.isEmpty, !q.theirGrid.isEmpty else { return nil }
            return GridMath.distanceKm(from: activation.grid, to: q.theirGrid)
        }.max()
    }
    private var uniqueGrids: Int {
        Set(activation.qsos.map { String($0.theirGrid.prefix(4)) }.filter { !$0.isEmpty }).count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                statsGrid
                if activation.kind.qsoTarget > 0 {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Eyebrow(text: "Activation progress")
                            Spacer()
                            Text(activation.isActivated ? "Activated" : "\(activation.remainingForTarget) to go")
                                .font(Brand.mono(13, weight: .semibold))
                                .foregroundStyle(activation.isActivated ? Brand.live : Brand.warn)
                        }
                        ProgressBar(value: Double(activation.qsoCount), target: Double(activation.kind.qsoTarget))
                    }
                    .glassCard()
                }
                if !activation.notes.isEmpty {
                    Text(activation.notes).font(.subheadline).foregroundStyle(Brand.text2)
                        .frame(maxWidth: .infinity, alignment: .leading).glassCard()
                }

                HStack {
                    SectionHeader(title: "Contacts (\(activation.qsoCount))")
                    Spacer()
                    Button { Haptics.tap(); showAddQSO = true } label: {
                        Label("Add", systemImage: "plus.circle").font(.subheadline)
                    }
                }
                if activation.qsos.isEmpty {
                    Text("No contacts logged for this outing yet.")
                        .font(.subheadline).foregroundStyle(Brand.text2)
                        .frame(maxWidth: .infinity, alignment: .leading).glassCard()
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(sortedQSOs) { q in
                            NavigationLink(value: q) { miniRow(q) }.buttonStyle(.plain)
                        }
                    }
                }

                Button(role: .destructive) { confirmDelete = true } label: {
                    Label("Delete outing", systemImage: "trash").frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle()).tint(Brand.danger).padding(.top, 4)
            }
            .padding(16)
        }
        .background(Brand.pageBackground)
        .navigationTitle(activation.title).navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: QSO.self) { QSODetailView(qso: $0) }
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Edit") { showEdit = true } } }
        .sheet(isPresented: $showEdit) { ActivationEditView(activation: activation) }
        .sheet(isPresented: $showAddQSO) { QSOEditView(qso: nil, presetActivation: activation) }
        .alert("Delete this outing?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) {
                context.delete(activation); try? context.save(); Haptics.warning(); dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This also deletes its \(activation.qsoCount) contacts.") }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: activation.kind.icon).font(.title2).foregroundStyle(Brand.text)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(activation.kind.rawValue).font(.headline).foregroundStyle(Brand.text)
                    if !activation.reference.isEmpty {
                        Text(activation.reference).font(Brand.mono(13)).foregroundStyle(Brand.text2)
                    }
                }
                Spacer()
            }
            HStack(spacing: 6) {
                if !activation.grid.isEmpty { Chip(text: activation.grid, system: "globe") }
                Chip(text: dateString)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).glassCard(padding: 18)
    }

    private var dateString: String {
        activation.date.formatted(.dateTime.month().day().year())
    }

    private var statsGrid: some View {
        HStack(spacing: 12) {
            StatTile(value: "\(activation.qsoCount)", label: "Contacts")
            StatTile(value: "\(uniqueGrids)", label: "Grids")
            StatTile(value: farthestKm.map { unit.format(km: $0) } ?? "—", label: "Farthest",
                     accent: Brand.info)
        }
    }

    private func miniRow(_ q: QSO) -> some View {
        HStack {
            Text(q.callsign).font(.subheadline.weight(.semibold)).foregroundStyle(Brand.text)
            if q.confirmed {
                Image(systemName: "checkmark.seal.fill").font(.caption2).foregroundStyle(Brand.live)
                    .accessibilityLabel("Confirmed")
            }
            Spacer()
            Chip(text: q.band.label); Chip(text: q.mode.rawValue)
            Text(q.dateTime, format: .dateTime.hour().minute())
                .font(Brand.mono(12)).foregroundStyle(Brand.text3)
        }
        .glassCard(padding: 12)
    }
}
