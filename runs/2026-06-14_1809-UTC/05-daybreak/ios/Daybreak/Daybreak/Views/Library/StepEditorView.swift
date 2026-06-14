import SwiftUI

/// Editor for a single step: title, kind (timed/checkbox), duration, icon, note.
struct StepEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    @State private var draft: StepDraft
    private let onCommit: (StepDraft) -> Void

    init(step: StepDraft, onCommit: @escaping (StepDraft) -> Void) {
        _draft = State(initialValue: step)
        self.onCommit = onCommit
    }

    private let iconChoices = ["circle.fill", "drop.fill", "wind", "figure.cooldown", "book.fill",
                               "cup.and.saucer.fill", "bed.double.fill", "target", "sparkles",
                               "timer", "bolt.fill", "heart.fill", "moon.fill", "pencil", "bell.slash.fill"]

    private var minutes: Int { draft.durationSec / 60 }
    private var seconds: Int { draft.durationSec % 60 }

    private var canSave: Bool {
        !draft.title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Step title", text: $draft.title)
                        .font(Theme.rounded(17))
                    Picker("Type", selection: $draft.kind) {
                        ForEach(StepKind.allCases) { kind in
                            Label(kind.label, systemImage: kind.symbol).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .listRowBackground(Theme.surface)

                if draft.kind == .timed {
                    Section {
                        durationPickers
                    } header: {
                        Text("Duration")
                    } footer: {
                        Text("The player counts this down and advances automatically.")
                    }
                    .listRowBackground(Theme.surface)
                }

                Section {
                    iconGrid
                    TextField("Note (optional)", text: $draft.note, axis: .vertical)
                        .lineLimit(1...3)
                        .font(Theme.rounded(15))
                } header: {
                    Text("Icon & note")
                }
                .listRowBackground(Theme.surface)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Step")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { commit() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
        }
    }

    private var durationPickers: some View {
        HStack(spacing: 0) {
            Picker("Minutes", selection: minutesBinding) {
                ForEach(0..<31, id: \.self) { m in
                    Text("\(m) min").tag(m)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Minutes")

            Picker("Seconds", selection: secondsBinding) {
                ForEach(Array(stride(from: 0, through: 55, by: 5)), id: \.self) { s in
                    Text("\(s) sec").tag(s)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Seconds")
        }
        .frame(height: 130)
    }

    private var minutesBinding: Binding<Int> {
        Binding(
            get: { minutes },
            set: { draft.durationSec = max(5, $0 * 60 + seconds) }
        )
    }

    private var secondsBinding: Binding<Int> {
        Binding(
            get: { seconds },
            set: { draft.durationSec = max(5, minutes * 60 + $0) }
        )
    }

    private var iconGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
            ForEach(iconChoices, id: \.self) { icon in
                Button {
                    draft.iconName = icon
                    Haptics.tap(settings.hapticsEnabled)
                } label: {
                    Image(systemName: icon)
                        .font(.system(size: 17))
                        .foregroundStyle(draft.iconName == icon ? Theme.onAccent : Theme.ink)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(draft.iconName == icon ? Theme.accent : Theme.surfaceAlt))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Icon \(icon)")
                .accessibilityAddTraits(draft.iconName == icon ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
    }

    private func commit() {
        var out = draft
        out.title = out.title.trimmingCharacters(in: .whitespaces)
        if out.kind == .timed { out.durationSec = max(5, out.durationSec) }
        onCommit(out)
        Haptics.tap(settings.hapticsEnabled)
        dismiss()
    }
}
