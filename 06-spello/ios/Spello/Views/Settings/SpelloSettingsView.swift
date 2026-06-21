import SwiftUI
import SwiftData

struct SpelloSettingsView: View {
    @Query private var prefs: [SpelloPrefs]
    @Query private var profiles: [SpelloProfile]
    @Environment(\.modelContext) private var ctx
    @State private var showDeleteConfirm = false
    @State private var profileToDelete: SpelloProfile?

    private var pref: SpelloPrefs {
        if let p = prefs.first { return p }
        let p = SpelloPrefs()
        ctx.insert(p)
        return p
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Feedback") {
                    Toggle("Haptics", isOn: Binding(
                        get: { pref.hapticsEnabled },
                        set: { pref.hapticsEnabled = $0 }
                    ))
                }
                Section("Profiles") {
                    ForEach(profiles) { p in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(p.name).font(.subheadline.weight(.semibold))
                                Text("Grade \(p.gradeLevel)").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button(role: .destructive) {
                                profileToDelete = p
                                showDeleteConfirm = true
                            } label: {
                                Image(systemName: "trash").foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    if profiles.isEmpty {
                        Text("No profiles yet. Add one from the Home tab.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Section("Word Lists") {
                    ForEach(1...5, id: \.self) { g in
                        LabeledContent("Grade \(g)", value: "\(spelloWords[g]?.count ?? 0) words")
                    }
                }
                Section("About") {
                    LabeledContent("Version", value: "1.0")
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog("Delete Profile?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let p = profileToDelete { ctx.delete(p) }
                }
            } message: {
                Text("This will delete the profile and all their progress.")
            }
        }
    }
}
