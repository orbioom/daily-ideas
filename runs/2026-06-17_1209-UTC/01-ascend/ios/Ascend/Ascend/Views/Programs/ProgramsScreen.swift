import SwiftUI
import SwiftData

/// Programs — your saved programs plus the built-in catalog. Set active, view, build custom.
struct ProgramsScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \Program.createdAt, order: .reverse) private var programs: [Program]

    @State private var paywallReason: PaywallReason?
    @State private var showBuilder = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if programs.isEmpty {
                            EmptyStateView(symbol: "square.grid.2x2",
                                           title: "No programs yet",
                                           message: "Add a built-in program below, or build your own with Ascend Pro.")
                                .padding(.top, 40)
                        } else {
                            sectionHeader("Your programs")
                            ForEach(programs) { program in
                                NavigationLink {
                                    ProgramDetailView(program: program)
                                } label: {
                                    ProgramRow(program: program, onSetActive: { setActive(program) })
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        sectionHeader("Add a built-in")
                        ForEach(BuiltInPrograms.all) { bp in
                            builtInRow(bp)
                        }

                        customRow
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Programs")
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .sheet(isPresented: $showBuilder) {
                NavigationStack { ProgramBuilderView() }
            }
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text.uppercased())
            .font(Theme.rounded(13, .bold))
            .foregroundStyle(Theme.inkSoft)
            .padding(.top, 4)
    }

    private func builtInRow(_ bp: BuiltInPrograms.Blueprint) -> some View {
        Card {
            HStack(spacing: 14) {
                Image(systemName: bp.type.symbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 34)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(bp.name)
                        .font(Theme.rounded(16, .bold))
                        .foregroundStyle(Theme.ink)
                    Text(bp.summary)
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Button {
                    addBuiltIn(bp)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(Theme.accent)
                }
                .accessibilityLabel("Add \(bp.name)")
            }
        }
    }

    private var customRow: some View {
        Button {
            if isPro {
                showBuilder = true
            } else {
                paywallReason = .customBuilder
            }
        } label: {
            Card {
                HStack(spacing: 14) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                        .frame(width: 34)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text("Build a custom program")
                                .font(Theme.rounded(16, .bold))
                                .foregroundStyle(Theme.ink)
                            if !isPro { Pill(text: "PRO", color: Theme.accent, filled: true) }
                        }
                        Text("Your own days, exercises, and progression.")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.inkFaint)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Actions

    private func addBuiltIn(_ bp: BuiltInPrograms.Blueprint) {
        let makeActive = programs.isEmpty
        let program = BuiltInPrograms.makeProgram(from: bp, isActive: makeActive)
        if makeActive { deactivateAll() }
        context.insert(program)
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
    }

    private func setActive(_ program: Program) {
        deactivateAll()
        program.isActive = true
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
    }

    private func deactivateAll() {
        for p in programs where p.isActive { p.isActive = false }
    }
}

/// A row for a saved program with an active toggle.
private struct ProgramRow: View {
    @Bindable var program: Program
    let onSetActive: () -> Void

    var body: some View {
        Card {
            HStack(spacing: 14) {
                Image(systemName: program.type.symbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(program.isActive ? Theme.accent : Theme.steel)
                    .frame(width: 34)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(program.name)
                            .font(Theme.rounded(16, .bold))
                            .foregroundStyle(Theme.ink)
                        if program.isActive { Pill(text: "ACTIVE", color: Theme.good, filled: true) }
                    }
                    Text("\(program.orderedDays.count) days · \(program.type.label)")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                if !program.isActive {
                    Button("Set active", action: onSetActive)
                        .font(Theme.rounded(13, .semibold))
                        .foregroundStyle(Theme.accent)
                }
            }
        }
    }
}
