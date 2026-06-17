import SwiftUI
import SwiftData

/// Settings — units, bar weight, plates, rest, progression, haptics, Pro, export, sample data.
struct SettingsScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query(filter: #Predicate<WorkoutSession> { $0.isComplete }) private var sessions: [WorkoutSession]

    @State private var paywallReason: PaywallReason?
    @State private var showExport = false
    @State private var showReseedConfirm = false
    @State private var barWeightText = ""

    var body: some View {
        NavigationStack {
            Form {
                unitsSection
                plateSection
                trainingSection
                feedbackSection
                proSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .sheet(isPresented: $showExport) {
                NavigationStack { ExportView() }
            }
            .confirmationDialog("Load sample data?", isPresented: $showReseedConfirm, titleVisibility: .visible) {
                Button("Replace with sample data", role: .destructive) {
                    SeedData.reseed(context: context)
                    Haptics.success(settings.hapticsEnabled)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears your programs and sessions, then loads a StrongLifts 5×5 program with example history.")
            }
            .onAppear { barWeightText = settings.number(settings.barWeightKg) }
        }
    }

    // MARK: Units

    private var unitsSection: some View {
        Section("Units") {
            Picker("Weight unit", selection: Binding(
                get: { settings.unit },
                set: { settings.unit = $0; barWeightText = settings.number(settings.barWeightKg) }
            )) {
                ForEach(WeightUnit.allCases) { Text($0.label.uppercased()).tag($0) }
            }
            .pickerStyle(.segmented)

            LabeledContent("Bar weight (\(settings.unit.label))") {
                TextField("20", text: $barWeightText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                    .onChange(of: barWeightText) { _, newValue in
                        if let v = Double(newValue.replacingOccurrences(of: ",", with: ".")) {
                            settings.barWeightKg = Units.fromDisplay(max(v, 0), unit: settings.unit)
                        }
                    }
            }
        }
    }

    // MARK: Plates

    private var plateSection: some View {
        Section {
            NavigationLink {
                PlateEditorView()
            } label: {
                LabeledContent("Available plates",
                               value: "\(settings.plateSetKg.count) sizes")
            }
            NavigationLink {
                PlateCalcView()
            } label: {
                Label("Plate calculator", systemImage: "circle.hexagongrid.fill")
            }
        } header: {
            Text("Plates")
        }
    }

    // MARK: Training

    private var trainingSection: some View {
        Section("Training") {
            Stepper("Rest timer: \(settings.defaultRestSeconds)s",
                    value: $settings.defaultRestSeconds, in: 30...600, step: 15)
            Toggle("Auto-progression", isOn: $settings.autoProgression)
        }
    }

    // MARK: Feedback

    private var feedbackSection: some View {
        Section("Feedback") {
            Toggle("Haptics", isOn: $settings.hapticsEnabled)
        }
    }

    // MARK: Pro

    private var proSection: some View {
        Section("Ascend Pro") {
            if isPro {
                Label("Pro unlocked — thank you!", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(Theme.good)
            } else {
                Button {
                    paywallReason = .analytics
                } label: {
                    Label("Unlock Ascend Pro · \(Pro.priceLabel)", systemImage: "crown.fill")
                        .foregroundStyle(Theme.accent)
                }
                Button("Restore purchase") {
                    Haptics.tap(settings.hapticsEnabled)
                    paywallReason = .analytics
                }
                .foregroundStyle(Theme.inkSoft)
            }
        }
    }

    // MARK: Data

    private var dataSection: some View {
        Section("Data") {
            Button {
                if isPro {
                    showExport = true
                } else {
                    paywallReason = .export
                }
            } label: {
                HStack {
                    Label("Export sessions", systemImage: "square.and.arrow.up")
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    if !isPro { Pill(text: "PRO", color: Theme.accent, filled: true) }
                }
            }
            Button {
                showReseedConfirm = true
            } label: {
                Label("Load sample data", systemImage: "sparkles")
                    .foregroundStyle(Theme.ink)
            }
        }
    }

    // MARK: About

    private var aboutSection: some View {
        Section {
            NavigationLink {
                AboutView()
            } label: {
                Label("About Ascend", systemImage: "info.circle")
            }
        }
    }
}
