import SwiftUI
import SwiftData

struct IntentionDetailView: View {
    @Bindable var intention: Intention
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var showEdit = false
    @State private var showDelete = false
    @State private var session: Phase?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                affirmationCard
                progressCard
                heatmapCard
                scriptingCard
                stateButtons
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .background(Theme.bgPrimary.ignoresSafeArea())
        .navigationTitle(intention.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showEdit = true } label: { Label("Edit", systemImage: "pencil") }
                    Button(role: .destructive) { showDelete = true } label: { Label("Delete", systemImage: "trash") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showEdit) { IntentionEditView(intention: intention) }
        .fullScreenCover(item: $session) { phase in
            SessionView(intention: intention, phase: phase)
        }
        .confirmationDialog("Delete this intention and its practice history?",
                            isPresented: $showDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                context.delete(intention); try? context.save(); dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var affirmationCard: some View {
        VStack(spacing: 12) {
            CategoryChip(category: intention.category)
            Text(intention.affirmation)
                .font(.system(.title3, design: .serif).weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
            if intention.state == .active {
                Button { Haptics.tap(); session = Phase.recommended() } label: {
                    Label("Practice now", systemImage: "pencil.line").font(.headline).frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent).tint(Theme.accent).controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity)
        .beckonCard()
    }

    private var progressCard: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle().stroke(Theme.track, lineWidth: 8).frame(width: 78, height: 78)
                Circle().trim(from: 0, to: intention.cycleProgress)
                    .stroke(Theme.goldGradient, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90)).frame(width: 78, height: 78)
                Text("\(Int(intention.cycleProgress * 100))%")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
            }
            VStack(alignment: .leading, spacing: 6) {
                DetailLine(label: "Completed days", value: "\(intention.completedDays) / \(intention.practiceLength)")
                DetailLine(label: "Total reps", value: "\(intention.logs.reduce(0) { $0 + $1.totalReps })")
                DetailLine(label: "Started", value: Fmt.date(intention.createdAt))
            }
            Spacer()
        }
        .beckonCard()
    }

    private var heatmapCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Last 5 weeks").font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textSecondary)
            PracticeHeatmap(intention: intention)
            HStack(spacing: 10) {
                legend(Theme.track, "Missed")
                legend(Theme.accent.opacity(0.4), "Partial")
                legend(Theme.accent, "3-6-9")
            }
            .font(.caption2).foregroundStyle(Theme.textSecondary)
        }
        .beckonCard()
    }

    private func legend(_ color: Color, _ text: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 12, height: 12)
            Text(text)
        }
    }

    private var scriptingCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Scripting", systemImage: "text.quote")
                .font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textSecondary)
            Text("Write freely as if it has already happened.")
                .font(.caption).foregroundStyle(Theme.textSecondary)
            TextField("It happened, and here's how it felt…", text: $intention.notes, axis: .vertical)
                .lineLimit(4...10)
                .padding(12)
                .background(Theme.track.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(Theme.textPrimary)
                .onChange(of: intention.notes) { _, _ in try? context.save() }
        }
        .beckonCard()
    }

    @ViewBuilder private var stateButtons: some View {
        VStack(spacing: 10) {
            if intention.state != .manifested {
                Button {
                    Haptics.success(); intention.state = .manifested; intention.manifestedAt = Date(); try? context.save()
                } label: {
                    Label("Mark as manifested", systemImage: "checkmark.seal.fill")
                        .font(.headline).frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent).tint(Theme.accent).controlSize(.large)
            } else {
                Button {
                    Haptics.tap(); intention.state = .active; intention.manifestedAt = nil; try? context.save()
                } label: {
                    Label("Reactivate", systemImage: "arrow.counterclockwise")
                        .font(.headline).frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered).tint(Theme.accent).controlSize(.large)
            }
            if intention.state != .released {
                Button {
                    Haptics.tap(); intention.state = .released; try? context.save()
                } label: {
                    Label("Release this intention", systemImage: "wind").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered).tint(Theme.textSecondary).controlSize(.large)
            }
        }
    }
}

struct DetailLine: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).font(.caption).foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(value).font(.caption.weight(.semibold)).foregroundStyle(Theme.textPrimary)
        }
    }
}

/// A 5-week × 7-day grid coloured by daily 369 completeness.
struct PracticeHeatmap: View {
    let intention: Intention
    private let weeks = 5
    private let cal = Calendar.current

    var body: some View {
        let days = gridDays()
        VStack(spacing: 4) {
            ForEach(0..<7, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<weeks, id: \.self) { col in
                        let date = days[col * 7 + row]
                        cell(for: date)
                    }
                }
            }
        }
        .accessibilityLabel("Practice calendar for the last five weeks")
    }

    private func cell(for date: Date) -> some View {
        let log = intention.log(for: date)
        let future = date > Date()
        let color: Color = {
            if future { return .clear }
            if let log, log.isComplete { return Theme.accent }
            if let log, log.totalReps > 0 { return Theme.accent.opacity(0.4) }
            return Theme.track
        }()
        return RoundedRectangle(cornerRadius: 3)
            .fill(color)
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
    }

    /// Columns are weeks (oldest first); rows are weekdays (top = oldest in week).
    /// Index `col*7 + row`; the last cell (col=weeks-1, row=6) is today.
    private func gridDays() -> [Date] {
        let today = cal.startOfDay(for: Date())
        var grid = [Date](repeating: today, count: weeks * 7)
        for col in 0..<weeks {
            for row in 0..<7 {
                let offset = (weeks - 1 - col) * 7 + (6 - row)
                grid[col * 7 + row] = cal.date(byAdding: .day, value: -offset, to: today) ?? today
            }
        }
        return grid
    }
}
