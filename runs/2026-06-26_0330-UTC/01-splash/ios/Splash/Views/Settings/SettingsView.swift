import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var settingsAll: [SplashSettings]
    @Query(sort: \SwimPool.name) private var pools: [SwimPool]
    @Environment(\.modelContext) private var context

    var settings: SplashSettings {
        if let s = settingsAll.first { return s }
        let s = SplashSettings()
        context.insert(s)
        return s
    }

    @State private var showingAddPool = false
    @State private var editingPool: SwimPool?

    var body: some View {
        NavigationStack {
            Form {
                Section("Display") {
                    Toggle("Use Yards", isOn: Binding(
                        get: { settings.useYards },
                        set: { v in settings.useYards = v; try? context.save() }
                    ))
                    .accessibilityLabel("Use yards instead of meters")
                }

                Section("Goals") {
                    HStack {
                        Text("Weekly Goal")
                        Spacer()
                        Picker("Weekly Goal (km)", selection: Binding(
                            get: { settings.weeklyGoalKm },
                            set: { v in settings.weeklyGoalKm = v; try? context.save() }
                        )) {
                            ForEach([1.0, 2.0, 3.0, 4.0, 5.0, 7.0, 10.0], id: \.self) { val in
                                Text(String(format: "%.0f km", val)).tag(val)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    HStack {
                        Text("Default Intensity")
                        Spacer()
                        Picker("Default Intensity", selection: Binding(
                            get: { settings.defaultIntensity },
                            set: { v in settings.defaultIntensity = v; try? context.save() }
                        )) {
                            ForEach(["easy","moderate","hard","race"], id: \.self) { v in
                                Text(v.intensityDisplayName).tag(v)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                Section("Haptics") {
                    Toggle("Haptic Feedback", isOn: Binding(
                        get: { settings.hapticsEnabled },
                        set: { v in settings.hapticsEnabled = v; try? context.save() }
                    ))
                }

                Section("Pools") {
                    if pools.isEmpty {
                        Text("No pools added yet")
                            .foregroundStyle(.secondary)
                            .italic()
                    } else {
                        ForEach(pools) { pool in
                            Button {
                                editingPool = pool
                            } label: {
                                HStack {
                                    Image(systemName: pool.poolType.poolTypeIcon)
                                        .foregroundStyle(SplashTheme.accent)
                                        .frame(width: 24)
                                        .accessibilityHidden(true)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(pool.name)
                                            .foregroundStyle(.primary)
                                        Text("\(pool.poolType.poolTypeDisplayName) · \(Int(pool.lengthMeters))m")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .accessibilityHidden(true)
                                }
                            }
                            .accessibilityLabel("\(pool.name), \(pool.poolType.poolTypeDisplayName), \(Int(pool.lengthMeters)) meters")
                        }
                        .onDelete { offsets in
                            for i in offsets { context.delete(pools[i]) }
                            try? context.save()
                        }
                    }
                    Button {
                        showingAddPool = true
                    } label: {
                        Label("Add Pool", systemImage: "plus.circle.fill")
                            .foregroundStyle(SplashTheme.accent)
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Build", value: "1")
                    Text("Splash is free to use. No account required. Your data never leaves your device.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingAddPool) {
                PoolEditorSheet(pool: nil)
            }
            .sheet(item: $editingPool) { pool in
                PoolEditorSheet(pool: pool)
            }
        }
    }
}

struct PoolEditorSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let pool: SwimPool?

    @State private var name = ""
    @State private var lengthMeters: Double = 25
    @State private var poolType = "indoor"
    @State private var notes = ""

    var isEditing: Bool { pool != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Pool Details") {
                    TextField("Name", text: $name)
                    Picker("Type", selection: $poolType) {
                        ForEach(["indoor","outdoor","openWater"], id: \.self) { t in
                            Label(t.poolTypeDisplayName, systemImage: t.poolTypeIcon).tag(t)
                        }
                    }
                    HStack {
                        Text("Length")
                        Spacer()
                        Picker("Length", selection: Binding(
                            get: { Int(lengthMeters) },
                            set: { lengthMeters = Double($0) }
                        )) {
                            ForEach([25, 33, 50], id: \.self) { l in
                                Text("\(l)m").tag(l)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                Section("Notes") {
                    TextField("Optional", text: $notes)
                }
                if isEditing {
                    Section {
                        Button("Delete Pool", role: .destructive) {
                            if let p = pool { context.delete(p); try? context.save() }
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Pool" : "Add Pool")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let p = pool {
                    name = p.name
                    lengthMeters = p.lengthMeters
                    poolType = p.poolType
                    notes = p.notes
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if let p = pool {
            p.name = trimmed
            p.lengthMeters = lengthMeters
            p.poolType = poolType
            p.notes = notes
        } else {
            let p = SwimPool(name: trimmed, lengthMeters: lengthMeters, poolType: poolType, notes: notes)
            context.insert(p)
        }
        try? context.save()
        dismiss()
    }
}
