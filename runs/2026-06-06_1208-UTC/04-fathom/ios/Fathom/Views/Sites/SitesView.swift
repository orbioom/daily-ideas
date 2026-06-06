import SwiftUI
import SwiftData

/// Dive sites catalog.
struct SitesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \DiveSite.name) private var sites: [DiveSite]

    @State private var newSite: DiveSite?

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Group {
                    if sites.isEmpty {
                        EmptyStateView(icon: "mappin.and.ellipse", title: "No sites yet",
                                       message: "Sites are created as you log dives, or add one here.")
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(sites) { site in
                                    NavigationLink(value: site) { SiteRow(site: site) }
                                        .buttonStyle(.plain)
                                        .contextMenu {
                                            Button(role: .destructive) { delete(site) } label: { Label("Delete", systemImage: "trash") }
                                        }
                                }
                            }
                            .padding(.horizontal, 16).padding(.bottom, 28)
                        }
                    }
                }
            }
            .navigationTitle("Sites")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { create() } label: { Image(systemName: "plus") }.accessibilityLabel("Add site")
                }
            }
            .navigationDestination(for: DiveSite.self) { SiteDetailView(site: $0) }
            .sheet(item: $newSite) { SiteEditView(site: $0, isNew: true) }
        }
    }

    private func create() { let s = DiveSite(name: ""); context.insert(s); newSite = s; Haptics.tap() }
    private func delete(_ s: DiveSite) { context.delete(s); try? context.save(); Haptics.warning() }
}

private struct SiteRow: View {
    let site: DiveSite
    @AppStorage("unitSystem") private var unitRaw = UnitSystem.metric.rawValue
    private var unit: UnitSystem { UnitSystem(rawValue: unitRaw) ?? .metric }
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "mappin.circle.fill").font(.title2).foregroundStyle(Brand.text2)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(site.name.isEmpty ? "Unnamed site" : site.name).font(.headline).foregroundStyle(Brand.text)
                if !site.location.isEmpty { Text(site.location).font(.caption).foregroundStyle(Brand.text3) }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(site.diveCount)").font(Brand.mono(16, weight: .semibold)).foregroundStyle(Brand.text)
                Text("dives").font(.caption2).foregroundStyle(Brand.text3)
            }
        }
        .glassCard()
    }
}

/// Create or edit a dive site.
struct SiteEditView: View {
    @Bindable var site: DiveSite
    var isNew: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    private var canSave: Bool { !site.name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Site") {
                    TextField("Name", text: $site.name)
                    TextField("Location", text: $site.location)
                }
                Section("Notes") {
                    TextField("Conditions, access, marine life…", text: $site.notes, axis: .vertical).lineLimit(2...8)
                }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle(isNew ? "New Site" : "Edit Site").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { if isNew { context.delete(site) }; dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        site.name = site.name.trimmingCharacters(in: .whitespaces)
                        try? context.save(); Haptics.success(); dismiss()
                    }.disabled(!canSave).fontWeight(.semibold)
                }
            }
        }
    }
}
