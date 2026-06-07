import SwiftUI
import SwiftData

/// Lists the pilot's aircraft profiles with full CRUD entry points.
struct AircraftListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Aircraft.createdAt, order: .reverse) private var aircraft: [Aircraft]
    @AppStorage("datum.confirmDelete") private var confirmDelete = true
    @AppStorage("datum.defaultFuelLbPerGal") private var defaultFuelLbPerGal = 6.0

    @State private var editing: Aircraft?
    @State private var creatingNew = false
    @State private var pendingDelete: Aircraft?

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                content
            }
            .navigationTitle("Aircraft")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        creatingNew = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add aircraft")
                }
            }
            .sheet(isPresented: $creatingNew) {
                AircraftEditView(mode: .create(defaultFuelLbPerGal: defaultFuelLbPerGal))
            }
            .sheet(item: $editing) { ac in
                AircraftEditView(mode: .edit(ac))
            }
            .confirmationDialog(
                "Delete this aircraft?",
                isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                titleVisibility: .visible
            ) {
                Button("Delete aircraft", role: .destructive) {
                    if let ac = pendingDelete { delete(ac) }
                    pendingDelete = nil
                }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            } message: {
                Text("Saved flights are not affected — they keep their own snapshot.")
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if aircraft.isEmpty {
            ScrollView {
                EmptyStateView(
                    icon: "airplane.circle",
                    title: "No aircraft yet",
                    message: "Add an aircraft profile — empty weight, stations and CG envelope — to start planning flights."
                )
                Button {
                    Haptics.tap()
                    creatingNew = true
                } label: {
                    Label("Add aircraft", systemImage: "plus")
                }
                .buttonStyle(InkButtonStyle())
                .padding(.horizontal, 24)
            }
        } else {
            List {
                ForEach(aircraft) { ac in
                    Button {
                        Haptics.selection()
                        editing = ac
                    } label: {
                        AircraftRow(aircraft: ac)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            if confirmDelete { pendingDelete = ac } else { delete(ac) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    private func delete(_ ac: Aircraft) {
        Haptics.warning()
        context.delete(ac)
        try? context.save()
    }
}

/// A single aircraft summary row.
private struct AircraftRow: View {
    let aircraft: Aircraft
    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(aircraft.tailNumber.isEmpty ? "Untitled" : aircraft.tailNumber)
                    .font(Brand.mono(17, weight: .semibold))
                    .foregroundStyle(Brand.text)
                Text(aircraft.model.isEmpty ? "No model" : aircraft.model)
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(Fmt.lb(aircraft.emptyWeight))
                    .font(Brand.mono(15, weight: .medium))
                    .foregroundStyle(Brand.text)
                Text("\(aircraft.stations.count) stations")
                    .font(Brand.mono(10))
                    .foregroundStyle(Brand.text3)
            }
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Brand.text3)
                .accessibilityHidden(true)
        }
        .glassCard()
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(aircraft.tailNumber), \(aircraft.model), empty weight \(Fmt.lb(aircraft.emptyWeight)), \(aircraft.stations.count) stations")
        .accessibilityHint("Opens the aircraft to edit")
    }
}
