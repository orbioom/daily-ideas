import SwiftUI
import SwiftData

struct PlanView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Planting.sowDate) private var plantings: [Planting]
    @State private var showingAdd = false

    private var thisYear: [Planting] {
        plantings.filter { $0.year == Season.currentYear }
    }

    /// Plantings still in the planned state whose sow date has arrived or passed.
    private var needsAttention: [Planting] {
        thisYear.filter { $0.status == .planned && $0.sowDate <= FrostMath.addDays(7, to: .now) }
            .sorted { $0.sowDate < $1.sowDate }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 18) {
                        seasonBanner
                        if !needsAttention.isEmpty { attentionCard }
                        timelineSection
                    }
                    .padding(.horizontal, 18).padding(.vertical, 14)
                }
            }
            .navigationTitle("Plan")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add planting")
                }
            }
            .sheet(isPresented: $showingAdd) { PlantingEditView() }
        }
    }

    private var seasonBanner: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow(text: "Season \(Season.currentYear)")
                    Text("\(Season.frostFreeDays) frost-free days")
                        .font(.title3.weight(.bold)).foregroundStyle(Brand.text)
                }
                Spacer()
                StatusDot(color: Brand.live)
            }
            HStack(spacing: 12) {
                StatTile(value: Fmt.date(Season.springFrost()), label: "Spring frost", accent: Brand.info)
                StatTile(value: Fmt.date(Season.fallFrost()), label: "Fall frost", accent: Brand.info)
            }
        }
    }

    private var attentionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Needs attention", trailing: "\(needsAttention.count)")
            ForEach(needsAttention) { p in
                let overdue = p.sowDate < Calendar.current.startOfDay(for: .now)
                HStack {
                    Image(systemName: p.category.symbol).foregroundStyle(overdue ? Brand.warn : Brand.live)
                        .frame(width: 26).accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(p.cropName).font(.subheadline.weight(.semibold)).foregroundStyle(Brand.text)
                        Text(overdue ? "Sow was due \(Fmt.date(p.sowDate))"
                                     : "Sow around \(Fmt.date(p.sowDate))")
                            .font(.caption).foregroundStyle(overdue ? Brand.warn : Brand.text3)
                    }
                    Spacer()
                    Button("Sown") { advance(p, to: p.method == .transplant ? .transplanted : .sown) }
                        .font(.caption.weight(.semibold)).foregroundStyle(Brand.text)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().strokeBorder(Brand.hairline, lineWidth: 1))
                }
                .glassCard(padding: 12)
            }
        }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "This year", trailing: "\(thisYear.count)")
            if thisYear.isEmpty {
                EmptyStateView(icon: "calendar",
                               title: "No plantings yet",
                               message: "Add a planting and Tilth schedules its sow, transplant, and harvest dates from your frost dates.")
            } else {
                ForEach(thisYear) { p in PlantingRow(planting: p) {
                    advance(p, to: nextStatus(p))
                } onDelete: {
                    context.delete(p); try? context.save(); Haptics.tap()
                } }
            }
        }
    }

    private func nextStatus(_ p: Planting) -> PlantingStatus {
        switch p.status {
        case .planned:      return p.method == .transplant ? .transplanted : .sown
        case .sown:         return .harvested
        case .transplanted: return .harvested
        case .harvested:    return .harvested
        }
    }

    private func advance(_ p: Planting, to status: PlantingStatus) {
        guard p.status != status else { return }
        p.status = status
        try? context.save()
        Haptics.success()
    }
}

struct PlantingRow: View {
    let planting: Planting
    var onAdvance: () -> Void
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: planting.category.symbol)
                    .foregroundStyle(Brand.text2).frame(width: 24).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(planting.cropName).font(.headline).foregroundStyle(Brand.text)
                    if let bed = planting.bed {
                        Text(bed.name).font(.caption).foregroundStyle(Brand.text3)
                    }
                }
                Spacer()
                Chip(text: planting.status.label, system: planting.status.symbol,
                     tint: planting.status.tint)
            }
            HStack(spacing: 8) {
                Chip(text: "sow \(Fmt.date(planting.sowDate))", system: "calendar")
                Chip(text: "harvest \(Fmt.date(planting.harvestDate))", system: "basket")
                Chip(text: "×\(planting.quantity)")
            }
        }
        .glassCard()
        .contentShape(Rectangle())
        .onTapGesture { if planting.status != .harvested { onAdvance() } }
        .swipeActions {
            Button(role: .destructive, action: onDelete) { Label("Delete", systemImage: "trash") }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(planting.cropName), \(planting.status.label), sow \(Fmt.dateLong(planting.sowDate)), harvest \(Fmt.dateLong(planting.harvestDate))")
        .accessibilityHint(planting.status == .harvested ? "" : "Double tap to advance status")
    }
}
