import SwiftUI
import SwiftData

/// The tank's at-a-glance health: score, latest parameters, due tasks.
struct DashboardView: View {
    @Bindable var tank: Tank
    let tanks: [Tank]
    @Binding var selectedTankID: String
    var onAddTank: () -> Void

    @Environment(\.modelContext) private var context
    @AppStorage("tempFahrenheit") private var tempF = false
    @AppStorage("salinitySG") private var salSG = false

    @State private var logging = false
    @State private var editingTank = false

    private var units: Units { Units(tempFahrenheit: tempF, salinitySG: salSG) }
    private var dueTasks: [CareTask] {
        tank.tasks.filter { $0.isOverdue }.sorted { ($0.daysUntilDue ?? -999) < ($1.daysUntilDue ?? -999) }
    }
    private var trackedParams: [WaterParameter] { tank.trackedParameters }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        scoreCard
                        if trackedParams.isEmpty {
                            EmptyStateView(icon: "drop.degreesign", title: "No readings yet",
                                           message: "Log your first test to populate the dashboard.")
                                .glassCard()
                        } else {
                            paramGrid
                        }
                        if !dueTasks.isEmpty { dueCard }
                        Button { logging = true } label: { Label("Log a test", systemImage: "plus.circle") }
                            .buttonStyle(InkButtonStyle())
                    }
                    .padding(.horizontal, 16).padding(.bottom, 28)
                }
            }
            .navigationTitle(tank.name.isEmpty ? "Tank" : tank.name)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { tankMenu } }
            .sheet(isPresented: $logging) { LogReadingView(tank: tank) }
            .sheet(isPresented: $editingTank) { TankEditView(tank: tank, isNew: false) }
        }
    }

    private var tankMenu: some View {
        Menu {
            ForEach(tanks) { t in
                Button { selectedTankID = t.id.uuidString } label: {
                    Label(t.name.isEmpty ? "Untitled" : t.name,
                          systemImage: t.id == tank.id ? "checkmark" : "drop")
                }
            }
            Divider()
            Button { editingTank = true } label: { Label("Edit this tank", systemImage: "pencil") }
            Button { onAddTank() } label: { Label("Add tank", systemImage: "plus") }
        } label: { Image(systemName: "rectangle.stack").accessibilityLabel("Switch or manage tanks") }
    }

    private var scoreCard: some View {
        let score = tank.healthScore
        let pct = Int((score * 100).rounded())
        let tint: Color = score >= 0.8 ? Brand.live : (score >= 0.5 ? Brand.warn : Brand.danger)
        return HStack(spacing: 18) {
            ZStack {
                Circle().stroke(Brand.hairline, lineWidth: 8).frame(width: 76, height: 76)
                Circle().trim(from: 0, to: max(0.001, score))
                    .stroke(tint, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90)).frame(width: 76, height: 76)
                Text("\(pct)%").font(Brand.mono(18, weight: .bold)).foregroundStyle(Brand.text)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Water health").font(.headline).foregroundStyle(Brand.text)
                Text(trackedParams.isEmpty ? "Log tests to compute a score."
                     : "\(trackedParams.filter { ($0.status(for: tank.latest($0)?.value ?? 0)) == .good }.count) of \(trackedParams.count) parameters in ideal range.")
                    .font(.subheadline).foregroundStyle(Brand.text2)
                if tank.volumeLitres > 0 {
                    Text("\(tank.kind.label) · \(Int(tank.volumeLitres)) L").font(.caption).foregroundStyle(Brand.text3)
                }
            }
            Spacer()
        }
        .glassCard()
    }

    private var paramGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(trackedParams) { p in
                if let reading = tank.latest(p) {
                    paramTile(p, reading)
                }
            }
        }
    }

    private func paramTile(_ p: WaterParameter, _ reading: Reading) -> some View {
        let status = p.status(for: reading.value)
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(p.shortName).font(.subheadline.weight(.semibold)).foregroundStyle(Brand.text)
                Spacer()
                Circle().fill(status.tint).frame(width: 9, height: 9)
                    .accessibilityLabel(status.label)
            }
            Text(Fmt.string(p, reading.value, units))
                .font(Brand.mono(20, weight: .semibold)).foregroundStyle(Brand.text)
                .lineLimit(1).minimumScaleFactor(0.6)
            Text("ideal \(Fmt.idealString(p, units))").font(.caption2).foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(padding: 14)
    }

    private var dueCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Due now")
            ForEach(dueTasks.prefix(4)) { task in
                HStack {
                    Image(systemName: "exclamationmark.circle.fill").foregroundStyle(Brand.warn)
                    Text(task.title).font(.subheadline).foregroundStyle(Brand.text)
                    Spacer()
                    Text(dueLabel(task)).font(.caption).foregroundStyle(Brand.text3)
                }
                .padding(.vertical, 2)
            }
        }
        .glassCard()
    }

    private func dueLabel(_ t: CareTask) -> String {
        guard let days = t.daysUntilDue else { return "never done" }
        if days < 0 { return "\(-days)d overdue" }
        if days == 0 { return "today" }
        return "in \(days)d"
    }
}
