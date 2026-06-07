import SwiftUI
import SwiftData

struct SightingsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Sighting.date, order: .reverse) private var sightings: [Sighting]
    @AppStorage("plume.confirmDeletes") private var confirmDeletes = true
    @State private var showingEditor = false
    @State private var pendingDelete: Sighting?

    private var liferIDs: Set<UUID> { LifeListEngine.liferSightingIDs(sightings: sightings) }

    var body: some View {
        NavigationStack {
            Group {
                if sightings.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "binoculars", title: "No sightings yet",
                                       message: "Tap + to log your first bird.")
                        .glassCard().padding()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(sightings) { s in
                                SightingRow(sighting: s, isLifer: liferIDs.contains(s.id))
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            if confirmDeletes { pendingDelete = s }
                                            else { delete(s) }
                                        } label: { Label("Delete", systemImage: "trash") }
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Sightings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); showingEditor = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Log sighting")
                }
            }
            .background(Brand.pageBackground)
            .sheet(isPresented: $showingEditor) { SightingEditView(existing: nil, trip: nil) }
            .confirmationDialog("Delete this sighting?", isPresented: Binding(
                get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                titleVisibility: .visible) {
                Button("Delete", role: .destructive) { if let s = pendingDelete { delete(s) }; pendingDelete = nil }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            }
        }
    }

    private func delete(_ s: Sighting) {
        context.delete(s); try? context.save(); Haptics.warning()
    }
}

struct SightingRow: View {
    let sighting: Sighting
    let isLifer: Bool
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(sighting.species?.commonName ?? "Unknown")
                        .font(.body.weight(.medium)).foregroundStyle(Brand.text)
                    if isLifer { Badge(text: "Lifer", color: Brand.magic) }
                }
                Text("\(sighting.location.isEmpty ? "—" : sighting.location) · \(sighting.date.formatted(.dateTime.month(.abbreviated).day().year()))")
                    .font(.caption).foregroundStyle(Brand.text3)
            }
            Spacer()
            Text("×\(sighting.count)").font(Brand.mono(15, weight: .semibold)).foregroundStyle(Brand.text2)
        }
        .glassCard(padding: 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(sighting.species?.commonName ?? "Unknown"), \(sighting.count) seen\(isLifer ? ", lifer" : "")")
    }
}
