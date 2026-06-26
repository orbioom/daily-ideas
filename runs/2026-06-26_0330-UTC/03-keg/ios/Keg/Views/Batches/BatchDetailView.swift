import SwiftUI
import SwiftData
import Charts

struct BatchDetailView: View {
    @Bindable var batch: BrewBatch
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var settingsAll: [KegSettings]

    @State private var showingEdit = false
    @State private var showingAddLog = false
    @State private var showingDeleteAlert = false

    var useMetric: Bool { settingsAll.first?.useMetric ?? true }
    var useCelsius: Bool { settingsAll.first?.useCelsius ?? true }

    var sortedLogs: [FermentationLog] {
        batch.fermentationLogs.sorted { $0.date < $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Batch #\(batch.batchNumber)")
                            .font(.headline)
                        Text(batch.brewDate, style: .date)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    StatusBadge(status: batch.status)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // Stats
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    if batch.actualOG > 0 {
                        StatTile(title: "Actual OG", value: batch.actualOG.gravityDisplay, color: .blue)
                    }
                    if batch.actualFG > 0 {
                        StatTile(title: "Actual FG", value: batch.actualFG.gravityDisplay, color: .purple)
                        StatTile(title: "ABV", value: String(format: "%.1f%%", batch.actualABV), color: KegTheme.accent)
                        if let att = batch.attenuation {
                            StatTile(title: "Attenuation", value: String(format: "%.0f%%", att), color: .green)
                        }
                    }
                    if batch.actualVolumeLiters > 0 {
                        StatTile(title: "Volume", value: volumeDisplay(batch.actualVolumeLiters, useMetric: useMetric), color: .orange)
                    }
                    StatTile(title: "Ferment Temp", value: tempDisplay(batch.fermentationTempC, useCelsius: useCelsius), color: Color(red: 0.2, green: 0.6, blue: 0.9))
                }

                // Fermentation chart
                if sortedLogs.count >= 2 {
                    FermentationChart(logs: sortedLogs)
                }

                // Fermentation log
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Fermentation Log", systemImage: "chart.line.uptrend.xyaxis")
                            .font(.headline)
                        Spacer()
                        Button {
                            showingAddLog = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(KegTheme.accent)
                        }
                        .accessibilityLabel("Add fermentation reading")
                    }

                    if sortedLogs.isEmpty {
                        Text("Log gravity and temperature readings as fermentation progresses.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(sortedLogs) { log in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(log.date, style: .date)
                                        .font(.subheadline.bold())
                                    if !log.notes.isEmpty {
                                        Text(log.notes)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(log.gravity.gravityDisplay)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(KegTheme.accent)
                                    Text(tempDisplay(log.tempC, useCelsius: useCelsius))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(10)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Reading on \(log.date.formatted(date: .long, time: .omitted)): gravity \(log.gravity.gravityDisplay), temperature \(tempDisplay(log.tempC, useCelsius: useCelsius))")
                        }
                        .onDelete { offsets in
                            for i in offsets {
                                context.delete(sortedLogs[i])
                            }
                            try? context.save()
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // Notes
                if !batch.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Notes", systemImage: "note.text")
                            .font(.headline)
                        Text(batch.notes)
                            .font(.body)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Batch #\(batch.batchNumber)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showingEdit = true } label: {
                        Label("Edit Batch", systemImage: "pencil")
                    }
                    Divider()
                    Button("Delete Batch", role: .destructive) {
                        showingDeleteAlert = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            BatchEditorView(recipe: batch.recipe, batch: batch)
        }
        .sheet(isPresented: $showingAddLog) {
            FermentationLogEditor(batch: batch)
        }
        .alert("Delete Batch?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                context.delete(batch)
                try? context.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All fermentation logs for this batch will also be deleted.")
        }
    }
}

private struct FermentationChart: View {
    let logs: [FermentationLog]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Gravity Over Time")
                .font(.headline)
            Chart(logs) { log in
                LineMark(
                    x: .value("Date", log.date),
                    y: .value("Gravity", log.gravity)
                )
                .foregroundStyle(KegTheme.accent)
                .lineStyle(StrokeStyle(lineWidth: 2))
                PointMark(
                    x: .value("Date", log.date),
                    y: .value("Gravity", log.gravity)
                )
                .foregroundStyle(KegTheme.accent)
                .symbolSize(40)
            }
            .frame(height: 150)
            .chartYScale(domain: .automatic(includesZero: false))
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { val in
                    AxisValueLabel {
                        if let d = val.as(Date.self) {
                            Text(d, format: .dateTime.month(.abbreviated).day())
                                .font(.caption2)
                        }
                    }
                    AxisGridLine()
                }
            }
            .chartYAxis {
                AxisMarks { val in
                    AxisValueLabel {
                        if let v = val.as(Double.self) {
                            Text(v.gravityDisplay).font(.caption2)
                        }
                    }
                    AxisGridLine()
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct FermentationLogEditor: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let batch: BrewBatch

    @State private var date = Date()
    @State private var gravity: Double = 1.020
    @State private var tempC: Double = 20
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Reading") {
                    DatePicker("Date", selection: $date, displayedComponents: [.date])
                    GravitySliderRow(label: "Gravity", value: $gravity, range: 1.000...1.120, step: 0.001)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Temperature")
                            Spacer()
                            Text(String(format: "%.1f°C", tempC))
                                .foregroundStyle(KegTheme.accent)
                        }
                        Slider(value: $tempC, in: 0...40, step: 0.5)
                            .tint(Color(red: 0.2, green: 0.6, blue: 0.9))
                    }
                }
                Section("Notes") {
                    TextField("Optional observation", text: $notes)
                }
            }
            .navigationTitle("Log Reading")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let log = FermentationLog(date: date, gravity: gravity, tempC: tempC, notes: notes)
                        log.batch = batch
                        context.insert(log)
                        try? context.save()
                        dismiss()
                    }
                }
            }
        }
    }
}

