import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var photos: [ProgressPhoto]
    @Query private var metrics: [BodyMetric]

    @AppStorage("contour.haptics") private var haptics = true
    @AppStorage("contour.weightUnit") private var weightUnitRaw = WeightUnit.kg.rawValue
    @AppStorage("contour.lengthUnit") private var lengthUnitRaw = LengthUnit.cm.rawValue
    @AppStorage("contour.defaultPose") private var defaultPoseRaw = Pose.front.rawValue
    @AppStorage("contour.goalWeightKg") private var goalWeightKg = 0.0
    @AppStorage("contour.goalDate") private var goalDateInterval = 0.0

    @State private var showDeleteConfirm = false
    @State private var goalText = ""
    @State private var hasGoalDate = false
    @State private var goalDate = Date()

    private var weightUnit: WeightUnit { WeightUnit(rawValue: weightUnitRaw) ?? .kg }

    var body: some View {
        Form {
            unitsSection
            goalSection
            preferencesSection
            privacySection
            dataSection
            aboutSection
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle("Settings")
        .onAppear { loadGoal() }
        .confirmationDialog("Delete all photos & data?",
                            isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete everything", role: .destructive) { deleteAll() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This permanently removes every photo file and measurement from this device. This can't be undone.")
        }
    }

    // MARK: - Units

    private var unitsSection: some View {
        Section("Units") {
            Picker("Weight", selection: $weightUnitRaw) {
                ForEach(WeightUnit.allCases) { Text($0.short.uppercased()).tag($0.rawValue) }
            }
            .onChange(of: weightUnitRaw) { _, _ in Haptics.selection() }

            Picker("Length", selection: $lengthUnitRaw) {
                ForEach(LengthUnit.allCases) { Text($0.short).tag($0.rawValue) }
            }
            .onChange(of: lengthUnitRaw) { _, _ in Haptics.selection() }
        }
    }

    // MARK: - Goal

    private var goalSection: some View {
        Section {
            HStack {
                Text("Goal weight (\(weightUnit.short))")
                Spacer()
                TextField("none", text: $goalText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 110)
                    .onChange(of: goalText) { _, _ in commitGoalWeight() }
            }
            Toggle("Target date", isOn: $hasGoalDate)
                .onChange(of: hasGoalDate) { _, on in
                    goalDateInterval = on ? goalDate.timeIntervalSince1970 : 0
                }
            if hasGoalDate {
                DatePicker("Reach by", selection: $goalDate, displayedComponents: .date)
                    .onChange(of: goalDate) { _, d in goalDateInterval = d.timeIntervalSince1970 }
            }
        } header: {
            Text("Goal")
        } footer: {
            Text("Used for the goal line and projection on the Progress chart.")
        }
    }

    // MARK: - Preferences

    private var preferencesSection: some View {
        Section("Preferences") {
            Picker("Default pose", selection: $defaultPoseRaw) {
                ForEach(Pose.allCases) { Label($0.label, systemImage: $0.symbol).tag($0.rawValue) }
            }
            .onChange(of: defaultPoseRaw) { _, _ in Haptics.selection() }

            Toggle("Haptics", isOn: $haptics)
                .onChange(of: haptics) { _, new in
                    Haptics.enabled = new
                    if new { Haptics.tap() }
                }
        }
    }

    // MARK: - Privacy

    private var privacySection: some View {
        Section {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(Brand.magic)
                    .accessibilityHidden(true)
                Text("All photos are stored only on this device. Nothing is uploaded to any server or cloud, and there is no account.")
                    .font(.footnote)
                    .foregroundStyle(Brand.text2)
            }
        } header: {
            Text("Privacy")
        }
    }

    // MARK: - Data

    private var dataSection: some View {
        Section {
            HStack {
                Text("Photos")
                Spacer()
                Text("\(photos.count)").foregroundStyle(Brand.text2)
            }
            HStack {
                Text("Measurements")
                Spacer()
                Text("\(metrics.count)").foregroundStyle(Brand.text2)
            }
            Button(role: .destructive) {
                Haptics.warning()
                showDeleteConfirm = true
            } label: {
                Label("Delete all photos & data", systemImage: "trash")
            }
        } header: {
            Text("Data")
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0").foregroundStyle(Brand.text2)
            }
            Text("Contour is a personal progress tracker, not a medical device.")
                .font(.footnote).foregroundStyle(Brand.text3)
        } header: {
            Text("About")
        }
    }

    // MARK: - Goal persistence

    private func loadGoal() {
        if goalWeightKg > 0 {
            goalText = Units.formattedWeight(goalWeightKg, unit: weightUnit, showUnit: false)
        }
        if goalDateInterval > 0 {
            hasGoalDate = true
            goalDate = Date(timeIntervalSince1970: goalDateInterval)
        }
    }

    private func commitGoalWeight() {
        let t = goalText.trimmingCharacters(in: .whitespaces)
        if t.isEmpty {
            goalWeightKg = 0
        } else if let v = Double(t), v > 0 {
            goalWeightKg = Units.displayToKg(v, unit: weightUnit)
        }
    }

    private func deleteAll() {
        for p in photos where p.hasImage { ImageStore.delete(p.filename) }
        ImageStore.deleteAll()
        for p in photos { context.delete(p) }
        for m in metrics { context.delete(m) }
        try? context.save()
        Haptics.success()
    }
}
