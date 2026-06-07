import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ServiceRecord.date, order: .reverse) private var records: [ServiceRecord]
    @Query(sort: \Bike.createdAt) private var bikes: [Bike]
    @AppStorage("cog.miles") private var miles = false
    @AppStorage("cog.confirmDeletes") private var confirmDeletes = true
    @State private var serviceBike: Bike?
    @State private var pendingDelete: ServiceRecord?

    private var totalSpend: Double { records.map { $0.cost }.reduce(0, +) }

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "wrench.and.screwdriver", title: "No service yet",
                                       message: bikes.isEmpty ? "Add a bike first." : "Log maintenance to build a history and track spend.")
                        .glassCard().padding()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            HStack(spacing: 10) {
                                StatTile(value: "\(records.count)", label: "Records")
                                StatTile(value: String(format: "$%.0f", totalSpend), label: "Total spend", accent: Brand.live)
                            }
                            VStack(alignment: .leading, spacing: 10) {
                                SectionTitle(text: "History")
                                ForEach(records) { rec in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("\(rec.action) · \(rec.componentName)")
                                                .font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                                            Text("\(rec.bike?.name ?? "—") · \(rec.date.formatted(.dateTime.month(.abbreviated).day().year()))")
                                                .font(.caption).foregroundStyle(Brand.text3)
                                            if !rec.notes.isEmpty { Text(rec.notes).font(.caption2).foregroundStyle(Brand.text3).lineLimit(2) }
                                        }
                                        Spacer()
                                        if rec.cost > 0 {
                                            Text(String(format: "$%.0f", rec.cost)).font(Brand.mono(14, weight: .semibold)).foregroundStyle(Brand.text2)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            if confirmDeletes { pendingDelete = rec } else { delete(rec) }
                                        } label: { Label("Delete", systemImage: "trash") }
                                    }
                                    if rec.id != records.last?.id { Divider().overlay(Brand.hairline) }
                                }
                            }
                            .glassCard()
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Service")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu { ForEach(bikes) { b in Button(b.name) { serviceBike = b } } }
                    label: { Image(systemName: "plus") }
                    .disabled(bikes.isEmpty).accessibilityLabel("Log service")
                }
            }
            .background(Brand.pageBackground)
            .sheet(item: $serviceBike) { b in ServiceEditView(bike: b) }
            .confirmationDialog("Delete this service record?", isPresented: Binding(
                get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                titleVisibility: .visible) {
                Button("Delete", role: .destructive) { if let r = pendingDelete { delete(r) }; pendingDelete = nil }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            }
        }
    }

    private func delete(_ r: ServiceRecord) { context.delete(r); try? context.save(); Haptics.warning() }
}

struct ServiceEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("cog.miles") private var miles = false
    let bike: Bike

    @State private var date = Date()
    @State private var componentName = ""
    @State private var action = "Replaced"
    @State private var cost = 0.0
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Component").foregroundStyle(Brand.text2); Spacer()
                            Menu {
                                ForEach(bike.activeComponents) { c in Button(c.name) { componentName = c.name } }
                                Button("Other / general") { componentName = "General" }
                            } label: {
                                Text(componentName.isEmpty ? "Choose" : componentName)
                                    .foregroundStyle(componentName.isEmpty ? Brand.text3 : Brand.text)
                            }
                        }
                        Divider().overlay(Brand.hairline)
                        TextField("or type a component", text: $componentName).foregroundStyle(Brand.text)
                        Divider().overlay(Brand.hairline)
                        HStack {
                            Text("Action").foregroundStyle(Brand.text2); Spacer()
                            Picker("Action", selection: $action) { ForEach(WearEngine.serviceActions, id: \.self) { Text($0).tag($0) } }.tint(Brand.text)
                        }
                        Divider().overlay(Brand.hairline)
                        DatePicker("Date", selection: $date, displayedComponents: .date).tint(Brand.text).foregroundStyle(Brand.text2)
                        Divider().overlay(Brand.hairline)
                        HStack {
                            Text("Cost").foregroundStyle(Brand.text2); Spacer()
                            TextField("0", value: $cost, format: .number).keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing).font(Brand.mono(15)).foregroundStyle(Brand.text).frame(width: 90)
                        }
                    }
                    .font(.subheadline).glassCard()
                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle(text: "Notes")
                        TextField("Details…", text: $notes, axis: .vertical).lineLimit(2...5).font(.subheadline).foregroundStyle(Brand.text)
                    }.glassCard()
                }.padding()
            }
            .navigationTitle("Log Service")
            .navigationBarTitleDisplayMode(.inline)
            .background(Brand.pageBackground)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(componentName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let name = componentName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let r = ServiceRecord(date: date, componentName: name, action: action,
                              atKm: bike.odometerKm, cost: max(0, cost), notes: notes)
        r.bike = bike
        context.insert(r)
        try? context.save(); Haptics.success(); dismiss()
    }
}
