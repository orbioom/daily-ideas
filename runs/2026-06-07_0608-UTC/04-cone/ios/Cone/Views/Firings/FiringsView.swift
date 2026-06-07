import SwiftUI
import SwiftData

struct FiringsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Firing.date, order: .reverse) private var firings: [Firing]
    @AppStorage("cone.celsius") private var celsius = false
    @AppStorage("cone.confirmDeletes") private var confirmDeletes = true
    @State private var showingEditor = false
    @State private var pendingDelete: Firing?

    var body: some View {
        NavigationStack {
            Group {
                if firings.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "flame", title: "No firings logged",
                                       message: "Record a ramp schedule and Cone estimates the time and energy cost.")
                        .glassCard().padding()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(firings) { f in
                                NavigationLink { FiringDetailView(firing: f) } label: {
                                    FiringRow(firing: f, celsius: celsius)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        if confirmDeletes { pendingDelete = f } else { delete(f) }
                                    } label: { Label("Delete", systemImage: "trash") }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Firings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); showingEditor = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add firing")
                }
            }
            .background(Brand.pageBackground)
            .sheet(isPresented: $showingEditor) { FiringEditView(existing: nil) }
            .confirmationDialog("Delete this firing?", isPresented: Binding(
                get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                titleVisibility: .visible) {
                Button("Delete", role: .destructive) { if let f = pendingDelete { delete(f) }; pendingDelete = nil }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            }
        }
    }

    private func delete(_ f: Firing) { context.delete(f); try? context.save(); Haptics.warning() }
}

private struct FiringRow: View {
    let firing: Firing
    let celsius: Bool
    private var resultColor: Color {
        switch firing.result {
        case "Success": return Brand.live
        case "Issues": return Brand.warn
        default: return Brand.text3
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(firing.name).font(.headline).foregroundStyle(Brand.text)
                    Text(firing.date, format: .dateTime.month(.abbreviated).day().year())
                        .font(.caption).foregroundStyle(Brand.text3)
                }
                Spacer()
                Text("△\(firing.targetCone)").font(Brand.mono(18, weight: .bold)).foregroundStyle(Brand.text)
            }
            HStack(spacing: 6) {
                Badge(text: firing.kind)
                Badge(text: firing.result, color: resultColor)
                Badge(text: ConeMath.formatHours(firing.totalHours))
                if firing.peakTempF > firing.startTempF {
                    Badge(text: ConeMath.formatTemp(Int(firing.peakTempF), celsius: celsius))
                }
            }
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(firing.name), cone \(firing.targetCone), \(firing.result)")
    }
}
