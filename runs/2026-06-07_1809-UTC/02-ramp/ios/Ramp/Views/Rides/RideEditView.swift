import SwiftUI
import SwiftData

/// Add or edit a ride. `ride == nil` means create; otherwise edit in place.
/// Power mode shows the snapshot FTP, IF and live TSS; manual mode takes TSS directly.
struct RideEditView: View {
    let ride: Ride?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \FTPEntry.date, order: .reverse) private var ftpEntries: [FTPEntry]

    @AppStorage("ramp.fallbackFTP") private var fallbackFTP = 250

    @State private var name = ""
    @State private var date = Date()
    @State private var type: RideType = .endurance
    @State private var entry: EntryMode = .power
    @State private var durationText = ""
    @State private var npText = ""
    @State private var tssText = ""
    @State private var distanceText = ""
    @State private var notes = ""
    @State private var showDeleteConfirm = false

    private var isEditing: Bool { ride != nil }

    // Parsed values.
    private var duration: Int { Int(durationText) ?? 0 }
    private var np: Int { Int(npText) ?? 0 }
    private var manualTSS: Double { Double(tssText) ?? 0 }
    private var distance: Double { Double(distanceText) ?? 0 }

    /// FTP that applies on the chosen date (snapshot at log time).
    private var snapshotFTP: Int {
        LoadEngine.ftp(on: date, entries: ftpEntries, fallback: fallbackFTP)
    }

    private var liveIF: Double {
        LoadEngine.intensityFactor(np: np, ftp: snapshotFTP)
    }

    private var liveTSS: Double {
        switch entry {
        case .power:  return LoadEngine.tssFromPower(np: np, ftp: snapshotFTP, durationMin: duration)
        case .manual: return max(0, manualTSS)
        }
    }

    private var durationValid: Bool { duration > 0 }
    private var powerValid: Bool { entry == .manual || np > 0 }
    private var canSave: Bool { durationValid && powerValid }

    var body: some View {
        NavigationStack {
            Form {
                detailsSection
                stressSection
                extrasSection
                if isEditing { deleteSection }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle(isEditing ? "Edit ride" : "New ride")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { Haptics.tap(); dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .onAppear(perform: load)
        }
    }

    // MARK: Sections

    private var detailsSection: some View {
        Section {
            TextField("Name (optional)", text: $name)
                .accessibilityLabel("Ride name")
            DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
            Picker("Type", selection: $type) {
                ForEach(RideType.allCases) { t in
                    Label(t.label, systemImage: t.symbol).tag(t)
                }
            }
            HStack {
                Text("Duration")
                Spacer()
                TextField("min", text: $durationText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                    .font(Brand.mono(15))
                    .accessibilityLabel("Duration in minutes")
                Text("min").foregroundStyle(Brand.text3)
            }
            if !durationValid && !durationText.isEmpty {
                validationRow("Duration must be greater than zero.")
            } else if durationText.isEmpty {
                validationRow("Enter a duration to compute TSS.", calm: true)
            }
        } header: {
            Text("Details")
        }
        .listRowBackground(Brand.mist2.opacity(0.5))
    }

    private var stressSection: some View {
        Section {
            Picker("Entry mode", selection: $entry) {
                ForEach(EntryMode.allCases) { m in Text(m.label).tag(m) }
            }
            .pickerStyle(.segmented)
            .onChange(of: entry) { _, _ in Haptics.selection() }

            if entry == .power {
                HStack {
                    Text("Normalized power")
                    Spacer()
                    TextField("W", text: $npText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .font(Brand.mono(15))
                        .accessibilityLabel("Normalized power in watts")
                    Text("W").foregroundStyle(Brand.text3)
                }
                InfoRow(label: "FTP at this date", value: "\(snapshotFTP) W", mono: true)
                InfoRow(label: "Intensity factor",
                        value: liveIF > 0 ? Format.twoDecimals(liveIF) : "—", mono: true)
                if !powerValid && !npText.isEmpty {
                    validationRow("Power must be greater than zero.")
                }
            } else {
                HStack {
                    Text("TSS")
                    Spacer()
                    TextField("0", text: $tssText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .font(Brand.mono(15))
                        .accessibilityLabel("Training stress score")
                }
            }

            HStack {
                Text("Live TSS").foregroundStyle(Brand.text2)
                Spacer()
                Text(Format.int(liveTSS))
                    .font(Brand.mono(20, weight: .semibold))
                    .foregroundStyle(Brand.live)
                    .contentTransition(.numericText())
                    .animation(Brand.ease(0.3), value: liveTSS)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Computed TSS \(Format.int(liveTSS))")
        } header: {
            Text("Training stress")
        } footer: {
            Text(entry == .power
                 ? "TSS = duration × IF² × 100, where IF = NP ÷ FTP."
                 : "Enter a TSS value from another head unit or app.")
                .font(.caption)
        }
        .listRowBackground(Brand.mist2.opacity(0.5))
    }

    private var extrasSection: some View {
        Section {
            HStack {
                Text("Distance")
                Spacer()
                TextField("0", text: $distanceText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                    .font(Brand.mono(15))
                    .accessibilityLabel("Distance in kilometres")
                Text("km").foregroundStyle(Brand.text3)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Notes").font(.caption).foregroundStyle(Brand.text3)
                TextField("How did it feel?", text: $notes, axis: .vertical)
                    .lineLimit(2...5)
            }
        } header: {
            Text("Extras")
        }
        .listRowBackground(Brand.mist2.opacity(0.5))
    }

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                Haptics.warning(); showDeleteConfirm = true
            } label: {
                Label("Delete ride", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .confirmationDialog("Delete this ride?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) { deleteRide() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This can't be undone.")
            }
        }
        .listRowBackground(Brand.mist2.opacity(0.5))
    }

    private func validationRow(_ text: String, calm: Bool = false) -> some View {
        HStack(spacing: 6) {
            Image(systemName: calm ? "info.circle" : "exclamationmark.triangle")
                .foregroundStyle(calm ? Brand.text3 : Brand.warn)
            Text(text)
                .font(.caption)
                .foregroundStyle(calm ? Brand.text3 : Brand.warn)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Load & save

    private func load() {
        guard let ride else {
            // New ride defaults.
            name = ""
            date = Date()
            type = .endurance
            entry = .power
            durationText = ""
            return
        }
        name = ride.name
        date = ride.date
        type = ride.type
        entry = ride.entry
        durationText = String(ride.durationMin)
        npText = ride.normalizedPower > 0 ? String(ride.normalizedPower) : ""
        tssText = ride.tssManual > 0 ? Format.oneDecimal(ride.tssManual) : ""
        distanceText = ride.distanceKm > 0 ? Format.oneDecimal(ride.distanceKm) : ""
        notes = ride.notes
    }

    private func save() {
        guard canSave else { Haptics.warning(); return }
        let snap = snapshotFTP
        if let ride {
            ride.name = name.trimmingCharacters(in: .whitespaces)
            ride.date = date
            ride.type = type
            ride.entry = entry
            ride.durationMin = duration
            ride.normalizedPower = entry == .power ? np : 0
            ride.ftpAtTime = snap
            ride.tssManual = entry == .manual ? manualTSS : 0
            ride.distanceKm = distance
            ride.notes = notes.trimmingCharacters(in: .whitespaces)
        } else {
            let new = Ride(date: date,
                           name: name.trimmingCharacters(in: .whitespaces),
                           durationMin: duration,
                           type: type,
                           entry: entry,
                           normalizedPower: entry == .power ? np : 0,
                           ftpAtTime: snap,
                           tssManual: entry == .manual ? manualTSS : 0,
                           distanceKm: distance,
                           notes: notes.trimmingCharacters(in: .whitespaces))
            context.insert(new)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }

    private func deleteRide() {
        guard let ride else { return }
        context.delete(ride)
        try? context.save()
        Haptics.warning()
        dismiss()
    }
}
