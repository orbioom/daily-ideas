import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allSettings: [ScriptSettings]
    @State private var showProUpgrade = false

    private var settings: ScriptSettings {
        if let s = allSettings.first { return s }
        let s = ScriptSettings()
        modelContext.insert(s)
        return s
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Writer") {
                    HStack {
                        Text("Your Name")
                        Spacer()
                        TextField("Author name", text: Binding(
                            get: { settings.authorName },
                            set: { settings.authorName = $0 }
                        ))
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.secondary)
                    }
                }

                Section("Editor") {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Font Size")
                            Spacer()
                            Text("\(Int(settings.fontSize))pt")
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                        Slider(
                            value: Binding(
                                get: { settings.fontSize },
                                set: { settings.fontSize = $0 }
                            ),
                            in: 12...18,
                            step: 1
                        )
                        .tint(.scriptAmber)
                    }
                    .padding(.vertical, 2)

                    Picker("Appearance", selection: Binding(
                        get: { settings.colorScheme },
                        set: { settings.colorScheme = $0 }
                    )) {
                        Text("System").tag("auto")
                        Text("Dark").tag("dark")
                        Text("Light").tag("light")
                    }

                    Toggle("Auto-Format Hints", isOn: Binding(
                        get: { settings.autoFormat },
                        set: { settings.autoFormat = $0 }
                    ))

                    Toggle("Show Element Guide", isOn: Binding(
                        get: { settings.showElementGuide },
                        set: { settings.showElementGuide = $0 }
                    ))

                    Toggle("Show Page Count", isOn: Binding(
                        get: { settings.showPageNumbers },
                        set: { settings.showPageNumbers = $0 }
                    ))
                }

                Section("Script Pro") {
                    if settings.hasPro {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.scriptAmber)
                            Text("Pro Unlocked")
                                .foregroundColor(.scriptAmber)
                                .fontWeight(.medium)
                        }
                    } else {
                        Button {
                            showProUpgrade = true
                        } label: {
                            HStack {
                                Image(systemName: "crown")
                                    .foregroundColor(.scriptAmber)
                                Text("Unlock Script Pro")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("$6.99 one-time")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    NavigationLink("About Fountain") {
                        FountainInfoView()
                    }
                    Link("Fountain Spec (fountain.io)", destination: URL(string: "https://fountain.io")!)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        try? modelContext.save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showProUpgrade) {
                ProUpgradeView()
            }
        }
    }
}

struct FountainInfoView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Fountain is a simple markup syntax for writing screenplays in plain text. It was created by John August, Stu Maschwitz, and others in the film industry.")
                    .font(.body)

                Text("Script stores your screenplays as Fountain — an open format that you own and can open in any compatible software, forever.")
                    .font(.body)

                Text("Why Fountain?")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    BulletRow("Your scripts are plain text — readable in any app")
                    BulletRow("You're never locked in to one software")
                    BulletRow("Fountain files are tiny and sync instantly")
                    BulletRow("Industry-recognized open standard")
                    BulletRow("Used by professional writers worldwide")
                }
                .foregroundColor(.secondary)

                Text("Format Quick Reference")
                    .font(.headline)
                    .padding(.top, 8)

                VStack(alignment: .leading, spacing: 6) {
                    FormatRefRow(syntax: "INT. PLACE - DAY", meaning: "Scene heading")
                    FormatRefRow(syntax: "ACTION TEXT", meaning: "Action / description")
                    FormatRefRow(syntax: "CHARACTER NAME", meaning: "Character cue (ALL CAPS)")
                    FormatRefRow(syntax: "Spoken words", meaning: "Dialogue (after character)")
                    FormatRefRow(syntax: "(beat)", meaning: "Parenthetical")
                    FormatRefRow(syntax: "CUT TO:", meaning: "Transition (ends with TO:)")
                    FormatRefRow(syntax: "===", meaning: "Forced page break")
                    FormatRefRow(syntax: "> CENTERED TEXT <", meaning: "Centered text")
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding()
        }
        .navigationTitle("About Fountain")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BulletRow: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
        }
    }
}

struct FormatRefRow: View {
    let syntax: String
    let meaning: String

    var body: some View {
        HStack {
            Text(syntax)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.scriptAmber)
                .frame(maxWidth: 180, alignment: .leading)
            Text(meaning)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
