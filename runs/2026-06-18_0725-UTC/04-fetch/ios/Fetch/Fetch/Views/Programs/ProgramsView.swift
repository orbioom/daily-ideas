import SwiftUI
import SwiftData

struct ProgramsView: View {
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \Dog.createdAt) private var dogs: [Dog]
    @State private var showPaywall = false

    private var activeDog: Dog? { DogManager.activeDog(from: dogs) }

    private func isLocked(_ index: Int, _ program: TrainingProgram) -> Bool {
        guard program.requiresPro, !isPro else { return false }
        return index >= Pro.freeProgramCount
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(Array(ProgramCatalog.all.enumerated()), id: \.element.id) { index, program in
                            let locked = isLocked(index, program)
                            Group {
                                if locked {
                                    Button { showPaywall = true } label: {
                                        ProgramCard(program: program, dog: activeDog, locked: true)
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    NavigationLink {
                                        ProgramDetailView(program: program)
                                    } label: {
                                        ProgramCard(program: program, dog: activeDog, locked: false)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("Programs")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }
}

struct ProgramCard: View {
    let program: TrainingProgram
    let dog: Dog?
    let locked: Bool

    private var fraction: Double {
        guard let dog, !locked else { return 0 }
        return ProgressEngine.programProgress(program, for: dog)
    }
    private var masteredCount: Int {
        guard let dog else { return 0 }
        return ProgressEngine.programMasteredCount(program, for: dog)
    }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Theme.accent.opacity(0.15))
                            .frame(width: 54, height: 54)
                        Image(systemName: program.icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                            .accessibilityHidden(true)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(program.title)
                                .font(Theme.rounded(17, .bold))
                                .foregroundStyle(Theme.ink)
                            if locked {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Theme.warn)
                            }
                        }
                        Text(program.subtitle)
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkSoft)
                            .lineLimit(2)
                    }
                    Spacer(minLength: 0)
                    if !locked {
                        ProgressRing(fraction: fraction, size: 46, lineWidth: 6,
                                     label: "\(Int(fraction * 100))%")
                    }
                }
                HStack(spacing: 12) {
                    Chip(text: "\(program.trickIDs.count) lessons", systemImage: "checklist")
                    Chip(text: "\(program.durationWeeks) wk plan", systemImage: "calendar")
                    if !locked && dog != nil {
                        Chip(text: "\(masteredCount) mastered", systemImage: "checkmark.seal.fill", color: Theme.good)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(program.title). \(locked ? "Locked, Pro feature." : "\(Int(fraction * 100)) percent complete.")")
    }
}
