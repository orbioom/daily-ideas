import SwiftUI
import SwiftData

/// Cross-bike maintenance overview: what's due, what's coming soon.
struct HealthView: View {
    @Query private var components: [Component]
    @Query private var bikes: [Bike]
    @AppStorage("cog.miles") private var miles = false

    private var active: [Component] { components.filter { !$0.retired && ($0.lifespanKm > 0 || $0.lifespanDays > 0) } }
    private var due: [Component] { active.filter { WearEngine.status(wear: $0.wear) == .due }.sorted { $0.wear > $1.wear } }
    private var soon: [Component] { active.filter { WearEngine.status(wear: $0.wear) == .soon }.sorted { $0.wear > $1.wear } }
    private var healthy: [Component] { active.filter { WearEngine.status(wear: $0.wear) == .ok }.sorted { $0.wear > $1.wear } }

    var body: some View {
        NavigationStack {
            Group {
                if active.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "gauge.with.dots.needle.bottom.50percent", title: "Nothing to track",
                                       message: "Add components with an expected life to see their wear here.")
                        .glassCard().padding()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            summaryCard
                            if !due.isEmpty { section("Replace now", due, Brand.danger) }
                            if !soon.isEmpty { section("Coming soon", soon, Brand.warn) }
                            if !healthy.isEmpty { section("Healthy", healthy, Brand.live) }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Health")
            .background(Brand.pageBackground)
        }
    }

    private var summaryCard: some View {
        HStack(spacing: 10) {
            StatTile(value: "\(due.count)", label: "Replace", accent: due.isEmpty ? Brand.text : Brand.danger)
            StatTile(value: "\(soon.count)", label: "Soon", accent: soon.isEmpty ? Brand.text : Brand.warn)
            StatTile(value: "\(healthy.count)", label: "Healthy", accent: Brand.live)
        }
    }

    private func section(_ title: String, _ items: [Component], _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack { Circle().fill(color).frame(width: 8, height: 8); SectionTitle(text: title) }
            ForEach(items) { c in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(c.name).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                        Text("· \(c.bike?.name ?? "")").font(.caption).foregroundStyle(Brand.text3)
                        Spacer()
                        Text("\(Int((c.wear * 100).rounded()))%").font(Brand.mono(13, weight: .semibold)).foregroundStyle(color)
                    }
                    MeterBar(fraction: min(1, c.wear), color: color)
                }
                .padding(.vertical, 4)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(c.name) on \(c.bike?.name ?? "bike"), \(Int(c.wear * 100)) percent worn")
                if c.id != items.last?.id { Divider().overlay(Brand.hairline) }
            }
        }
        .glassCard()
    }
}
