import SwiftUI
import SwiftData

/// Detail / edit for a single day. Creates the log lazily on first edit so browsing an
/// unlogged day doesn't litter the store with empty entries.
struct DayDetailView: View {
    let date: Date

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    @State private var log: DayLog?
    @State private var showDeleteConfirm = false

    private var dayStart: Date { Calendar.current.startOfDay(for: date) }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                dateHeader
                if let log {
                    DayLogEditor(log: log, onChange: { DayLogStore.save(modelContext) })
                    deleteButton(for: log)
                } else {
                    startCard
                }
            }
            .padding(16)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(dayStart.formatted(.dateTime.month(.abbreviated).day()))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadExisting)
        .confirmationDialog("Delete this day's log?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { deleteLog() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes everything you recorded for \(dayStart.formatted(date: .abbreviated, time: .omitted)).")
        }
    }

    private var dateHeader: some View {
        HStack(spacing: 12) {
            BotanicalSprig(size: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(dayStart.formatted(date: .complete, time: .omitted))
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                Text(relativeLabel)
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
        }
        .padding(16)
        .cardSurface()
    }

    private var relativeLabel: String {
        let cal = Calendar.current
        let diff = cal.dateComponents([.day], from: dayStart, to: cal.startOfDay(for: Date())).day ?? 0
        switch diff {
        case 0: return "Today"
        case 1: return "Yesterday"
        default: return "\(diff) days ago"
        }
    }

    private var startCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("Nothing logged for this day")
                .font(Theme.rounded(17, .semibold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text("You can backfill a past day — add hot flashes, symptoms, sleep, and more.")
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(title: "Add a log for this day", systemImage: "plus") {
                createLog()
            }
            .frame(maxWidth: 280)
        }
        .padding(28)
        .cardSurface()
    }

    private func deleteButton(for log: DayLog) -> some View {
        Button(role: .destructive) {
            showDeleteConfirm = true
        } label: {
            Label("Delete this day's log", systemImage: "trash")
                .font(Theme.rounded(15, .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .foregroundStyle(Theme.bad)
                .background(
                    RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                        .fill(Theme.bad.opacity(0.12))
                )
        }
        .buttonStyle(PressableScale())
    }

    // MARK: - Logic

    private func loadExisting() {
        if log == nil {
            log = DayLogStore.log(on: dayStart, context: modelContext)
        }
    }

    private func createLog() {
        let fresh = DayLogStore.logOrCreate(on: dayStart, context: modelContext)
        DayLogStore.save(modelContext)
        Haptics.tap(enabled: settings.hapticsEnabled)
        log = fresh
    }

    private func deleteLog() {
        guard let current = log else { return }
        modelContext.delete(current)
        DayLogStore.save(modelContext)
        Haptics.success(enabled: settings.hapticsEnabled)
        log = nil
        dismiss()
    }
}
