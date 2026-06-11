import SwiftUI

struct SettingsView: View {
    @AppStorage("scanQuality") private var scanQuality = 0.8
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("defaultShareName") private var defaultShareName = true

    private var qualityLabel: String {
        switch scanQuality {
        case ..<0.65: return "Compact"
        case ..<0.85: return "Balanced"
        default: return "Best"
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Page image quality")
                            Spacer()
                            Text(qualityLabel)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Slider(value: $scanQuality, in: 0.5...0.95, step: 0.05)
                            .accessibilityLabel("Page image quality")
                            .accessibilityValue(qualityLabel)
                    }
                } header: {
                    Text("Scanning")
                } footer: {
                    Text("Higher quality keeps finer print readable; Compact keeps PDFs small for email. Applies to new scans.")
                }

                Section("Behavior") {
                    Toggle("Name PDFs after the document", isOn: $defaultShareName)
                    Toggle("Haptic feedback", isOn: $hapticsEnabled)
                }

                Section("Privacy") {
                    Label {
                        Text("Pages and recognized text are stored only in this app's sandbox on this device. There is no cloud, no account, and no analytics.")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    } icon: {
                        Image(systemName: "lock.shield")
                            .foregroundStyle(Theme.accent)
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Text recognition", value: "Apple Vision, on-device")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
