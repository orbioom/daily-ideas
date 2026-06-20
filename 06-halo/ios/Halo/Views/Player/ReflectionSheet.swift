import SwiftUI
import SwiftData

struct ReflectionSheet: View {
    let preset: HaloPreset
    let duration: TimeInterval
    let moodBefore: Int
    var onSave: (HaloSession) -> Void
    var onSkip: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var moodAfter: Int = 3
    @State private var notes: String = ""

    private var moodDelta: Int { moodAfter - moodBefore }

    private var durationDisplay: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return seconds > 0 ? "\(minutes)m \(seconds)s" : "\(minutes)m"
        }
        return "\(seconds)s"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HaloTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: HaloTheme.spacingL) {
                        completionHeader
                        sessionSummary
                        moodSection
                        notesSection
                        moodDeltaDisplay
                        saveButton
                    }
                    .padding(.horizontal, HaloTheme.spacingM)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Session Complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(HaloTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") { onSkip() }
                        .foregroundColor(HaloTheme.textTertiary)
                }
            }
        }
    }

    // MARK: - Subviews

    private var completionHeader: some View {
        VStack(spacing: HaloTheme.spacingS) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(HaloTheme.accent)
                .shadow(color: HaloTheme.accent.opacity(0.5), radius: 16)
                .padding(.top, HaloTheme.spacingL)

            Text("Well done.")
                .font(HaloTheme.displayFont)
                .foregroundColor(HaloTheme.textPrimary)

            Text("You completed a session.")
                .font(HaloTheme.bodyFont)
                .foregroundColor(HaloTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var sessionSummary: some View {
        HStack(spacing: 0) {
            summaryItem(label: "Preset", value: preset.name)
            Divider().background(Color.white.opacity(0.1)).frame(height: 40)
            summaryItem(label: "Duration", value: durationDisplay)
            Divider().background(Color.white.opacity(0.1)).frame(height: 40)
            summaryItem(label: "Category", value: preset.category.rawValue)
        }
        .padding(HaloTheme.spacingM)
        .background(
            RoundedRectangle(cornerRadius: HaloTheme.radiusM)
                .fill(HaloTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: HaloTheme.radiusM)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private func summaryItem(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(HaloTheme.textTertiary)
                .tracking(1)
            Text(value)
                .font(HaloTheme.labelFont)
                .foregroundColor(HaloTheme.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: HaloTheme.spacingM) {
            Label("How do you feel now?", systemImage: "heart")
                .font(HaloTheme.labelFont)
                .foregroundColor(HaloTheme.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            MoodPicker(rating: $moodAfter)
        }
        .padding(HaloTheme.spacingM)
        .background(
            RoundedRectangle(cornerRadius: HaloTheme.radiusM)
                .fill(HaloTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: HaloTheme.radiusM)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: HaloTheme.spacingS) {
            Label("Notes (optional)", systemImage: "note.text")
                .font(HaloTheme.labelFont)
                .foregroundColor(HaloTheme.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            TextEditor(text: $notes)
                .font(HaloTheme.bodyFont)
                .foregroundColor(HaloTheme.textPrimary)
                .frame(minHeight: 80)
                .padding(HaloTheme.spacingS)
                .background(HaloTheme.surfaceElevated)
                .cornerRadius(HaloTheme.radiusS)
                .scrollContentBackground(.hidden)
        }
        .padding(HaloTheme.spacingM)
        .background(
            RoundedRectangle(cornerRadius: HaloTheme.radiusM)
                .fill(HaloTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: HaloTheme.radiusM)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private var moodDeltaDisplay: some View {
        if moodBefore != moodAfter {
            HStack(spacing: HaloTheme.spacingS) {
                Image(systemName: moodDelta > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .foregroundColor(moodDelta > 0 ? .green : .red)
                Text(
                    moodDelta > 0
                        ? "Mood improved by \(moodDelta) point\(abs(moodDelta) == 1 ? "" : "s")"
                        : "Mood changed by \(moodDelta) point\(abs(moodDelta) == 1 ? "" : "s")"
                )
                .font(HaloTheme.bodyFont)
                .foregroundColor(moodDelta > 0 ? .green : .red)
            }
            .padding(HaloTheme.spacingM)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: HaloTheme.radiusM)
                    .fill((moodDelta > 0 ? Color.green : Color.red).opacity(0.1))
            )
        }
    }

    private var saveButton: some View {
        Button {
            saveSession()
        } label: {
            Text("Save Session")
                .font(HaloTheme.headlineFont)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, HaloTheme.spacingM)
                .background(
                    RoundedRectangle(cornerRadius: HaloTheme.radiusL)
                        .fill(
                            LinearGradient(
                                colors: [HaloTheme.primary, HaloTheme.accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: HaloTheme.accent.opacity(0.4), radius: 12, y: 4)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func saveSession() {
        let session = HaloSession(
            presetID: preset.id,
            presetName: preset.name,
            category: preset.category.rawValue,
            durationSeconds: duration,
            moodBefore: moodBefore,
            moodAfter: moodAfter,
            notes: notes,
            completed: true
        )
        modelContext.insert(session)
        onSave(session)
    }
}
