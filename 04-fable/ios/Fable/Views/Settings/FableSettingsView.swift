import SwiftUI
import SwiftData

struct FableSettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var settingsQ: [FableSettings]
    @State private var showClearAlert = false

    private var settings: FableSettings {
        if let s = settingsQ.first { return s }
        let s = FableSettings(); context.insert(s); try? context.save(); return s
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Reader") {
                    Toggle("Dark Mode by Default", isOn: Binding(
                        get: { settings.darkReaderMode },
                        set: { settings.darkReaderMode = $0; try? context.save() }
                    ))
                    .accessibilityLabel("Dark reader mode")

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Narration Speed")
                            .font(.subheadline)
                        Slider(
                            value: Binding(get: { settings.narrationSpeed }, set: { settings.narrationSpeed = $0; try? context.save() }),
                            in: 0...1
                        )
                        HStack {
                            Text("Slow").font(.caption).foregroundColor(FableTheme.secondaryLabel)
                            Spacer()
                            Text("Fast").font(.caption).foregroundColor(FableTheme.secondaryLabel)
                        }
                    }
                    .accessibilityLabel("Narration speed slider")

                    Toggle("Auto-Play Narration", isOn: Binding(
                        get: { settings.autoPlayNarration },
                        set: { settings.autoPlayNarration = $0; try? context.save() }
                    ))
                    .accessibilityLabel("Auto-play narration when opening story")
                }

                Section("Profile") {
                    HStack {
                        Text("Child's Name")
                        Spacer()
                        TextField("Name", text: Binding(
                            get: { settings.childName },
                            set: { settings.childName = $0; try? context.save() }
                        ))
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(FableTheme.secondaryLabel)
                    }
                    .accessibilityLabel("Child's name")

                    Picker("Preferred Age Group", selection: Binding(
                        get: { settings.preferredAgeGroup },
                        set: { settings.preferredAgeGroup = $0; try? context.save() }
                    )) {
                        ForEach(AgeGroup.allCases, id: \.self) { a in
                            Text(a.rawValue).tag(a)
                        }
                    }
                    .accessibilityLabel("Preferred age group")

                    Picker("Default Genre", selection: Binding(
                        get: { settings.defaultGenre },
                        set: { settings.defaultGenre = $0; try? context.save() }
                    )) {
                        ForEach(StoryGenre.allCases, id: \.self) { g in
                            Text(g.rawValue).tag(g)
                        }
                    }
                    .accessibilityLabel("Default genre")
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0").foregroundColor(FableTheme.secondaryLabel)
                    }
                }

                Section {
                    Button(role: .destructive) { showClearAlert = true } label: {
                        Label("Delete All Stories", systemImage: "trash")
                    }
                    .accessibilityLabel("Delete all stories")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Delete All Stories?", isPresented: $showClearAlert) {
                Button("Delete Everything", role: .destructive) { clearAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all stories, characters, and pages. This cannot be undone.")
            }
        }
    }

    private func clearAll() {
        try? context.delete(model: FableStory.self)
        try? context.delete(model: StoryCharacter.self)
        try? context.delete(model: StoryPage.self)
        try? context.save()
    }
}
