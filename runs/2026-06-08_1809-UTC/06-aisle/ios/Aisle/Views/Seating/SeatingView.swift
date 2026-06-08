import SwiftUI
import SwiftData

struct SeatingView: View {
    let wedding: Wedding
    @Environment(\.modelContext) private var context
    @Query(sort: \SeatingTable.createdAt) private var tables: [SeatingTable]
    @Query(sort: \Guest.name) private var guests: [Guest]

    @State private var showAddTable = false
    @State private var editingTable: SeatingTable?
    @State private var assigningTable: SeatingTable?

    private var summary: WeddingEngine.SeatingSummary {
        WeddingEngine.seatingSummary(tables: tables, guests: guests)
    }
    private var unassigned: [Guest] {
        guests.filter { $0.table == nil && ($0.rsvp == .yes || $0.rsvp == .maybe) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                summaryCard
                if !unassigned.isEmpty { unassignedCard }
                if tables.isEmpty {
                    EmptyStateView(icon: "square.grid.3x3",
                                   title: "No tables yet",
                                   message: "Add tables, then assign your attending guests to seats.")
                        .padding(.top, 20)
                } else {
                    ForEach(tables) { table in
                        tableCard(table)
                    }
                }
            }
            .padding()
        }
        .background(Brand.pageBackground)
        .navigationTitle("Seating")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAddTable = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add table")
            }
        }
        .sheet(isPresented: $showAddTable) { TableEditorView(mode: .create) }
        .sheet(item: $editingTable) { t in TableEditorView(mode: .edit(t)) }
        .sheet(item: $assigningTable) { t in TableAssignmentSheet(table: t) }
    }

    private var summaryCard: some View {
        HStack(spacing: 0) {
            stat("\(summary.tableCount)", "tables")
            div
            stat("\(summary.seatsAssigned)/\(summary.seatsCapacity)", "seated")
            div
            stat("\(summary.unassignedHeads)", "to seat",
                 tint: summary.unassignedHeads > 0 ? Brand.warn : Brand.live)
        }
        .glassCard()
    }

    private var unassignedCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: "Not yet seated")
            ForEach(unassigned) { g in
                HStack {
                    Image(systemName: g.rsvp.icon).foregroundStyle(g.rsvp.color)
                    Text(g.name).foregroundStyle(Brand.text)
                    if g.partySize > 1 {
                        Text("(\(g.partySize))").font(.caption).foregroundStyle(Brand.text3)
                    }
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private func tableCard(_ table: SeatingTable) -> some View {
        let seated = table.guests.sorted { $0.name < $1.name }
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(table.name).font(.headline).foregroundStyle(Brand.text)
                Spacer()
                Text("\(table.seatsUsed)/\(table.capacity)")
                    .font(Brand.mono(12))
                    .foregroundStyle(table.isOver ? Brand.danger : Brand.text2)
                Menu {
                    Button("Assign guests", systemImage: "person.badge.plus") { assigningTable = table }
                    Button("Edit table", systemImage: "pencil") { editingTable = table }
                    Button("Delete table", systemImage: "trash", role: .destructive) { delete(table) }
                } label: {
                    Image(systemName: "ellipsis.circle").foregroundStyle(Brand.text3)
                }
                .accessibilityLabel("Table options")
            }
            if table.isOver {
                Label("Over capacity", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption).foregroundStyle(Brand.danger)
            }
            if seated.isEmpty {
                Text("No one seated here yet.").font(.caption).foregroundStyle(Brand.text3)
            } else {
                ForEach(seated) { g in
                    HStack {
                        Image(systemName: g.rsvp.icon).foregroundStyle(g.rsvp.color).font(.caption)
                        Text(g.name).font(.subheadline).foregroundStyle(Brand.text)
                        if g.partySize > 1 {
                            Text("(\(g.partySize))").font(.caption2).foregroundStyle(Brand.text3)
                        }
                        Spacer()
                        Button {
                            g.table = nil; try? context.save(); Haptics.tap()
                        } label: {
                            Image(systemName: "minus.circle").foregroundStyle(Brand.text3)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Remove \(g.name) from \(table.name)")
                    }
                }
            }
            Button { assigningTable = table } label: {
                Label("Assign guests", systemImage: "person.badge.plus")
                    .font(.subheadline.weight(.medium))
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color(hex: 0xB07A8C))
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private var div: some View { Rectangle().fill(Brand.hairline).frame(width: 1, height: 30) }
    private func stat(_ v: String, _ l: String, tint: Color = Brand.text) -> some View {
        VStack(spacing: 2) {
            Text(v).font(.headline).foregroundStyle(tint).minimumScaleFactor(0.6).lineLimit(1)
            Text(l).font(.caption2).foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
    }

    private func delete(_ table: SeatingTable) {
        context.delete(table); try? context.save(); Haptics.warning()
    }
}

/// Assign or remove guests to/from a specific table.
struct TableAssignmentSheet: View {
    @Bindable var table: SeatingTable
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Guest.name) private var guests: [Guest]

    private var candidates: [Guest] {
        guests.filter { $0.rsvp == .yes || $0.rsvp == .maybe }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("Seats used").foregroundStyle(Brand.text2)
                        Spacer()
                        Text("\(table.seatsUsed)/\(table.capacity)")
                            .foregroundStyle(table.isOver ? Brand.danger : Brand.text)
                    }
                }
                Section("Attending guests") {
                    if candidates.isEmpty {
                        Text("No attending guests yet.").font(.subheadline).foregroundStyle(Brand.text2)
                    }
                    ForEach(candidates) { g in
                        Button { toggle(g) } label: {
                            HStack {
                                Image(systemName: g.table == table ? "checkmark.circle.fill" :
                                        (g.table == nil ? "circle" : "circle.slash"))
                                    .foregroundStyle(g.table == table ? Brand.live : Brand.text3)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(g.name).foregroundStyle(Brand.text)
                                    if let other = g.table, other != table {
                                        Text("At \(other.name)").font(.caption2).foregroundStyle(Brand.text3)
                                    } else if g.partySize > 1 {
                                        Text("Party of \(g.partySize)").font(.caption2).foregroundStyle(Brand.text3)
                                    }
                                }
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle(table.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }

    private func toggle(_ g: Guest) {
        if g.table == table { g.table = nil } else { g.table = table }
        try? context.save()
        Haptics.tap()
    }
}
