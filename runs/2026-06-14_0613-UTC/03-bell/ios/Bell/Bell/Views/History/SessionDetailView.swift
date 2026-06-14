import SwiftUI
import SwiftData

struct SessionDetailView: View {
    @Bindable var session: MeditationSession
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                detailCard
                noteEditor
            }
            .padding(Theme.spacing)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { try? context.save() }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Text(session.mood.emoji)
                .font(.system(size: 56))
                .accessibilityHidden(true)
            Text(session.durationLabel)
                .font(Theme.serif(34, .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text(session.date, format: .dateTime.weekday(.wide).month().day().hour().minute())
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var detailCard: some View {
        Card {
            VStack(spacing: 0) {
                detailRow("Mood", "\(session.mood.emoji) \(session.mood.displayName)")
                Divider().background(Theme.separator)
                detailRow("Preset", session.presetName)
                Divider().background(Theme.separator)
                detailRow("Time of day", session.timeOfDay.displayName)
                Divider().background(Theme.separator)
                detailRow("Completed", session.completedFully ? "Fully" : "Ended early")
            }
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(Theme.rounded(15)).foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(value).font(Theme.rounded(15, .medium)).foregroundStyle(Theme.textPrimary)
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }

    private var noteEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Note")
                .font(Theme.rounded(16, .semibold))
                .foregroundStyle(Theme.textPrimary)
            TextField("Add a reflection…", text: $session.note, axis: .vertical)
                .lineLimit(3...6)
                .padding(12)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                        .strokeBorder(Theme.separator, lineWidth: 1)
                )
        }
    }
}
