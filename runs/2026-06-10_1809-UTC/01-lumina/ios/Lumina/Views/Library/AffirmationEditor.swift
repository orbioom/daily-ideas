import SwiftUI
import SwiftData

/// Create a new custom affirmation, or edit one the user already owns.
struct AffirmationEditor: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let existing: Affirmation?
    @State private var text: String = ""
    @State private var theme: AffirmationTheme = .confidence
    @State private var error: String?

    private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { trimmed.count >= 3 && trimmed.count <= 200 }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section {
                        TextField("Write an affirmation…", text: $text, axis: .vertical)
                            .lineLimit(2...5)
                            .font(.body)
                        Text("\(trimmed.count)/200")
                            .font(.caption)
                            .foregroundStyle(trimmed.count > 200 ? Brand.danger : Brand.text3)
                    } header: {
                        Text("Affirmation")
                    } footer: {
                        if let error { Text(error).foregroundStyle(Brand.danger) }
                    }

                    Section("Theme") {
                        Picker("Theme", selection: $theme) {
                            ForEach(AffirmationTheme.allCases) { t in
                                Label(t.title, systemImage: t.icon).tag(t)
                            }
                        }
                        .pickerStyle(.navigationLink)
                    }

                    if !trimmed.isEmpty {
                        Section("Preview") {
                            AffirmationCardView(
                                affirmation: Affirmation(text: trimmed, theme: theme, isCustom: true),
                                compact: true)
                            .listRowBackground(Color.clear)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(existing == nil ? "New Affirmation" : "Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!canSave)
                }
            }
            .onAppear {
                if let e = existing { text = e.text; theme = e.theme }
            }
        }
    }

    private func save() {
        guard canSave else {
            error = "Affirmation must be between 3 and 200 characters."
            return
        }
        if let e = existing {
            e.text = trimmed
            e.theme = theme
        } else {
            context.insert(Affirmation(text: trimmed, theme: theme, isCustom: true))
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}

#Preview {
    AffirmationEditor(existing: nil)
        .modelContainer(for: [Affirmation.self, DayLog.self], inMemory: true)
}