struct BatchEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let recipe: Recipe?
    let batch: BrewBatch?

    @State private var batchNumber = 1
    @State private var brewDate = Date()
    @State private var status = "planned"
    @State private var actualOG: Double = 0
    @State private var actualFG: Double = 0
    @State private var actualVolumeLiters: Double = 0
    @State private var fermentationTempC: Double = 20
    @State private var notes = ""

    let statuses = ["planned","fermenting","conditioning","kegged","bottled","complete"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Batch") {
                    Stepper("Batch #\(batchNumber)", value: $batchNumber, in: 1...999)
                    DatePicker("Brew Date", selection: $brewDate, displayedComponents: [.date])
                    Picker("Status", selection: $status) {
                        ForEach(statuses, id: \.self) { s in
                            Text(BrewBatch(batchNumber: 0, status: s).statusDisplayName).tag(s)
                        }
                    }
                }
                Section("Actuals") {
                    GravitySliderRow(label: "Actual OG", value: $actualOG, range: 0...1.120, step: 0.001)
                    GravitySliderRow(label: "Actual FG", value: $actualFG, range: 0...1.050, step: 0.001)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Volume")
                            Spacer()
                            Text(String(format: "%.1f L", actualVolumeLiters))
                                .foregroundStyle(KegTheme.accent)
                        }
                        Slider(value: $actualVolumeLiters, in: 0...60, step: 0.5)
                            .tint(.orange)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Ferment Temp")
                            Spacer()
                            Text(String(format: "%.1f°C", fermentationTempC))
                                .foregroundStyle(Color(red: 0.2, green: 0.6, blue: 0.9))
                        }
                        Slider(value: $fermentationTempC, in: 5...35, step: 0.5)
                            .tint(Color(red: 0.2, green: 0.6, blue: 0.9))
                    }
                }
                Section("Notes") {
                    TextField("Brew day notes...", text: $notes, axis: .vertical)
                        .lineLimit(4)
                }
            }
            .navigationTitle(batch == nil ? "New Batch" : "Edit Batch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onAppear {
                if let b = batch {
                    batchNumber = b.batchNumber
                    brewDate = b.brewDate
                    status = b.status
                    actualOG = b.actualOG
                    actualFG = b.actualFG
                    actualVolumeLiters = b.actualVolumeLiters
                    fermentationTempC = b.fermentationTempC
                    notes = b.notes
                } else if let r = recipe {
                    batchNumber = r.batches.count + 1
                }
            }
        }
    }

    private func save() {
        if let b = batch {
            b.batchNumber = batchNumber
            b.brewDate = brewDate
            b.status = status
            b.actualOG = actualOG
            b.actualFG = actualFG
            b.actualVolumeLiters = actualVolumeLiters
            b.fermentationTempC = fermentationTempC
            b.notes = notes
        } else {
            let b = BrewBatch(
                batchNumber: batchNumber,
                brewDate: brewDate,
                status: status,
                actualOG: actualOG,
                actualFG: actualFG,
                actualVolumeLiters: actualVolumeLiters,
                fermentationTempC: fermentationTempC,
                notes: notes
            )
            b.recipe = recipe
            context.insert(b)
        }
        try? context.save()
        dismiss()
    }
}
