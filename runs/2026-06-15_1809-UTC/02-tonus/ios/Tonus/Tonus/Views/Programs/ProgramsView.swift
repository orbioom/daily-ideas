import SwiftUI
import SwiftData

struct ProgramsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \TrainingProgram.sortIndex) private var programs: [TrainingProgram]

    @State private var paywallReason: PaywallReason?
    @State private var showBuilder = false
    @State private var editingProgram: TrainingProgram?

    /// Programs grouped by level, ascending.
    private var grouped: [(level: Int, items: [TrainingProgram])] {
        let dict = Dictionary(grouping: programs) { $0.level }
        return dict.keys.sorted().map { level in
            (level, (dict[level] ?? []).sorted { $0.sortIndex < $1.sortIndex })
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if programs.isEmpty {
                    EmptyStateView(
                        symbol: "list.bullet.rectangle.portrait",
                        title: "No programs yet",
                        message: "Your built-in programs are loading. Pull to refresh if this lingers."
                    )
                } else {
                    programList
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Programs")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if isPro {
                            editingProgram = nil
                            showBuilder = true
                        } else {
                            paywallReason = .customBuilder
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Create custom program")
                }
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .sheet(isPresented: $showBuilder) {
                ProgramBuilderView(existing: editingProgram)
            }
        }
    }

    private var programList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 22, pinnedViews: []) {
                ForEach(grouped, id: \.level) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(levelName(group.level))
                            .font(Theme.rounded(15, .bold))
                            .foregroundStyle(Theme.inkFaint)
                            .padding(.horizontal, 4)
                        ForEach(group.items) { program in
                            NavigationLink {
                                ProgramDetailView(program: program,
                                                  onEdit: { p in editingProgram = p; showBuilder = true })
                            } label: {
                                ProgramRow(program: program, locked: isLocked(program))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    private func levelName(_ level: Int) -> String {
        switch level {
        case 1: return "Beginner"
        case 2: return "Intermediate"
        case 3: return "Advanced"
        default: return "Level \(level)"
        }
    }

    private func isLocked(_ program: TrainingProgram) -> Bool {
        !isPro && program.level > Pro.freeMaxLevel
    }
}

/// A program card row.
struct ProgramRow: View {
    let program: TrainingProgram
    let locked: Bool

    private var engine: SessionEngine { SessionEngine(program: program) }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.accentSoft)
                    .frame(width: 50, height: 50)
                Image(systemName: locked ? "lock.fill" : "circle.circle.fill")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(program.name)
                        .font(Theme.rounded(17, .semibold))
                        .foregroundStyle(Theme.ink)
                    if !program.isBuiltIn {
                        Text("Custom")
                            .font(Theme.rounded(10, .bold))
                            .foregroundStyle(Theme.accent)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(Theme.accentSoft))
                    }
                    if locked { ProLockChip() }
                }
                Text("\(engine.totalReps) reps · \(engine.durationLabel)")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.inkFaint)
                .accessibilityHidden(true)
        }
        .padding(14)
        .cardSurface()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(program.name), \(program.levelLabel), \(engine.totalReps) reps, \(engine.durationLabel)\(locked ? ", Pro locked" : "")")
        .accessibilityHint("Opens program details")
    }
}
