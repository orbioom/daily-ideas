import SwiftUI
import SwiftData

struct GarageView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Bike.createdAt) private var bikes: [Bike]
    @AppStorage("cog.miles") private var miles = false
    @AppStorage("cog.confirmDeletes") private var confirmDeletes = true
    @State private var showingEditor = false
    @State private var pendingDelete: Bike?

    var body: some View {
        NavigationStack {
            Group {
                if bikes.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "bicycle", title: "No bikes yet",
                                       message: "Add a bike to start tracking its components and rides.")
                        .glassCard().padding()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(bikes) { bike in
                                NavigationLink { BikeDetailView(bike: bike) } label: { BikeCard(bike: bike, miles: miles) }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            if confirmDeletes { pendingDelete = bike } else { delete(bike) }
                                        } label: { Label("Delete", systemImage: "trash") }
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Garage")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); showingEditor = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add bike")
                }
            }
            .background(Brand.pageBackground)
            .sheet(isPresented: $showingEditor) { BikeEditView(existing: nil) }
            .confirmationDialog("Delete this bike and all its data?", isPresented: Binding(
                get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                titleVisibility: .visible) {
                Button("Delete", role: .destructive) { if let b = pendingDelete { delete(b) }; pendingDelete = nil }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            }
        }
    }

    private func delete(_ b: Bike) { context.delete(b); try? context.save(); Haptics.warning() }
}

private struct BikeCard: View {
    let bike: Bike
    let miles: Bool
    private var dueCount: Int { bike.activeComponents.filter { WearEngine.status(wear: $0.wear) == .due }.count }
    private var soonCount: Int { bike.activeComponents.filter { WearEngine.status(wear: $0.wear) == .soon }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(bike.name).font(.title3.weight(.bold)).foregroundStyle(Brand.text)
                    Text(bike.kind).font(.caption).foregroundStyle(Brand.text3)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(Units.format(bike.odometerKm, miles: miles))
                        .font(Brand.mono(18, weight: .bold)).foregroundStyle(Brand.text)
                    Text("odometer").font(.caption2).foregroundStyle(Brand.text3)
                }
            }
            HStack(spacing: 8) {
                Badge(text: "\(bike.activeComponents.count) parts")
                if dueCount > 0 { Badge(text: "\(dueCount) due", color: Brand.danger) }
                if soonCount > 0 { Badge(text: "\(soonCount) soon", color: Brand.warn) }
                if dueCount == 0 && soonCount == 0 {
                    HStack(spacing: 4) { StatusDot(); Text("All healthy").font(.caption).foregroundStyle(Brand.text2) }
                }
            }
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(bike.name), \(Units.format(bike.odometerKm, miles: miles)), \(dueCount) due")
    }
}

struct BikeEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("cog.miles") private var miles = false
    let existing: Bike?
    @State private var name = ""
    @State private var kind = "Road"
    @State private var odometer = 0.0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Bike name", text: $name).font(.headline).foregroundStyle(Brand.text)
                        Divider().overlay(Brand.hairline)
                        HStack {
                            Text("Type").foregroundStyle(Brand.text2); Spacer()
                            Picker("Type", selection: $kind) { ForEach(WearEngine.bikeKinds, id: \.self) { Text($0).tag($0) } }.tint(Brand.text)
                        }
                        Divider().overlay(Brand.hairline)
                        HStack {
                            Text("Odometer (\(Units.label(miles: miles)))").foregroundStyle(Brand.text2)
                            Spacer()
                            TextField("0", value: $odometer, format: .number).keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing).font(Brand.mono(15)).foregroundStyle(Brand.text).frame(width: 100)
                        }
                    }
                    .font(.subheadline).glassCard()
                }.padding()
            }
            .navigationTitle(existing == nil ? "New Bike" : "Edit Bike")
            .navigationBarTitleDisplayMode(.inline)
            .background(Brand.pageBackground)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let b = existing { name = b.name; kind = b.kind; odometer = Units.kmTo(b.odometerKm, miles: miles) }
            }
        }
    }

    private func save() {
        let t = name.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        let b: Bike
        if let existing { b = existing } else { b = Bike(name: t); context.insert(b) }
        b.name = t; b.kind = kind; b.odometerKm = Units.toKm(max(0, odometer), miles: miles)
        try? context.save(); Haptics.success(); dismiss()
    }
}
