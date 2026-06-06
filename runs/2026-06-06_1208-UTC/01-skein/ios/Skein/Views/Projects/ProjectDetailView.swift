import SwiftUI
import SwiftData

/// One project: gauge summary, its counters with quick controls, and the
/// entry point into the full-screen counting session.
struct ProjectDetailView: View {
    @Bindable var project: Project
    @Environment(\.modelContext) private var context
    @AppStorage("unitSystem") private var unitRaw = UnitSystem.imperial.rawValue

    @State private var editing = false
    @State private var counting = false
    @State private var editingCounter: Counter?
    @State private var addingCounter = false

    private var unit: UnitSystem { UnitSystem(rawValue: unitRaw) ?? .imperial }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                if project.hasGauge { gaugeCard }
                countersSection
                if project.status != .frogged { dangerlessFooter }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(Brand.pageBackground)
        .navigationTitle(project.name.isEmpty ? "Project" : project.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { editing = true } label: { Label("Edit project", systemImage: "pencil") }
                    Button { addingCounter = true } label: { Label("Add counter", systemImage: "plus.circle") }
                    Menu("Set status") {
                        ForEach(ProjectStatus.allCases) { s in
                            Button { setStatus(s) } label: {
                                Label(s.label, systemImage: project.status == s ? "checkmark" : "")
                            }
                        }
                    }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $editing) { ProjectEditView(project: project, isNew: false) }
        .sheet(isPresented: $addingCounter) {
            CounterEditView(counter: nil) { addCounter($0) }
        }
        .sheet(item: $editingCounter) { c in
            CounterEditView(counter: c) { _ in try? context.save() }
        }
        .fullScreenCover(isPresented: $counting) {
            CounterSessionView(project: project)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                StatusChip(status: project.status)
                Spacer()
                Pill(text: project.craft.label)
            }
            if !project.yarn.isEmpty || !project.tool.isEmpty {
                HStack(spacing: 16) {
                    if !project.yarn.isEmpty { metaLine("Yarn", project.yarn) }
                    if !project.tool.isEmpty { metaLine(project.craft.toolNoun, project.tool) }
                }
            }
            if !project.notes.isEmpty {
                Text(project.notes).font(.subheadline).foregroundStyle(Brand.text2)
            }
            Button { counting = true } label: {
                Label("Open counting session", systemImage: "hand.tap")
            }
            .buttonStyle(InkButtonStyle())
            .disabled(project.counters.isEmpty)
        }
        .glassCard()
    }

    private func metaLine(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased()).font(Brand.mono(10, weight: .medium)).foregroundStyle(Brand.text3)
            Text(value).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
        }
    }

    private var gaugeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Gauge")
            HStack(spacing: 10) {
                StatTile(value: trimmed(project.gaugeStitches), label: "Sts / \(Int(unit.gaugeSpan))\(unit.shortUnit)")
                StatTile(value: trimmed(project.gaugeRows), label: "Rows / \(Int(unit.gaugeSpan))\(unit.shortUnit)")
                StatTile(value: stitchesPerUnit, label: "Sts / \(unit.shortUnit)")
            }
        }
    }

    private var stitchesPerUnit: String {
        let perInch = project.gaugeStitches / 4.0
        let perUnit = unit == .imperial ? perInch : perInch * 2.54
        return String(format: "%.1f", perUnit)
    }

    private var countersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Eyebrow(text: "Counters")
                Spacer()
                Button { addingCounter = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add counter")
            }
            if project.counters.isEmpty {
                EmptyStateView(icon: "number.circle",
                               title: "No counters",
                               message: "Add a counter for rows, repeats, or increases.")
                    .glassCard()
            } else {
                ForEach(project.orderedCounters) { counter in
                    CounterRow(counter: counter,
                               onEdit: { editingCounter = counter },
                               onDelete: { deleteCounter(counter) },
                               onSave: { try? context.save() })
                }
            }
        }
    }

    private var dangerlessFooter: some View {
        Text("Tip: long sessions read best in the full-screen counter — your screen can stay awake while you work.")
            .font(.footnote).foregroundStyle(Brand.text3)
            .padding(.top, 4)
    }

    private func trimmed(_ d: Double) -> String { d == d.rounded() ? String(Int(d)) : String(format: "%.1f", d) }

    private func setStatus(_ s: ProjectStatus) {
        project.status = s; project.updatedAt = Date(); try? context.save(); Haptics.selection()
    }
    private func addCounter(_ c: Counter) {
        c.sortIndex = (project.counters.map(\.sortIndex).max() ?? -1) + 1
        c.project = project
        project.counters.append(c)
        project.updatedAt = Date()
        try? context.save()
    }
    private func deleteCounter(_ c: Counter) {
        context.delete(c); project.updatedAt = Date(); try? context.save(); Haptics.warning()
    }
}

/// A counter row with inline +/- and quick info.
private struct CounterRow: View {
    @Bindable var counter: Counter
    var onEdit: () -> Void
    var onDelete: () -> Void
    var onSave: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(counter.name).font(.headline).foregroundStyle(Brand.text)
                    if counter.tracksRepeat, let pos = counter.repeatPosition, let rep = counter.repeatNumber {
                        Text("Repeat \(rep) · step \(pos) of \(counter.repeatLength)")
                            .font(.caption).foregroundStyle(Brand.text2)
                    } else if counter.step > 1 {
                        Text("Steps of \(counter.step)").font(.caption).foregroundStyle(Brand.text2)
                    }
                }
                Spacer()
                Menu {
                    Button { onEdit() } label: { Label("Edit", systemImage: "pencil") }
                    Button(role: .destructive) { onDelete() } label: { Label("Delete", systemImage: "trash") }
                } label: { Image(systemName: "ellipsis").foregroundStyle(Brand.text3) }
                    .accessibilityLabel("Counter options")
            }
            HStack(spacing: 16) {
                stepButton("minus", enabled: counter.value > 0) { counter.decrement(); onSave(); Haptics.tap() }
                Text("\(counter.value)")
                    .font(Brand.mono(34, weight: .semibold))
                    .foregroundStyle(Brand.text)
                    .frame(maxWidth: .infinity)
                    .contentTransition(.numericText(value: Double(counter.value)))
                    .accessibilityLabel("\(counter.name) count")
                    .accessibilityValue("\(counter.value)")
                stepButton("plus", enabled: true) { counter.increment(); onSave(); Haptics.tap() }
            }
        }
        .glassCard()
    }

    private func stepButton(_ icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2.weight(.semibold))
                .frame(width: 54, height: 54)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
                .foregroundStyle(Brand.text)
        }
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
        .accessibilityLabel(icon == "plus" ? "Increase" : "Decrease")
    }
}
