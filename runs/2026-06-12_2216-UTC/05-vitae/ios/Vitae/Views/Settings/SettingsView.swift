import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("paperSize") private var paperRaw = PaperSize.letter.rawValue
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("defaultTemplate") private var defaultTemplateRaw = TemplateKind.classic.rawValue

    @Query private var resumes: [Resume]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Paper size", selection: $paperRaw) {
                        ForEach(PaperSize.allCases) { size in
                            Text(size.displayName).tag(size.rawValue)
                        }
                    }
                    Picker("Default template", selection: $defaultTemplateRaw) {
                        ForEach(TemplateKind.allCases) { kind in
                            Text(kind.displayName).tag(kind.rawValue)
                        }
                    }
                } header: {
                    Text("Documents")
                } footer: {
                    Text("US Letter is standard in North America; A4 nearly everywhere else. Each resume can switch templates on the preview screen at any time.")
                }

                Section("Feedback") {
                    Toggle("Haptics", isOn: $hapticsEnabled)
                }

                Section {
                    LabeledContent("Resumes", value: "\(resumes.count)")
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Your data", value: "Stays on this device")
                } header: {
                    Text("About")
                } footer: {
                    Text("Vitae has no account, no upload, and no subscription that quietly renews at $29.95 a month. You write; it typesets; you keep the PDF.")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
