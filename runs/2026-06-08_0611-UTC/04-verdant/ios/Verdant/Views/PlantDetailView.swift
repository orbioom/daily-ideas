import SwiftUI
import SwiftData

struct PlantDetailView: View {
    @Bindable var plant: Plant
    @AppStorage("verdant.seasonal") private var seasonalAdjust = true
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showEdit = false
    @State private var showDeleteConfirm = false
    @State private var showNoteEntry = false
    @State private var noteText = ""

    private var now: Date { Date() }

    private var waterDue: Date? {
        CareEngine.nextWaterDue(plant: plant, seasonalAdjust: seasonalAdjust, now: now)
    }
    private var fertilizeDue: Date? {
        CareEngine.nextFertilizeDue(plant: plant, now: now)
    }
    private var careStatus: CareStatus {
        CareEngine.status(plant: plant, seasonalAdjust: seasonalAdjust, now: now)
    }

    private var sortedCareLog: [CareEvent] {
        plant.careLog.sorted { $0.date > $1.date }
    }

    var body: some View {
        ZStack {
            Brand.pageBackground

            ScrollView {
                VStack(spacing: 20) {
                    heroCard
                    scheduleCard
                    quickActions
                    careHistory
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(plant.nickname)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showEdit = true
                    } label: {
                        Label("Edit Plant", systemImage: "pencil")
                    }

                    Button {
                        withAnimation(reduceMotion ? .none : Brand.ease()) {
                            plant.archived.toggle()
                        }
                        Haptics.tap()
                    } label: {
                        Label(plant.archived ? "Unarchive" : "Archive", systemImage: plant.archived ? "tray.and.arrow.up.fill" : "archivebox.fill")
                    }

                    Divider()

                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete Plant", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .accessibilityLabel("Plant options")
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            AddEditPlantView(editingPlant: plant)
        }
        .alert("Delete \(plant.nickname)?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                modelContext.delete(plant)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove the plant and all its care history.")
        }
        .sheet(isPresented: $showNoteEntry) {
            noteEntrySheet
        }
    }

    private var heroCard: some View {
        GlassCard {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(hex: plant.colorHex).opacity(0.18))
                        .frame(width: 72, height: 72)
                    Image(systemName: plant.symbol)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(Color(hex: plant.colorHex))
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 6) {
                    Text(plant.species.isEmpty ? "Unknown species" : plant.species)
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)

                    HStack(spacing: 8) {
                        StatusDotLabel(status: careStatus)
                    }

                    if let room = plant.room {
                        HStack(spacing: 4) {
                            Image(systemName: room.symbol)
                                .font(.caption2)
                                .accessibilityHidden(true)
                            Text(room.name)
                                .font(.caption)
                        }
                        .foregroundStyle(Brand.text3)
                    }
                }

                Spacer()
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var scheduleCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Eyebrow(text: "Care Schedule")

                HStack(spacing: 12) {
                    Image(systemName: plant.light.symbol)
                        .foregroundStyle(plant.light.color)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Light")
                            .font(.caption)
                            .foregroundStyle(Brand.text3)
                        Text(plant.light.label)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Brand.text)
                    }
                    Spacer()
                    if !plant.potSize.isEmpty {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Pot")
                                .font(.caption)
                                .foregroundStyle(Brand.text3)
                            Text(plant.potSize)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Brand.text)
                        }
                    }
                }

                Divider().background(Brand.hairline)

                scheduleRow(
                    icon: "drop.fill",
                    color: Brand.info,
                    label: "Water",
                    interval: Format.intervalLabel(days: plant.wateringIntervalDays),
                    lastDate: plant.lastWatered,
                    nextDate: waterDue
                )

                if plant.fertilizeIntervalDays > 0 {
                    Divider().background(Brand.hairline)

                    scheduleRow(
                        icon: "sparkles",
                        color: Brand.magic,
                        label: "Fertilize",
                        interval: Format.intervalLabel(days: plant.fertilizeIntervalDays),
                        lastDate: plant.lastFertilized,
                        nextDate: fertilizeDue
                    )
                }
            }
        }
    }

    private func scheduleRow(icon: String, color: Color, label: String, interval: String, lastDate: Date?, nextDate: Date?) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Brand.text)
                Text(interval)
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let next = nextDate {
                    Text(Format.relativeDue(from: next))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(dueDateColor(next))
                } else {
                    Text("Skipped (winter)")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                }
                if let last = lastDate {
                    Text("Last: \(Format.relativePast(from: last))")
                        .font(.caption2)
                        .foregroundStyle(Brand.text3)
                } else {
                    Text("Never done")
                        .font(.caption2)
                        .foregroundStyle(Brand.text3)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func dueDateColor(_ date: Date) -> Color {
        let days = CareEngine.daysUntil(date, now: now)
        if days < 0  { return Brand.danger }
        if days == 0 { return Brand.warn }
        if days <= 2 { return Brand.warn }
        return Brand.live
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Quick Actions")
            GlassCard {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                    QuickActionButton(type: .water) { logEvent(.water) }
                    QuickActionButton(type: .fertilize) { logEvent(.fertilize) }
                    QuickActionButton(type: .mist) { logEvent(.mist) }
                    QuickActionButton(type: .repot) { logEvent(.repot) }
                    QuickActionButton(type: .prune) { logEvent(.prune) }
                    QuickActionButton(type: .note) { showNoteEntry = true }
                }
            }
        }
    }

    private var careHistory: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Care History")

            if sortedCareLog.isEmpty {
                GlassCard {
                    EmptyStateView(
                        icon: "clock.arrow.circlepath",
                        title: "No events yet",
                        message: "Use Quick Actions above to log your first care event."
                    )
                }
            } else {
                GlassCard(padding: 0) {
                    LazyVStack(spacing: 0) {
                        ForEach(sortedCareLog) { event in
                            careEventRow(event)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)

                            if event.id != sortedCareLog.last?.id {
                                Divider()
                                    .background(Brand.hairline)
                                    .padding(.leading, 56)
                            }
                        }
                    }
                }
            }
        }
    }

    private func careEventRow(_ event: CareEvent) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(event.type.color.opacity(0.14))
                    .frame(width: 36, height: 36)
                Image(systemName: event.type.symbol)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(event.type.color)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.type.label)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Brand.text)
                if !event.note.isEmpty {
                    Text(event.note)
                        .font(.caption)
                        .foregroundStyle(Brand.text2)
                }
            }

            Spacer()

            Text(Format.relativePast(from: event.date))
                .font(.caption)
                .foregroundStyle(Brand.text3)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(event.type.label), \(Format.relativePast(from: event.date))\(event.note.isEmpty ? "" : ", \(event.note)")")
    }

    private var noteEntrySheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextEditor(text: $noteText)
                    .frame(minHeight: 120)
                    .padding(12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Brand.hairline, lineWidth: 0.5))
                    .padding(.horizontal, 16)
                    .accessibilityLabel("Note text")

                Spacer()
            }
            .padding(.top, 16)
            .navigationTitle("Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        noteText = ""
                        showNoteEntry = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        logEvent(.note, note: noteText)
                        noteText = ""
                        showNoteEntry = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func logEvent(_ type: CareType, note: String = "") {
        let now = Date()
        switch type {
        case .water:
            plant.lastWatered = now
        case .fertilize:
            plant.lastFertilized = now
        default:
            break
        }
        let event = CareEvent(date: now, type: type, note: note, plant: plant)
        modelContext.insert(event)
        plant.careLog.append(event)
        Haptics.success()
    }
}
