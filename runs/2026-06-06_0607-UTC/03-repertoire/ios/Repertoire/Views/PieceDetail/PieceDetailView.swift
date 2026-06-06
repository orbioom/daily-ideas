import SwiftUI
import SwiftData

/// A piece's home: header, spots with tempo progress, session history, and the
/// focal "Practice" action that opens a metronome-driven session for this piece.
struct PieceDetailView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Bindable var piece: Piece

    @State private var showingEditPiece = false
    @State private var showingPractice = false
    @State private var editingSpot: PracticeSpot?
    @State private var showingAddSpot = false
    @State private var showingShare = false
    @State private var shareURL: URL?

    private var sortedHistory: [(session: PracticeSession, minutes: Int)] {
        piece.entries
            .compactMap { entry -> (PracticeSession, Int)? in
                guard let session = entry.session else { return nil }
                return (session, entry.minutes)
            }
            .sorted { $0.0.date > $1.0.date }
    }

    private var totalMinutes: Int {
        piece.entries.reduce(0) { $0 + $1.minutes }
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    spotsSection
                    historySection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }

            VStack {
                Spacer()
                InkButton(title: "Practice this piece", systemImage: "metronome") {
                    showingPractice = true
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                .background(
                    LinearGradient(colors: [Brand.mist1.opacity(0), Brand.mist1],
                                   startPoint: .top, endPoint: .bottom)
                        .frame(height: 90)
                        .allowsHitTesting(false),
                    alignment: .bottom
                )
            }
        }
        .navigationTitle(piece.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingEditPiece = true
                    } label: {
                        Label("Edit piece", systemImage: "pencil")
                    }
                    Button {
                        exportLog()
                    } label: {
                        Label("Export log (CSV)", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Piece options")
            }
        }
        .sheet(isPresented: $showingEditPiece) {
            PieceEditView(piece: piece)
        }
        .sheet(isPresented: $showingPractice) {
            PracticeView(piece: piece)
        }
        .sheet(item: $editingSpot) { spot in
            SpotEditView(piece: piece, spot: spot)
        }
        .sheet(isPresented: $showingAddSpot) {
            SpotEditView(piece: piece, spot: nil)
        }
        .sheet(isPresented: $showingShare) {
            if let shareURL {
                ShareSheet(items: [shareURL])
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(piece.title)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Brand.text)
                        if !piece.composer.trimmingCharacters(in: .whitespaces).isEmpty {
                            Text(piece.composer)
                                .font(.subheadline)
                                .foregroundStyle(Brand.text2)
                        }
                    }
                    Spacer(minLength: 8)
                    StatusBadge(status: piece.status)
                }

                FlowLayout(spacing: 8) {
                    metaChip("music.note", piece.instrument)
                    metaChip("dial.medium", piece.difficulty.title)
                    if !piece.key.trimmingCharacters(in: .whitespaces).isEmpty {
                        metaChip("key", piece.key)
                    }
                    if piece.hasTarget {
                        metaChip("metronome", "\(piece.targetTempo) BPM")
                    }
                    metaChip("clock", "\(totalMinutes) min total")
                    metaChip("calendar", Insights.lastPracticedPhrase(piece))
                }

                if !piece.notes.trimmingCharacters(in: .whitespaces).isEmpty {
                    Text(piece.notes)
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func metaChip(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.caption2)
            Text(text).font(.caption.weight(.medium))
        }
        .foregroundStyle(Brand.text2)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Brand.glassStroke.opacity(0.25), in: Capsule())
        .overlay(Capsule().strokeBorder(Brand.glassStroke.opacity(0.4), lineWidth: 1))
    }

    // MARK: - Spots

    private var spotsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionLabel(text: "Practice Spots")
                Spacer()
                Button {
                    showingAddSpot = true
                } label: {
                    Label("Add", systemImage: "plus").font(.caption.weight(.semibold))
                }
                .tint(Brand.text)
            }

            if piece.orderedSpots.isEmpty {
                GlassCard {
                    Text("No spots yet. Add the passages or skills you want to drill.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ForEach(piece.orderedSpots) { spot in
                    Button {
                        editingSpot = spot
                    } label: {
                        SpotRow(spot: spot)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Session History")
            if sortedHistory.isEmpty {
                GlassCard {
                    Text("No sessions logged for this piece yet. Tap Practice to begin.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ForEach(sortedHistory, id: \.session.id) { item in
                    SessionHistoryRow(session: item.session, minutes: item.minutes)
                }
            }
        }
    }

    // MARK: - Export

    private func exportLog() {
        let csv = Exporter.pieceLogCSV(piece)
        let name = "\(piece.title)-log.csv"
        if let url = Exporter.temporaryFile(named: name, contents: csv) {
            shareURL = url
            showingShare = true
            Haptics.impact(enabled: settings.hapticsEnabled)
        }
    }
}

// MARK: - Spot row

private struct SpotRow: View {
    var spot: PracticeSpot

    var body: some View {
        GlassCard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text(spot.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Brand.text)
                        .lineLimit(2)
                    Spacer(minLength: 8)
                    if spot.atTarget {
                        Label("At target", systemImage: "checkmark.circle.fill")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Brand.live)
                            .labelStyle(.titleAndIcon)
                    }
                }
                if spot.targetTempo >= Tempo.min {
                    HStack(spacing: 8) {
                        Text("\(spot.currentTempo) → \(spot.targetTempo) BPM")
                            .font(Brand.mono(13))
                            .foregroundStyle(Brand.text2)
                            .monospacedDigit()
                        Spacer()
                        MasteryDots(level: spot.clampedMastery)
                    }
                    TempoProgressBar(current: spot.currentTempo, target: spot.targetTempo)
                } else {
                    HStack {
                        Text(spot.currentTempo > 0 ? "\(spot.currentTempo) BPM" : "No tempo set")
                            .font(Brand.mono(13))
                            .foregroundStyle(Brand.text3)
                            .monospacedDigit()
                        Spacer()
                        MasteryDots(level: spot.clampedMastery)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("Edit spot")
    }
}

// MARK: - Session history row

struct SessionHistoryRow: View {
    var session: PracticeSession
    var minutes: Int

    var body: some View {
        GlassCard(padding: 14) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(session.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Brand.text)
                    HStack(spacing: 10) {
                        Label("\(minutes) min", systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(Brand.text2)
                        if session.tempo > 0 {
                            Label("\(session.tempo) BPM", systemImage: "metronome")
                                .font(.caption)
                                .foregroundStyle(Brand.text2)
                        }
                    }
                    .labelStyle(.titleAndIcon)
                    if !session.focusNotes.isEmpty {
                        Text(session.focusNotes)
                            .font(.caption)
                            .foregroundStyle(Brand.text3)
                            .lineLimit(2)
                    }
                }
                Spacer(minLength: 6)
                if let quality = session.quality {
                    VStack(spacing: 3) {
                        Image(systemName: quality.systemImage)
                            .font(.subheadline)
                            .foregroundStyle(Brand.text2)
                        Text(quality.title)
                            .font(.caption2)
                            .foregroundStyle(Brand.text3)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Quality: \(quality.title)")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PieceDetailView(piece: PreviewData.samplePiece)
            .environment(SettingsStore())
    }
    .previewContainer()
}
