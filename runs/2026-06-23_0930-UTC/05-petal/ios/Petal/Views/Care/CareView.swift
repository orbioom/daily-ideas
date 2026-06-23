import SwiftUI
import SwiftData

/// Care tab — the hero screen. Aggregates every due item across all pets into a
/// single Overdue / Today / Soon / Upcoming timeline, with a one-tap complete.
struct CareView: View {
    @Bindable var settings: AppSettings
    @Environment(\.modelContext) private var context
    @Query(sort: \Pet.createdAt) private var pets: [Pet]

    @State private var filter: CareItem.Kind? = nil
    /// Bumped to force timeline recomputation after a completion mutation.
    @State private var refreshToken = 0

    private var allItems: [CareItem] {
        _ = refreshToken
        let items = CareTimeline.build(for: pets)
        guard let filter else { return items }
        return items.filter { $0.kind == filter }
    }

    private var grouped: [(CareItem.Bucket, [CareItem])] {
        CareTimeline.grouped(allItems, soonWindowDays: settings.soonWindowDays)
    }

    var body: some View {
        NavigationStack {
            Group {
                if pets.isEmpty {
                    EmptyStateView(symbol: "checklist",
                                   title: "Nothing to track yet",
                                   message: "Add a pet and their care items to build your timeline.")
                } else if allItems.isEmpty {
                    EmptyStateView(symbol: "checkmark.seal.fill",
                                   title: filter == nil ? "All caught up" : "Nothing here",
                                   message: filter == nil
                                     ? "No upcoming care in the next 60 days. Great job!"
                                     : "No \(filter!.label.lowercased()) items due soon.")
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 22, pinnedViews: []) {
                            summaryStrip
                            ForEach(grouped, id: \.0) { bucket, items in
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Circle().fill(bucket.tint).frame(width: 9, height: 9)
                                        Text(bucket.label)
                                            .font(.headline)
                                            .foregroundStyle(Theme.primaryText)
                                        Text("\(items.count)")
                                            .font(.subheadline)
                                            .foregroundStyle(Theme.secondaryText)
                                    }
                                    ForEach(items) { item in
                                        CareItemRow(item: item, settings: settings) {
                                            complete(item)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .petalScreenBackground()
            .navigationTitle("Care")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { filterMenu }
            }
        }
    }

    private var summaryStrip: some View {
        let overdue = CareTimeline.overdueCount(allItems, soonWindowDays: settings.soonWindowDays)
        let today = allItems.filter { $0.bucket(soonWindowDays: settings.soonWindowDays) == .today }.count
        return HStack(spacing: Theme.Metrics.spacing) {
            summaryTile("\(overdue)", "Overdue", Theme.danger)
            summaryTile("\(today)", "Today", Theme.accent)
            summaryTile("\(allItems.count)", "Upcoming", Theme.secondaryText)
        }
    }

    private func summaryTile(_ value: String, _ label: String, _ tint: Color) -> some View {
        PetalCard {
            VStack(spacing: 4) {
                Text(value).font(.title2.bold()).foregroundStyle(tint)
                Text(label).font(.caption).foregroundStyle(Theme.secondaryText)
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }

    private var filterMenu: some View {
        Menu {
            Button { filter = nil } label: {
                Label("All", systemImage: filter == nil ? "checkmark" : "")
            }
            ForEach([CareItem.Kind.medication, .vaccination, .vetFollowUp, .feeding], id: \.rawValue) { kind in
                Button { filter = kind } label: {
                    Label(kind.label, systemImage: filter == kind ? "checkmark" : kind.symbol)
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
        .accessibilityLabel("Filter care items")
    }

    /// Completes / advances the source item behind a care row.
    private func complete(_ item: CareItem) {
        switch item.kind {
        case .medication:
            if let med = pets.flatMap({ $0.medications }).first(where: { $0.id == item.sourceID }) {
                med.markGiven()
            }
        case .vaccination:
            if let vax = pets.flatMap({ $0.vaccinations }).first(where: { $0.id == item.sourceID }) {
                // Mark booster as administered now; clear the next-due so it leaves the timeline.
                vax.renew(on: .now, nextDue: nil)
            }
        case .vetFollowUp:
            if let visit = pets.flatMap({ $0.vetVisits }).first(where: { $0.id == item.sourceID }) {
                visit.followUpDate = nil
            }
        case .feeding:
            // Feedings are recurring; completing simply gives positive feedback.
            break
        }
        try? context.save()
        Haptics.notify(.success, enabled: settings.hapticsEnabled)
        refreshToken += 1
    }
}

/// A single row in the care timeline.
struct CareItemRow: View {
    let item: CareItem
    let settings: AppSettings
    var onComplete: () -> Void

    var body: some View {
        PetalCard {
            HStack(spacing: 12) {
                PetAvatar(symbol: item.petSymbol, tint: item.petTint, size: 42)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Image(systemName: item.kind.symbol)
                            .font(.caption).foregroundStyle(item.kind.tint)
                            .accessibilityHidden(true)
                        Text(item.title).font(.body.weight(.medium)).foregroundStyle(Theme.primaryText)
                            .lineLimit(1)
                    }
                    Text("\(item.petName)\(item.subtitle.isEmpty ? "" : " · \(item.subtitle)")")
                        .font(.caption).foregroundStyle(Theme.secondaryText).lineLimit(1)
                    let phrase = Fmt.duePhrase(for: item.dueDate)
                    PillLabel(text: item.kind == .feeding ? "\(item.subtitle.isEmpty ? "Feeding" : "") at \(timeText)" : phrase,
                              tint: phrase.contains("overdue") ? Theme.danger : item.kind.tint)
                }
                Spacer()
                Button(action: onComplete) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2).foregroundStyle(Theme.success)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Mark \(item.title) for \(item.petName) done")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.kind.label): \(item.title) for \(item.petName)")
        .accessibilityValue(Fmt.duePhrase(for: item.dueDate))
        .accessibilityHint("Double tap the check to complete")
    }

    private var timeText: String {
        let f = DateFormatter(); f.timeStyle = .short
        return f.string(from: item.dueDate)
    }
}

#Preview {
    CareView(settings: AppSettings(hasOnboarded: true))
        .modelContainer(PersistenceController.preview.container)
}
