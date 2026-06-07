import SwiftUI
import SwiftData

struct CropDetailView: View {
    @Bindable var crop: Crop
    @Environment(\.modelContext) private var context
    @State private var showingEdit = false

    private var sched: CropSchedule {
        crop.schedule(springFrost: Season.springFrost(), fallFrost: Season.fallFrost())
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            ScrollView {
                VStack(spacing: 16) {
                    header
                    if !sched.fitsSeason { warningCard }
                    scheduleCard
                    if !sched.successionDates.isEmpty { successionCard }
                    detailsCard
                    if !crop.notes.isEmpty { notesCard }
                }
                .padding(.horizontal, 18).padding(.vertical, 12)
            }
        }
        .navigationTitle(crop.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showingEdit = true } label: { Label("Edit", systemImage: "pencil") }
                    Button {
                        crop.isFavorite.toggle(); try? context.save()
                    } label: { Label(crop.isFavorite ? "Unfavorite" : "Favorite", systemImage: "star") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showingEdit) { CropEditView(crop: crop) }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: crop.category.symbol).font(.system(size: 34, weight: .light))
                .foregroundStyle(Brand.live).accessibilityHidden(true)
            HStack(spacing: 8) {
                Chip(text: crop.category.label)
                Chip(text: crop.tolerance.label, tint: Brand.info)
                Chip(text: "\(crop.spacingInches)\" spacing")
            }
        }
        .frame(maxWidth: .infinity).glassCard(padding: 18)
    }

    private var warningCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle").foregroundStyle(Brand.warn)
                .accessibilityHidden(true)
            Text("With your frost dates this crop barely fits the season — start it indoors or pick a faster variety.")
                .font(.footnote).foregroundStyle(Brand.text2)
        }
        .glassCard(padding: 14)
    }

    private var scheduleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Your schedule", trailing: "\(sched.frostFreeDays) FF days")
            VStack(spacing: 12) {
                if let indoor = sched.indoorSow {
                    MilestoneRow(symbol: "house", label: "Start indoors", date: indoor, tint: Brand.info)
                }
                MilestoneRow(symbol: crop.method == .transplant ? "arrow.up.forward" : "circle.dotted",
                             label: crop.method == .transplant ? "Transplant out" : "Direct sow",
                             date: sched.plantOrSow, tint: Brand.live)
                MilestoneRow(symbol: "basket", label: "First harvest",
                             date: sched.firstHarvest, tint: Brand.magic)
                if let last = sched.lastSafeSow {
                    MilestoneRow(symbol: "calendar.badge.exclamationmark",
                                 label: "Last safe sow", date: last, tint: Brand.warn)
                }
            }
        }
        .glassCard()
    }

    private var successionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Succession sowings",
                          trailing: "every \(crop.successionIntervalDays)d")
            FlowChips(dates: sched.successionDates)
        }
        .glassCard()
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Profile")
            detailRow("Method", crop.method.label)
            detailRow("Days to maturity", "\(crop.daysToMaturity)")
            if crop.method == .transplant {
                detailRow("Start indoors", "\(crop.startIndoorWeeksBefore) wk before frost")
                detailRow("Transplant", offsetLabel(crop.transplantWeeksAfterFrost))
            } else {
                detailRow("Sow", offsetLabel(crop.directSowWeeksAfterFrost))
            }
            detailRow("Frost tolerance", crop.tolerance.label)
        }
        .glassCard()
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: "Notes")
            Text(crop.notes).font(.subheadline).foregroundStyle(Brand.text2)
        }
        .glassCard()
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(Brand.text2)
            Spacer()
            Text(value).font(Brand.mono(13, weight: .medium)).foregroundStyle(Brand.text)
        }
    }

    private func offsetLabel(_ weeks: Int) -> String {
        if weeks == 0 { return "at last frost" }
        return weeks < 0 ? "\(-weeks) wk before frost" : "\(weeks) wk after frost"
    }
}

/// A wrapping set of date chips.
struct FlowChips: View {
    let dates: [Date]
    var body: some View {
        let columns = [GridItem(.adaptive(minimum: 84), spacing: 8)]
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(Array(dates.enumerated()), id: \.offset) { _, d in
                Chip(text: Fmt.date(d), system: "circle.dotted", tint: Brand.live)
            }
        }
    }
}
