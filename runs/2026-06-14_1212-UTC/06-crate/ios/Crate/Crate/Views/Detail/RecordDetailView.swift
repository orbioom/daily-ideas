import SwiftUI
import SwiftData

/// Record Detail — hero, tracklist by side with runtime, condition + value, spin log, actions.
struct RecordDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Bindable var record: Record

    @State private var showEdit = false
    @State private var showSpinEditor = false
    @State private var editingSpin: Spin?
    @State private var showDeleteConfirm = false
    @State private var spinAngle: Double = 0
    @State private var justLogged = false

    private var sortedSides: [String] {
        Array(Set(record.tracks.map { $0.side })).sorted()
    }

    private var sortedSpins: [Spin] {
        record.spins.sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                hero
                metaRow
                conditionCard
                if !record.tracks.isEmpty { tracklistCard }
                spinLogCard
                if !record.notes.isEmpty { notesCard }
                actionButtons
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(record.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showEdit = true } label: { Label("Edit", systemImage: "pencil") }
                    Button(role: .destructive) { showDeleteConfirm = true } label: {
                        Label("Delete record", systemImage: "trash")
                    }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showEdit) {
            RecordEditorView(record: record, initialStatus: record.status)
        }
        .sheet(isPresented: $showSpinEditor) {
            SpinEditorView(record: record, spin: editingSpin)
        }
        .confirmationDialog("Delete this record?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { deleteRecord() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes \(record.title) and its tracklist and spin history.")
        }
    }

    // MARK: Hero

    private var hero: some View {
        VStack(spacing: 12) {
            ZStack {
                VinylDisc(labelHue: record.coverHue, labelFraction: 0.42)
                    .frame(width: 220, height: 220)
                    .rotationEffect(.degrees(spinAngle))
                    .offset(x: 70)
                CoverArtView(title: record.title, artist: record.artist, hue: record.coverHue, showDisc: false)
                    .frame(width: 190, height: 190)
                    .offset(x: -28)
                    .shadow(color: .black.opacity(0.25), radius: 8, x: -2, y: 4)
            }
            .frame(height: 230)
            VStack(spacing: 3) {
                Text(record.title)
                    .font(Theme.serif(24, .bold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                Text(record.artist)
                    .font(Theme.rounded(17))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear { startSpin() }
    }

    private var metaRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Pill(text: record.status.display, systemImage: record.status.symbol,
                     tint: record.status == .owned ? Theme.good : Theme.accent)
                Pill(text: record.format.display, systemImage: record.format.symbol, tint: Theme.accent)
                Pill(text: record.speed.display, systemImage: "metronome")
                Pill(text: record.genre.rawValue, systemImage: record.genre.symbol, tint: record.genre.hue)
                Pill(text: record.yearLabel, systemImage: "calendar")
                Pill(text: record.vinylColor, systemImage: "paintpalette")
                if !record.label.isEmpty {
                    Pill(text: record.label, systemImage: "tag")
                }
                if !record.catalogNo.isEmpty {
                    Pill(text: record.catalogNo, systemImage: "number")
                }
            }
        }
    }

    // MARK: Condition + value

    private var conditionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Condition & value")
                .font(Theme.serif(18, .semibold)).foregroundStyle(Theme.ink)
            HStack(spacing: 10) {
                GradeChip(label: "Media", grade: record.mediaCondition, display: settings.gradeText(record.mediaCondition))
                GradeChip(label: "Sleeve", grade: record.sleeveCondition, display: settings.gradeText(record.sleeveCondition))
                Spacer()
            }
            if !settings.hideValues {
                Divider().background(Theme.hairline)
                HStack {
                    valueLine("Paid", record.pricePaid)
                    Spacer()
                    valueLine("Est. value", record.estValue)
                    Spacer()
                    let delta = record.estValue - record.pricePaid
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(delta >= 0 ? "Upside" : "Below")
                            .font(Theme.rounded(11, .semibold)).foregroundStyle(Theme.inkFaint)
                        Text((delta >= 0 ? "+" : "") + settings.formatMoney(delta))
                            .font(Theme.rounded(16, .bold))
                            .foregroundStyle(delta >= 0 ? Theme.good : Theme.bad)
                            .monospacedDigit()
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
    }

    private func valueLine(_ label: String, _ amount: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(Theme.rounded(11, .semibold)).foregroundStyle(Theme.inkFaint)
            Text(settings.formatMoney(amount))
                .font(Theme.rounded(16, .bold)).foregroundStyle(Theme.ink).monospacedDigit()
        }
    }

    // MARK: Tracklist

    private var tracklistCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tracklist").font(Theme.serif(18, .semibold)).foregroundStyle(Theme.ink)
                Spacer()
                Text("\(record.tracks.count) tracks · \(Fmt.runtime(record.totalRuntimeSeconds))")
                    .font(Theme.rounded(12, .semibold)).foregroundStyle(Theme.inkSoft)
            }
            ForEach(sortedSides, id: \.self) { side in
                VStack(alignment: .leading, spacing: 6) {
                    Text("Side \(side)")
                        .font(Theme.rounded(12, .bold))
                        .foregroundStyle(Theme.accent)
                    let sideTracks = record.tracks
                        .filter { $0.side == side }
                        .sorted { $0.position < $1.position }
                    ForEach(sideTracks) { t in
                        HStack(spacing: 10) {
                            Text("\(t.position)")
                                .font(Theme.rounded(12)).foregroundStyle(Theme.inkFaint)
                                .frame(width: 18, alignment: .trailing)
                            Text(t.title.isEmpty ? "Untitled" : t.title)
                                .font(Theme.rounded(14)).foregroundStyle(Theme.ink)
                                .lineLimit(1)
                            Spacer()
                            Text(t.durationLabel)
                                .font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft).monospacedDigit()
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
    }

    // MARK: Spin log

    private var spinLogCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Spin log").font(Theme.serif(18, .semibold)).foregroundStyle(Theme.ink)
                Spacer()
                Text("\(record.spinCount) spin\(record.spinCount == 1 ? "" : "s")")
                    .font(Theme.rounded(12, .semibold)).foregroundStyle(Theme.inkSoft)
            }
            if justLogged {
                Label("Spin logged", systemImage: "checkmark.circle.fill")
                    .font(Theme.rounded(13, .semibold)).foregroundStyle(Theme.good)
                    .transition(.opacity)
            }
            Button { logSpin() } label: {
                Label("Log a spin", systemImage: "play.circle.fill")
                    .font(Theme.rounded(15, .semibold)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.accent))
            }
            if sortedSpins.isEmpty {
                Text("No spins yet. Drop the needle and log your first.")
                    .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
            } else {
                ForEach(sortedSpins) { spin in
                    Button { editingSpin = spin; showSpinEditor = true } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "opticaldisc")
                                .foregroundStyle(Theme.accent).accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(spin.dateLabel)
                                    .font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.ink)
                                if !spin.note.isEmpty {
                                    Text(spin.note).font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft).lineLimit(1)
                                }
                            }
                            Spacer()
                            if spin.rating > 0 {
                                HStack(spacing: 1) {
                                    ForEach(1...5, id: \.self) { i in
                                        Image(systemName: i <= spin.rating ? "star.fill" : "star")
                                            .font(.system(size: 9)).foregroundStyle(Theme.accent)
                                    }
                                }
                                .accessibilityLabel("\(spin.rating) of 5 stars")
                            }
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11)).foregroundStyle(Theme.inkFaint)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
        .animation(.easeInOut, value: justLogged)
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes").font(Theme.serif(18, .semibold)).foregroundStyle(Theme.ink)
            Text(record.notes)
                .font(Theme.rounded(15)).foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            PrimaryButton(title: "Edit record", systemImage: "pencil") { showEdit = true }
            Button(role: .destructive) { showDeleteConfirm = true } label: {
                Label("Delete record", systemImage: "trash")
                    .font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.bad)
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.bad.opacity(0.10)))
            }
        }
    }

    // MARK: Actions

    private func startSpin() {
        guard !reduceMotion else { return }
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) { spinAngle = 360 }
    }

    private func logSpin() {
        let spin = Spin(date: .now, rating: 0, note: "")
        spin.record = record
        record.spins.append(spin)
        try? context.save()
        justLogged = true
        Haptics.success(settings.hapticsEnabled)
    }

    private func deleteRecord() {
        context.delete(record)
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}
