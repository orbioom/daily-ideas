import SwiftUI
import SwiftData

struct SpoolsView: View {
    @Query(sort: \Spool.purchaseDate, order: .reverse) private var spools: [Spool]
    @AppStorage("hideArchived") private var hideArchived = true
    @State private var showAdd = false
    @State private var search = ""

    private var visible: [Spool] {
        spools.filter { (!hideArchived || !$0.archived)
            && (search.isEmpty || $0.displayName.localizedCaseInsensitiveContains(search)) }
    }
    private var lowCount: Int { spools.filter { !$0.archived && ($0.isLow || $0.isEmpty) }.count }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if spools.isEmpty {
                    EmptyStateView(icon: "circle.circle",
                                   title: "No spools yet",
                                   message: "Add your filament so Spool can track what's left and warn you before you run out.")
                } else {
                    ScrollView {
                        if lowCount > 0 {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Brand.warn)
                                Text("\(lowCount) spool\(lowCount == 1 ? "" : "s") low or empty")
                                    .font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                                Spacer()
                            }
                            .glassCard(padding: 12).padding(.horizontal, 16).padding(.top, 8)
                        }
                        LazyVStack(spacing: 10) {
                            if visible.isEmpty {
                                Text("No spools match.").font(.subheadline)
                                    .foregroundStyle(Brand.text2).padding(.top, 30)
                            }
                            ForEach(visible) { s in
                                NavigationLink(value: s) { SpoolRow(spool: s) }.buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Spools")
            .navigationDestination(for: Spool.self) { SpoolDetailView(spool: $0) }
            .searchable(text: $search, prompt: "Brand, material, color")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add spool")
                }
            }
            .sheet(isPresented: $showAdd) { SpoolEditView(spool: nil) }
        }
    }
}

private struct SpoolRow: View {
    let spool: Spool
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                ColorSwatch(hex: spool.colorHex, size: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text(spool.displayName).font(.headline).foregroundStyle(Brand.text)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        Chip(text: spool.material.rawValue)
                        Chip(text: spool.diameter.label)
                        if spool.archived { Chip(text: "Archived", tint: Brand.text3) }
                    }
                }
                Spacer()
                Text("\(Int(spool.remainingG)) g")
                    .font(Brand.mono(15, weight: .semibold))
                    .foregroundStyle(spool.isLow ? Brand.danger : Brand.text)
            }
            RemainingBar(fraction: spool.fractionRemaining)
            HStack {
                Text("\(Int(spool.fractionRemaining * 100))% · \(String(format: "%.0f m", spool.lengthRemainingM)) left")
                    .font(Brand.mono(12)).foregroundStyle(Brand.text3)
                Spacer()
                if spool.isEmpty { Chip(text: "Empty", system: "xmark.circle", tint: Brand.danger) }
                else if spool.isLow { Chip(text: "Low", system: "exclamationmark.triangle", tint: Brand.warn) }
            }
        }
        .glassCard()
    }
}
