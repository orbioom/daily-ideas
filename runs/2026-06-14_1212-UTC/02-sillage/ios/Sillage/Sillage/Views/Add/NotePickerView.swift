import SwiftUI
import SwiftData

/// Pick notes for one pyramid slot: search the seeded library or add a custom note.
struct NotePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \ScentNote.name) private var allNotes: [ScentNote]

    let slot: NoteSlot
    /// Names already selected in this slot (to show checkmarks).
    let selectedNames: Set<String>
    /// Called with the chosen note when the user taps a row.
    let onToggle: (ScentNote) -> Void

    @State private var search = ""
    @State private var customName = ""
    @State private var customFamily: NoteFamily = .floral

    private var filtered: [ScentNote] {
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        let base = allNotes.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        guard !q.isEmpty else { return base }
        return base.filter {
            $0.name.lowercased().contains(q) || $0.family.rawValue.lowercased().contains(q)
        }
    }

    private var canAddCustom: Bool {
        let trimmed = customName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return !allNotes.contains { $0.name.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("Add a custom note", text: $customName)
                            .font(Theme.rounded(16))
                        Picker("", selection: $customFamily) {
                            ForEach(NoteFamily.allCases) { fam in
                                Text(fam.rawValue).tag(fam)
                            }
                        }
                        .labelsHidden()
                        Button {
                            addCustom()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(canAddCustom ? Theme.accent : Theme.inkFaint)
                        }
                        .disabled(!canAddCustom)
                        .accessibilityLabel("Add custom note")
                    }
                } header: {
                    Text("Custom")
                } footer: {
                    Text("Not in the library? Add it with its family.")
                }

                Section {
                    if filtered.isEmpty {
                        Text("No notes match “\(search)”.")
                            .font(Theme.rounded(14))
                            .foregroundStyle(Theme.inkSoft)
                    } else {
                        ForEach(filtered) { note in
                            Button {
                                onToggle(note)
                                Haptics.tap(settings.hapticsEnabled)
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: note.family.symbol)
                                        .font(.system(size: 13))
                                        .foregroundStyle(note.family.hueDeep)
                                        .frame(width: 22)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(note.name)
                                            .font(Theme.rounded(16, .medium))
                                            .foregroundStyle(Theme.ink)
                                        Text(note.family.rawValue)
                                            .font(Theme.rounded(12))
                                            .foregroundStyle(Theme.inkSoft)
                                    }
                                    Spacer()
                                    if selectedNames.contains(note.name) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Theme.accent)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundStyle(Theme.inkFaint)
                                    }
                                }
                            }
                            .accessibilityAddTraits(selectedNames.contains(note.name) ? .isSelected : [])
                        }
                    }
                } header: {
                    Text("\(slot.rawValue) notes · library")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .searchable(text: $search, prompt: "Search notes")
            .navigationTitle("\(slot.rawValue) notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
        }
    }

    private func addCustom() {
        let trimmed = customName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, canAddCustom else { return }
        let note = ScentNote(name: trimmed, family: customFamily, isSeeded: false)
        context.insert(note)
        onToggle(note)
        customName = ""
        Haptics.success(settings.hapticsEnabled)
    }
}
