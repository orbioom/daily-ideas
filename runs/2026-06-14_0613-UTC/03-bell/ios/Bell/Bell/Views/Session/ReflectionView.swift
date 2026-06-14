import SwiftUI

/// Post-sit reflection: pick a mood, optional note. Saving is delegated up.
struct ReflectionView: View {
    let presetName: String
    let seconds: Int
    let completedFully: Bool
    let onSave: (Mood, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var mood: Mood = .calm
    @State private var note: String = ""

    private var durationLabel: String {
        let m = seconds / 60, s = seconds % 60
        if m == 0 { return "\(s)s" }
        if s == 0 { return "\(m) min" }
        return "\(m)m \(s)s"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Image(systemName: completedFully ? "checkmark.seal.fill" : "leaf.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(Theme.accent)
                            .accessibilityHidden(true)
                        Text(completedFully ? "Sit complete" : "Sit ended")
                            .font(Theme.serif(26, .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("\(durationLabel) · \(presetName)")
                            .font(Theme.rounded(15))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.top, 12)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("How do you feel?")
                            .font(Theme.rounded(16, .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        moodPicker
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Note (optional)")
                            .font(Theme.rounded(16, .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        TextField("A word on this sit…", text: $note, axis: .vertical)
                            .lineLimit(2...4)
                            .padding(12)
                            .background(Theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                                    .strokeBorder(Theme.separator, lineWidth: 1)
                            )
                    }

                    PrimaryButton(title: "Save & finish") {
                        onSave(mood, note.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    }
                }
                .padding(Theme.spacing)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var moodPicker: some View {
        HStack(spacing: 10) {
            ForEach(Mood.allCases) { m in
                Button { mood = m } label: {
                    VStack(spacing: 6) {
                        Text(m.emoji).font(.system(size: 28))
                        Text(m.displayName)
                            .font(Theme.rounded(11, .medium))
                            .foregroundStyle(mood == m ? Theme.textPrimary : Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(mood == m ? m.color.opacity(0.16) : Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                            .strokeBorder(mood == m ? m.color : Theme.separator, lineWidth: mood == m ? 1.5 : 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(m.displayName)
                .accessibilityAddTraits(mood == m ? .isSelected : [])
            }
        }
    }
}
