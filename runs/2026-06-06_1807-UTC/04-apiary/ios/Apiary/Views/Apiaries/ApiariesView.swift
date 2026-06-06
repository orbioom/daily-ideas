import SwiftUI
import SwiftData

struct ApiariesView: View {
    @Query(sort: \Apiary.createdAt) private var apiaries: [Apiary]
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if apiaries.isEmpty {
                    EmptyStateView(icon: "house",
                                   title: "No apiaries yet",
                                   message: "Add your first apiary, then add hives to it. Everything stays on your device.")
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(apiaries) { a in
                                NavigationLink(value: a) { ApiaryRow(apiary: a) }.buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Apiaries")
            .navigationDestination(for: Apiary.self) { ApiaryDetailView(apiary: $0) }
            .navigationDestination(for: Hive.self) { HiveDetailView(hive: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add apiary")
                }
            }
            .sheet(isPresented: $showAdd) { ApiaryEditView(apiary: nil) }
        }
    }
}

private struct ApiaryRow: View {
    let apiary: Apiary
    private var riskCount: Int { apiary.hives.filter { BeeLogic.health(for: $0) == .risk }.count }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(apiary.name).font(.headline).foregroundStyle(Brand.text)
                    if !apiary.location.isEmpty {
                        Text(apiary.location).font(.subheadline).foregroundStyle(Brand.text2)
                    }
                }
                Spacer()
                Text("\(apiary.liveHives.count)/\(apiary.hives.count)")
                    .font(Brand.mono(16, weight: .semibold)).foregroundStyle(Brand.text)
            }
            HStack(spacing: 6) {
                Chip(text: "\(apiary.hives.count) hive\(apiary.hives.count == 1 ? "" : "s")", system: "square.grid.2x2")
                if riskCount > 0 {
                    Chip(text: "\(riskCount) at risk", system: "exclamationmark.triangle", tint: Brand.danger)
                }
            }
        }
        .glassCard()
    }
}
