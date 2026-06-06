import SwiftUI
import SwiftData

/// One site and the dives logged there.
struct SiteDetailView: View {
    @Bindable var site: DiveSite
    @AppStorage("unitSystem") private var unitRaw = UnitSystem.metric.rawValue
    @State private var editing = false

    private var unit: UnitSystem { UnitSystem(rawValue: unitRaw) ?? .metric }
    private var fmt: DiveFmt { DiveFmt(unit: unit) }
    private var divesByDate: [Dive] { site.dives.sorted { $0.date > $1.date } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    if !site.location.isEmpty {
                        Label(site.location, systemImage: "mappin").font(.subheadline).foregroundStyle(Brand.text2)
                    }
                    HStack(spacing: 10) {
                        StatTile(value: "\(site.diveCount)", label: "Dives")
                        StatTile(value: fmt.depth(site.maxDepthM), label: "Deepest", tint: Brand.text)
                    }
                    if !site.notes.isEmpty { Text(site.notes).font(.subheadline).foregroundStyle(Brand.text) }
                }
                .glassCard()

                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow(text: "Dives here")
                    if divesByDate.isEmpty {
                        EmptyStateView(icon: "book", title: "No dives yet",
                                       message: "Log a dive at this site and it'll appear here.")
                    } else {
                        ForEach(divesByDate) { dive in
                            NavigationLink(value: dive) {
                                HStack {
                                    Image(systemName: dive.type.symbol).foregroundStyle(Brand.text3)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(dive.date.formatted(date: .abbreviated, time: .omitted))
                                            .font(.subheadline).foregroundStyle(Brand.text)
                                        Text("\(fmt.depth(dive.maxDepthM)) · \(fmt.duration(dive.durationMin))")
                                            .font(.caption).foregroundStyle(Brand.text3)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.footnote).foregroundStyle(Brand.text3)
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .glassCard()
            }
            .padding(.horizontal, 16).padding(.bottom, 32)
        }
        .background(Brand.pageBackground)
        .navigationTitle(site.name.isEmpty ? "Site" : site.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Dive.self) { DiveDetailView(dive: $0) }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { editing = true } label: { Image(systemName: "pencil") }.accessibilityLabel("Edit site")
            }
        }
        .sheet(isPresented: $editing) { SiteEditView(site: site, isNew: false) }
    }
}
