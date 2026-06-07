import SwiftUI
import SwiftData

/// Settings: appearance, haptics, rider weight & unit preference, fallback FTP,
/// data counts, erase-all, and an about section.
struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var rides: [Ride]
    @Query private var ftpEntries: [FTPEntry]

    @AppStorage("ramp.appearance") private var appearance = AppearanceMode.system.rawValue
    @AppStorage("ramp.hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("ramp.weightKg") private var weightKg = 72.0
    @AppStorage("ramp.fallbackFTP") private var fallbackFTP = 250
    @AppStorage("ramp.useImperialWeight") private var useImperialWeight = false
    @AppStorage("ramp.hasOnboarded") private var hasOnboarded = true

    @State private var showEraseConfirm = false
    @State private var weightText = ""
    @State private var ftpText = ""

    private let lbPerKg = 2.2046226218

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                feedbackSection
                riderSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Settings")
            .onAppear(perform: syncFields)
        }
    }

    // MARK: Appearance

    private var appearanceSection: some View {
        Section {
            Picker("Appearance", selection: $appearance) {
                ForEach(AppearanceMode.allCases) { m in Text(m.label).tag(m.rawValue) }
            }
            .onChange(of: appearance) { _, _ in Haptics.selection() }
        } header: {
            Text("Appearance")
        } footer: {
            Text("System follows your device's light or dark setting.")
        }
        .listRowBackground(Brand.mist2.opacity(0.5))
    }

    // MARK: Feedback

    private var feedbackSection: some View {
        Section {
            Toggle("Haptics", isOn: $hapticsEnabled)
                .onChange(of: hapticsEnabled) { _, new in
                    Haptics.enabled = new
                    if new { Haptics.success() }
                }
        } header: {
            Text("Feedback")
        } footer: {
            Text("Sparse vibrations confirm saves and deletes.")
        }
        .listRowBackground(Brand.mist2.opacity(0.5))
    }

    // MARK: Rider

    private var riderSection: some View {
        Section {
            Toggle("Use pounds (lb)", isOn: $useImperialWeight)
                .onChange(of: useImperialWeight) { _, _ in Haptics.selection(); syncFields() }

            HStack {
                Text("Rider weight")
                Spacer()
                TextField(useImperialWeight ? "lb" : "kg", text: $weightText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 90)
                    .font(Brand.mono(15))
                    .onSubmit(commitWeight)
                    .accessibilityLabel("Rider weight")
                Text(useImperialWeight ? "lb" : "kg").foregroundStyle(Brand.text3)
            }

            HStack {
                Text("Fallback FTP")
                Spacer()
                TextField("watts", text: $ftpText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 90)
                    .font(Brand.mono(15))
                    .onSubmit(commitFTP)
                    .accessibilityLabel("Fallback FTP in watts")
                Text("W").foregroundStyle(Brand.text3)
            }
        } header: {
            Text("Rider")
        } footer: {
            Text("Weight drives W/kg. Fallback FTP is used for any ride dated before your first recorded FTP. Changes apply when you tap return.")
        }
        .listRowBackground(Brand.mist2.opacity(0.5))
        .onChange(of: weightText) { _, _ in commitWeight() }
        .onChange(of: ftpText) { _, _ in commitFTP() }
    }

    // MARK: Data

    private var dataSection: some View {
        Section {
            InfoRow(label: "Rides logged", value: "\(rides.count)", mono: true)
            InfoRow(label: "FTP entries", value: "\(ftpEntries.count)", mono: true)
            InfoRow(label: "Total TSS",
                    value: Format.int(rides.reduce(0) { $0 + $1.tss }), mono: true)
            Button(role: .destructive) {
                Haptics.warning(); showEraseConfirm = true
            } label: {
                Label("Erase all data", systemImage: "trash")
            }
            .confirmationDialog("Erase everything?", isPresented: $showEraseConfirm, titleVisibility: .visible) {
                Button("Erase all rides & FTP", role: .destructive) { eraseAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes every ride and FTP entry. This can't be undone.")
            }
        } header: {
            Text("Data")
        }
        .listRowBackground(Brand.mist2.opacity(0.5))
    }

    // MARK: About

    private var aboutSection: some View {
        Section {
            InfoRow(label: "App", value: "Ramp")
            InfoRow(label: "Version", value: appVersion, mono: true)
            InfoRow(label: "Studio", value: "Orbioom")
            Button {
                Haptics.tap()
                withAnimation(Brand.ease()) { hasOnboarded = false }
            } label: {
                Label("Replay intro", systemImage: "sparkles")
            }
        } header: {
            Text("About")
        } footer: {
            Text("Training-load tracking — fitness, fatigue and form — entirely on your device. No account, no cloud.")
        }
        .listRowBackground(Brand.mist2.opacity(0.5))
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    // MARK: Field sync & commit

    private func syncFields() {
        if useImperialWeight {
            weightText = Format.oneDecimal(weightKg * lbPerKg)
        } else {
            weightText = Format.oneDecimal(weightKg)
        }
        ftpText = String(fallbackFTP)
    }

    private func commitWeight() {
        guard let v = Double(weightText), v > 0 else { return }
        let kg = useImperialWeight ? v / lbPerKg : v
        weightKg = (kg * 10).rounded() / 10
    }

    private func commitFTP() {
        guard let v = Int(ftpText), v > 0 else { return }
        fallbackFTP = v
    }

    private func eraseAll() {
        for r in rides { context.delete(r) }
        for f in ftpEntries { context.delete(f) }
        try? context.save()
        Haptics.warning()
    }
}
