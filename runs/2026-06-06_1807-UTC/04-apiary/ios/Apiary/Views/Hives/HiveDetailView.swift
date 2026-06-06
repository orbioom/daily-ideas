import SwiftUI
import SwiftData
import Charts

struct HiveDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("massUnit") private var massRaw = MassUnit.kg.rawValue
    @Bindable var hive: Hive

    @State private var showEdit = false
    @State private var confirmDelete = false
    @State private var editingInspection: Inspection?
    @State private var editingTreatment: Treatment?
    @State private var editingHarvest: Harvest?
    @State private var addInspection = false
    @State private var addTreatment = false
    @State private var addHarvest = false

    private var mass: MassUnit { MassUnit(rawValue: massRaw) ?? .kg }
    private var inspections: [Inspection] { hive.inspections.sorted { $0.date > $1.date } }
    private var treatments: [Treatment] { hive.treatments.sorted { $0.startDate > $1.startDate } }
    private var harvests: [Harvest] { hive.harvests.sorted { $0.date > $1.date } }
    private var miteSeries: [Inspection] { hive.inspections.sorted { $0.date < $1.date } }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCard
                if BeeLogic.swarmRisk(for: hive) || BeeLogic.miteAlert(for: hive) {
                    alertsCard
                }
                if let latest = hive.latestInspection { latestCard(latest) }
                if miteSeries.filter({ $0.mitesPer300 > 0 }).count >= 2 { miteChart }

                listSection(title: "Inspections", add: { addInspection = true }) {
                    if inspections.isEmpty { emptyRow("No inspections logged yet.") }
                    ForEach(inspections) { i in
                        Button { editingInspection = i } label: { inspectionRow(i) }.buttonStyle(.plain)
                    }
                }
                listSection(title: "Treatments", add: { addTreatment = true }) {
                    if treatments.isEmpty { emptyRow("No treatments recorded.") }
                    ForEach(treatments) { t in
                        Button { editingTreatment = t } label: { treatmentRow(t) }.buttonStyle(.plain)
                    }
                }
                listSection(title: "Harvests", add: { addHarvest = true }) {
                    if harvests.isEmpty { emptyRow("No harvests recorded.") }
                    ForEach(harvests) { h in
                        Button { editingHarvest = h } label: { harvestRow(h) }.buttonStyle(.plain)
                    }
                }

                Button(role: .destructive) { confirmDelete = true } label: {
                    Label("Delete hive", systemImage: "trash").frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle()).tint(Brand.danger)
            }
            .padding(16)
        }
        .background(Brand.pageBackground)
        .navigationTitle(hive.name).navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Edit") { showEdit = true } } }
        .sheet(isPresented: $showEdit) { HiveEditView(hive: hive) }
        .sheet(isPresented: $addInspection) { InspectionEditView(inspection: nil, hive: hive) }
        .sheet(isPresented: $addTreatment) { TreatmentEditView(treatment: nil, hive: hive) }
        .sheet(isPresented: $addHarvest) { HarvestEditView(harvest: nil, hive: hive) }
        .sheet(item: $editingInspection) { InspectionEditView(inspection: $0, hive: hive) }
        .sheet(item: $editingTreatment) { TreatmentEditView(treatment: $0, hive: hive) }
        .sheet(item: $editingHarvest) { HarvestEditView(harvest: $0, hive: hive) }
        .alert("Delete this hive?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) {
                context.delete(hive); try? context.save(); Haptics.warning(); dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Removes the hive and all its inspections, treatments, and harvests.") }
    }

    // MARK: - Cards

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HealthPill(health: BeeLogic.health(for: hive))
                Spacer()
                Chip(text: hive.status.rawValue, tint: hive.status.isLive ? Brand.live : Brand.text2)
            }
            HStack(spacing: 10) {
                QueenDot(year: hive.queenYear, size: 22)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Queen \(String(hive.queenYear)) · \(BeeLogic.queenColorName(year: hive.queenYear))")
                        .font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                    Text(hive.queenMarked ? "Marked" : "Unmarked")
                        .font(.caption).foregroundStyle(Brand.text3)
                }
                Spacer()
            }
            HStack(spacing: 6) {
                Chip(text: hive.kind.rawValue)
                Chip(text: "Est. " + hive.establishedDate.formatted(.dateTime.month().year()))
            }
            if !hive.notes.isEmpty {
                Text(hive.notes).font(.footnote).foregroundStyle(Brand.text2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).glassCard(padding: 18)
    }

    private var alertsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            if BeeLogic.swarmRisk(for: hive) {
                Label("Swarm risk — queen cells in a crowded colony. Consider splitting or adding space.",
                      systemImage: "bolt.fill").foregroundStyle(Brand.danger)
            }
            if BeeLogic.miteAlert(for: hive), let m = hive.latestInspection?.mitesPer300 {
                Label("Varroa at \(m)/300 (\(String(format: "%.1f", Double(m)/3.0))%) — at or over the treat threshold.",
                      systemImage: "ant.fill").foregroundStyle(Brand.danger)
            }
        }
        .font(.footnote).frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(padding: 16)
    }

    private func latestCard(_ i: Inspection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack { Eyebrow(text: "Latest inspection"); Spacer()
                Text(i.date, format: .dateTime.month().day()).font(Brand.mono(12)).foregroundStyle(Brand.text3) }
            HStack(spacing: 10) {
                statusTag("Queen", i.queenSeen ? "Seen" : (i.eggsSeen ? "Eggs" : "—"),
                          i.queenSeen || i.eggsSeen ? Brand.live : Brand.danger)
                statusTag("Temperament", i.temperament.rawValue, Brand.text2)
                statusTag("Space", i.space.rawValue, i.space == .crowded ? Brand.warn : Brand.text2)
            }
            ratingRow("Brood", i.brood)
            ratingRow("Population", i.population)
            ratingRow("Stores", i.stores)
        }
        .frame(maxWidth: .infinity, alignment: .leading).glassCard(padding: 18)
    }

    private var miteChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Varroa trend (per 300 bees)")
            Chart {
                ForEach(miteSeries) { i in
                    LineMark(x: .value("Date", i.date), y: .value("Mites", i.mitesPer300))
                        .foregroundStyle(Brand.info)
                    PointMark(x: .value("Date", i.date), y: .value("Mites", i.mitesPer300))
                        .foregroundStyle(i.mitesPer300 >= BeeLogic.mitesThresholdPer300 ? Brand.danger : Brand.info)
                }
                RuleMark(y: .value("Threshold", BeeLogic.mitesThresholdPer300))
                    .foregroundStyle(Brand.danger.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .annotation(position: .top, alignment: .leading) {
                        Text("treat").font(Brand.mono(9)).foregroundStyle(Brand.danger)
                    }
            }
            .frame(height: 160)
        }
        .frame(maxWidth: .infinity, alignment: .leading).glassCard(padding: 18)
    }

    // MARK: - Rows

    private func listSection<C: View>(title: String, add: @escaping () -> Void,
                                      @ViewBuilder content: () -> C) -> some View {
        VStack(spacing: 10) {
            HStack {
                SectionHeader(title: title)
                Spacer()
                Button { Haptics.tap(); add() } label: { Label("Add", systemImage: "plus.circle").font(.subheadline) }
            }
            content()
        }
    }
    private func emptyRow(_ text: String) -> some View {
        Text(text).font(.subheadline).foregroundStyle(Brand.text2)
            .frame(maxWidth: .infinity, alignment: .leading).glassCard()
    }
    private func inspectionRow(_ i: Inspection) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(i.date, format: .dateTime.weekday().month().day())
                    .font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                HStack(spacing: 6) {
                    Chip(text: i.queenSeen ? "Queen ✓" : (i.eggsSeen ? "Eggs" : "No queen"),
                         tint: i.queenSeen || i.eggsSeen ? Brand.text2 : Brand.danger)
                    if i.queenCells > 0 { Chip(text: "\(i.queenCells) cells", tint: Brand.warn) }
                    Chip(text: "\(i.mitesPer300) mites",
                         tint: i.mitesPer300 >= BeeLogic.mitesThresholdPer300 ? Brand.danger : Brand.text2)
                }
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Brand.text3)
        }
        .glassCard(padding: 14)
    }
    private func treatmentRow(_ t: Treatment) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(t.product).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                Text("\(t.reason) · started \(t.startDate.formatted(.dateTime.month().day()))")
                    .font(.caption).foregroundStyle(Brand.text2)
            }
            Spacer()
            if t.completed { Chip(text: "Done", system: "checkmark", tint: Brand.live) }
            else if t.isOverdue { Chip(text: "Overdue", system: "exclamationmark", tint: Brand.danger) }
            else { Chip(text: "\(t.daysRemaining)d left", tint: t.isDueSoon ? Brand.warn : Brand.text2) }
        }
        .glassCard(padding: 14)
    }
    private func harvestRow(_ h: Harvest) -> some View {
        HStack {
            Image(systemName: h.type.icon).foregroundStyle(Brand.warn).frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(h.type.rawValue).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                Text(h.date, format: .dateTime.month().day().year()).font(.caption).foregroundStyle(Brand.text2)
            }
            Spacer()
            Text(mass.format(kg: h.weightKg)).font(Brand.mono(14, weight: .semibold)).foregroundStyle(Brand.text)
        }
        .glassCard(padding: 14)
    }

    private func statusTag(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased()).font(Brand.mono(9, weight: .medium)).tracking(0.8).foregroundStyle(Brand.text3)
            Text(value).font(Brand.mono(13, weight: .semibold)).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    private func ratingRow(_ label: String, _ r: Rating) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(Brand.text2)
            Spacer()
            RatingBar(rating: r, tint: Brand.warn)
        }
    }
}
