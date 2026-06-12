import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("defaultCorrection") private var defaultCorrectionRaw = CorrectionLevel.medium.rawValue
    @AppStorage("keepScanHistory") private var keepScanHistory = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    @Query private var scans: [ScanRecord]
    @Query private var codes: [SavedCode]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Default error correction", selection: $defaultCorrectionRaw) {
                        ForEach(CorrectionLevel.allCases) { level in
                            Text(level.displayName).tag(level.rawValue)
                        }
                    }
                } header: {
                    Text("Creating")
                } footer: {
                    Text("Applied to new codes; each code can override it.")
                }

                Section {
                    Toggle("Keep scan history", isOn: $keepScanHistory)
                    Toggle("Haptics", isOn: $hapticsEnabled)
                } header: {
                    Text("Scanning & feedback")
                } footer: {
                    Text("With history off, scans are shown once and never stored.")
                }

                Section {
                    LabeledContent("Saved codes", value: "\(codes.count)")
                    LabeledContent("Scan records", value: "\(scans.count)")
                    LabeledContent("Version", value: "1.0")
                } header: {
                    Text("About")
                } footer: {
                    Text("Glyph generates and reads QR codes entirely on this device. Your codes never expire, never phone home, and never require a subscription — because none of this needs a server.")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
