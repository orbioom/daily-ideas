import SwiftUI
import SwiftData

/// Title detail — hero, progress stepper, score, status, metadata, notes,
/// rewatch counter, watch-log history, edit & delete.
struct TitleDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @Bindable var title: Title

    @State private var showEdit = false
    @State private var showDeleteConfirm = false

    private var sortedLogs: [WatchLog] { LibraryEngine.sortedLogs(title) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                hero
                progressSection
                scoreStatusSection
                metadataSection
                notesSection
                logsSection
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(title.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showEdit = true } label: { Label("Edit", systemImage: "pencil") }
                    Button {
                        title.favorite.toggle()
                        try? context.save()
                        Haptics.tap(settings.hapticsEnabled)
                    } label: {
                        Label(title.favorite ? "Unfavorite" : "Favorite",
                              systemImage: title.favorite ? "heart.slash" : "heart")
                    }
                    Button(role: .destructive) { showDeleteConfirm = true } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            AddEditTitleView(mode: .edit(title))
        }
        .confirmationDialog("Delete this title?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { deleteTitle() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes \(title.name) and its watch log from your library.")
        }
    }

    // MARK: Hero

    private var hero: some View {
        HStack(alignment: .top, spacing: 16) {
            CoverView(hue: title.coverHue,
                      kind: title.kind,
                      initials: title.name.coverInitials,
                      intensity: settings.accentIntensity)
                .frame(width: 110, height: 150)

            VStack(alignment: .leading, spacing: 8) {
                Text(title.name)
                    .font(Theme.display(22, .bold))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if !title.studioOrAuthor.isEmpty {
                    Text(title.studioOrAuthor)
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                }
                HStack(spacing: 8) {
                    StatusPill(status: title.status, kind: title.kind)
                    if title.favorite {
                        Pill(text: "Favorite", systemImage: "heart.fill", tint: Theme.accent)
                    }
                }
                ScoreChip(score: title.score, hidden: settings.hideScores)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: Progress

    private var progressSection: some View {
        card("Progress", "chart.bar.fill") {
            VStack(spacing: 12) {
                HStack {
                    Text(title.progressLabel)
                        .font(Theme.display(26, .bold))
                        .foregroundStyle(Theme.ink)
                        .monospacedDigit()
                    Spacer()
                    Text("\(Int((title.progressFraction * 100).rounded()))%")
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                        .monospacedDigit()
                }
                ProgressBar(fraction: title.progressFraction, height: 8)
                HStack(spacing: 14) {
                    stepButton(symbol: "minus", label: "Remove one \(title.kind.unitNoun)") {
                        TitleActions.advance(title, by: -1, in: context)
                        Haptics.tap(settings.hapticsEnabled)
                    }
                    .disabled(title.progress <= 0)
                    .opacity(title.progress <= 0 ? 0.4 : 1)

                    Button {
                        let done = TitleActions.advance(title, by: 1, in: context)
                        Haptics.success(settings.hapticsEnabled)
                        _ = done
                    } label: {
                        Label("+1 \(title.kind.unitNoun.capitalized)", systemImage: "plus")
                            .font(Theme.rounded(16, .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(LinearGradient(colors: [Theme.accent, Theme.violet],
                                                         startPoint: .leading, endPoint: .trailing))
                            )
                    }
                    .accessibilityLabel("Advance by one \(title.kind.unitNoun)")
                }
            }
        }
    }

    private func stepButton(symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Theme.accent)
                .frame(width: 48, height: 48)
                .background(Circle().fill(Theme.accentSoft))
        }
        .accessibilityLabel(label)
    }

    // MARK: Score & status

    private var scoreStatusSection: some View {
        card("Score & status", "star.fill") {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your score")
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                    Picker("Score", selection: scoreBinding) {
                        Text("Unrated").tag(0)
                        ForEach(1...10, id: \.self) { s in Text("\(s)").tag(s) }
                    }
                    .pickerStyle(.menu)
                    .tint(Theme.accent)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Status")
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                    Picker("Status", selection: statusBinding) {
                        ForEach(WatchStatus.allCases) { s in
                            Text(s.label(for: title.kind)).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                HStack {
                    Label("Rewatches", systemImage: "arrow.triangle.2.circlepath")
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text("\(title.rewatchCount)")
                        .font(Theme.rounded(16, .bold))
                        .foregroundStyle(Theme.inkSoft)
                        .monospacedDigit()
                    Button {
                        TitleActions.logRewatch(title, in: context)
                        Haptics.success(settings.hapticsEnabled)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Theme.accent)
                    }
                    .accessibilityLabel("Log a rewatch")
                }
            }
        }
    }

    private var scoreBinding: Binding<Int> {
        Binding(get: { title.score }, set: { newValue in
            title.score = min(max(newValue, 0), 10)
            try? context.save()
        })
    }

    private var statusBinding: Binding<WatchStatus> {
        Binding(get: { title.status }, set: { newValue in
            TitleActions.setStatus(title, to: newValue, in: context)
            Haptics.tap(settings.hapticsEnabled)
        })
    }

    // MARK: Metadata

    private var metadataSection: some View {
        card("Details", "info.circle.fill") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Pill(text: title.kind.rawValue, systemImage: title.kind.symbol, tint: Theme.violet)
                    if let season = title.seasonLabel {
                        Pill(text: season, systemImage: "calendar", tint: Theme.cyan)
                    }
                }
                if !title.genres.isEmpty {
                    FlowRow(spacing: 6) {
                        ForEach(title.genres.sorted { $0.name < $1.name }) { g in
                            Pill(text: g.name, tint: Theme.accent)
                        }
                    }
                }
                metadataRow("Added", title.addedAt.formatted(date: .abbreviated, time: .omitted))
                if let started = title.startedAt {
                    metadataRow("Started", started.formatted(date: .abbreviated, time: .omitted))
                }
                if let finished = title.finishedAt {
                    metadataRow("Finished", finished.formatted(date: .abbreviated, time: .omitted))
                }
                if settings.showTimeSpent {
                    metadataRow("Est. time", settings.formatMinutes(estimatedMinutes))
                }
            }
        }
    }

    private var estimatedMinutes: Int {
        let p = min(max(title.progress, 0), title.totalUnits ?? title.progress)
        return p * title.kind.minutesPerUnit * (1 + max(0, title.rewatchCount))
    }

    private func metadataRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
            Spacer()
            Text(value).font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.ink)
        }
    }

    // MARK: Notes

    private var notesSection: some View {
        card("Notes", "note.text") {
            if title.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("No notes yet. Tap Edit to add your thoughts.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkFaint)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(title.notes)
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: Logs

    private var logsSection: some View {
        card("Watch log", "clock.arrow.circlepath") {
            if sortedLogs.isEmpty {
                Text("No sessions logged. Use +1 to record progress as you watch or read.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkFaint)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 10) {
                    ForEach(sortedLogs) { log in
                        HStack(spacing: 12) {
                            Image(systemName: title.kind.symbol)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Theme.accent)
                                .frame(width: 26)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(title.kind.unitNoun.capitalized) \(log.fromUnit + 1)–\(log.toUnit)")
                                    .font(Theme.rounded(14, .semibold))
                                    .foregroundStyle(Theme.ink)
                                Text(log.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(Theme.rounded(12))
                                    .foregroundStyle(Theme.inkSoft)
                            }
                            Spacer()
                            Text("+\(log.delta)")
                                .font(Theme.rounded(14, .bold))
                                .foregroundStyle(Theme.good)
                                .monospacedDigit()
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }

    // MARK: Card helper

    private func card<Content: View>(_ titleText: String, _ symbol: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(titleText, systemImage: symbol)
                .font(Theme.display(17, .semibold))
                .foregroundStyle(Theme.ink)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface))
    }

    private func deleteTitle() {
        Haptics.success(settings.hapticsEnabled)
        context.delete(title)
        try? context.save()
        dismiss()
    }
}
