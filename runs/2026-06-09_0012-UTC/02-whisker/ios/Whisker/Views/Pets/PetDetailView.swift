import SwiftUI
import SwiftData
import Charts

struct PetDetailView: View {
    @Bindable var pet: Pet
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("whisker.weightUnit") private var unitRaw = WeightUnit.kg.rawValue

    private enum Tab: String, CaseIterable { case overview = "Overview", weight = "Weight", care = "Care", timeline = "Timeline" }
    @State private var tab: Tab = .overview
    @State private var editingPet = false
    @State private var addingWeight = false
    @State private var addingTask = false
    @State private var addingEvent = false
    @State private var editingTask: CareTask?
    @State private var editingEvent: HealthEvent?
    @State private var confirmDelete = false

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .kg }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                Picker("Section", selection: $tab) {
                    ForEach(Tab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                switch tab {
                case .overview: overviewSection
                case .weight: weightSection
                case .care: careSection
                case .timeline: timelineSection
                }
            }
            .padding(20)
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle(pet.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { editingPet = true } label: { Label("Edit pet", systemImage: "pencil") }
                    Button(role: .destructive) { confirmDelete = true } label: { Label("Delete pet", systemImage: "trash") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $editingPet) { PetEditorView(pet: pet) }
        .sheet(isPresented: $addingWeight) { WeightEntrySheet(pet: pet) }
        .sheet(isPresented: $addingTask) { CareTaskEditorView(pet: pet, task: nil) }
        .sheet(isPresented: $addingEvent) { EventEditorView(pet: pet, event: nil) }
        .sheet(item: $editingTask) { CareTaskEditorView(pet: pet, task: $0) }
        .sheet(item: $editingEvent) { EventEditorView(pet: pet, event: $0) }
        .alert("Delete \(pet.name)?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) {
                context.delete(pet); try? context.save(); dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the pet and all their records. This cannot be undone.")
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 10) {
            PetAvatar(pet: pet, size: 84)
            Text([pet.species.title, pet.breed].filter { !$0.isEmpty }.joined(separator: " · "))
                .font(.subheadline).foregroundStyle(Brand.text2)
            HStack(spacing: 22) {
                if let age = PetEngine.ageString(from: pet.birthday) {
                    stat("Age", age)
                }
                if let kg = pet.latestWeightKg {
                    stat("Weight", Format.weight(kg, unit: unit))
                }
                stat("Due", "\(PetEngine.nextDueCount(for: pet))")
            }
        }
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(Brand.mono(17, weight: .semibold)).foregroundStyle(Brand.text)
            Text(label).font(.caption2).foregroundStyle(Brand.text3)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: - Overview

    private var overviewSection: some View {
        VStack(spacing: 16) {
            if !pet.notes.isEmpty {
                GlassCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Eyebrow(text: "Notes")
                        Text(pet.notes).font(.subheadline).foregroundStyle(Brand.text2)
                    }
                }
            }
            actionGrid
            if let next = PetEngine.dueTasks(for: [pet]).first {
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Eyebrow(text: "Next up")
                        HStack {
                            Image(systemName: next.task.kind.icon).foregroundStyle(next.task.kind.tint)
                            Text(next.task.title).foregroundStyle(Brand.text)
                            Spacer()
                            Text(PetEngine.dueLabel(next.daysUntil))
                                .font(.caption)
                                .foregroundStyle(next.bucket == .overdue ? Brand.danger : Brand.text2)
                        }
                    }
                }
            }
        }
    }

    private var actionGrid: some View {
        let cols = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: cols, spacing: 12) {
            quickAction("Weight", "scalemass.fill", Brand.live) { addingWeight = true }
            quickAction("Care task", "checklist", Brand.info) { addingTask = true }
            quickAction("Event", "calendar.badge.plus", Brand.magic) { addingEvent = true }
        }
    }

    private func quickAction(_ label: String, _ icon: String, _ tint: Color, _ action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap(); action()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.title3).foregroundStyle(tint)
                Text(label).font(.caption).foregroundStyle(Brand.text)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
        }
        .accessibilityLabel("Add \(label)")
    }

    // MARK: - Weight

    private var weightSection: some View {
        let series = PetEngine.weightSeries(for: pet)
        return VStack(spacing: 16) {
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Eyebrow(text: "Weight trend")
                        Spacer()
                        if let change = PetEngine.recentChangeKg(for: pet) {
                            let up = change >= 0
                            Label(Format.weight(abs(change), unit: unit),
                                  systemImage: up ? "arrow.up.right" : "arrow.down.right")
                                .font(.caption)
                                .foregroundStyle(up ? Brand.warn : Brand.live)
                        }
                    }
                    if series.count < 2 {
                        Text("Log at least two weights to see a trend.")
                            .font(.subheadline).foregroundStyle(Brand.text3)
                            .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 12)
                    } else {
                        Chart(series) { p in
                            LineMark(x: .value("Date", p.date),
                                     y: .value("Weight", unit.fromKg(p.kilograms)))
                                .foregroundStyle(pet.color.color)
                                .interpolationMethod(.catmullRom)
                            AreaMark(x: .value("Date", p.date),
                                     y: .value("Weight", unit.fromKg(p.kilograms)))
                                .foregroundStyle(pet.color.color.opacity(0.12))
                                .interpolationMethod(.catmullRom)
                        }
                        .frame(height: 190)
                        .chartYScale(domain: .automatic(includesZero: false))
                        .accessibilityLabel("Weight trend for \(pet.name)")
                    }
                }
            }
            Button { Haptics.tap(); addingWeight = true } label: {
                Label("Log weight", systemImage: "plus")
            }
            .buttonStyle(InkButtonStyle())

            entriesList(series)
        }
    }

    private func entriesList(_ series: [PetEngine.WeightPoint]) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: "Entries")
                if series.isEmpty {
                    Text("No weights logged yet.").font(.subheadline).foregroundStyle(Brand.text3)
                } else {
                    ForEach(pet.weights.sorted { $0.date > $1.date }) { w in
                        HStack {
                            Text(Format.weight(w.kilograms, unit: unit))
                                .font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                            Spacer()
                            Text(Format.relativeDay(w.date)).font(.caption).foregroundStyle(Brand.text3)
                            Button {
                                context.delete(w); try? context.save()
                            } label: {
                                Image(systemName: "trash").font(.caption).foregroundStyle(Brand.danger)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Delete weight entry")
                        }
                        .padding(.vertical, 3)
                    }
                }
            }
        }
    }

    // MARK: - Care

    private var careSection: some View {
        VStack(spacing: 16) {
            Button { Haptics.tap(); addingTask = true } label: {
                Label("Add care task", systemImage: "plus")
            }
            .buttonStyle(InkButtonStyle())

            if pet.tasks.isEmpty {
                EmptyStateView(icon: "checklist",
                               title: "No care tasks",
                               message: "Add recurring tasks like feeding, grooming or vet check-ups.")
                    .glassCard()
            } else {
                ForEach(pet.tasks.sorted { $0.nextDue < $1.nextDue }) { task in
                    Button { Haptics.tap(); editingTask = task } label: { careRow(task) }
                        .buttonStyle(.plain)
                }
            }
        }
    }

    private func careRow(_ task: CareTask) -> some View {
        let days = Calendar.current.dateComponents([.day],
                    from: Calendar.current.startOfDay(for: .now),
                    to: Calendar.current.startOfDay(for: task.nextDue)).day ?? 0
        return HStack(spacing: 12) {
            ZStack {
                Circle().fill(task.kind.tint.opacity(0.18)).frame(width: 40, height: 40)
                Image(systemName: task.kind.icon).foregroundStyle(task.kind.tint)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                Text("Every \(task.intervalDays) day\(task.intervalDays == 1 ? "" : "s") · \(PetEngine.dueLabel(days))")
                    .font(.caption).foregroundStyle(task.isActive ? Brand.text3 : Brand.text3.opacity(0.5))
            }
            Spacer()
            if !task.isActive {
                Text("Paused").font(.caption2).foregroundStyle(Brand.text3)
            }
            Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(Brand.text3)
                .accessibilityHidden(true)
        }
        .glassCard(padding: 12)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Timeline

    private var timelineSection: some View {
        VStack(spacing: 16) {
            Button { Haptics.tap(); addingEvent = true } label: {
                Label("Add event", systemImage: "plus")
            }
            .buttonStyle(InkButtonStyle())

            if pet.events.isEmpty {
                EmptyStateView(icon: "calendar",
                               title: "No events",
                               message: "Record vet visits, vaccinations, symptoms and milestones here.")
                    .glassCard()
            } else {
                ForEach(pet.events.sorted { $0.date > $1.date }) { event in
                    Button { Haptics.tap(); editingEvent = event } label: { eventRow(event) }
                        .buttonStyle(.plain)
                }
            }
        }
    }

    private func eventRow(_ event: HealthEvent) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(event.kind.tint.opacity(0.18)).frame(width: 40, height: 40)
                Image(systemName: event.kind.icon).foregroundStyle(event.kind.tint)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                Text("\(event.kind.title) · \(Format.relativeDay(event.date))")
                    .font(.caption).foregroundStyle(Brand.text3)
                if !event.detail.isEmpty {
                    Text(event.detail).font(.caption).foregroundStyle(Brand.text2).lineLimit(2)
                }
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(Brand.text3)
                .accessibilityHidden(true)
        }
        .glassCard(padding: 12)
        .accessibilityElement(children: .combine)
    }
}
