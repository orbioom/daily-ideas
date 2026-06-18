import SwiftUI
import SwiftData

struct TrickDetailView: View {
    let trick: Trick
    let onStartSession: () -> Void

    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \Dog.createdAt) private var dogs: [Dog]
    @State private var showStatusMenu = false

    private var activeDog: Dog? { DogManager.activeDog(from: dogs) }
    private var status: TrickStatus {
        activeDog.map { ProgressEngine.status(for: $0, trickId: trick.id) } ?? .notStarted
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    if let dog = activeDog {
                        statusCard(for: dog)
                    }
                    prerequisitesCard
                    stepsCard
                    if !trick.tips.isEmpty { tipsCard }
                    Color.clear.frame(height: 80)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }

            VStack {
                Spacer()
                startButton
            }
        }
        .navigationTitle(trick.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(trick.difficulty.color.opacity(0.15))
                            .frame(width: 58, height: 58)
                        Image(systemName: trick.icon)
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(trick.difficulty.color)
                            .accessibilityHidden(true)
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text(trick.name)
                            .font(Theme.rounded(22, .bold))
                            .foregroundStyle(Theme.ink)
                        HStack(spacing: 8) {
                            Chip(text: trick.category.rawValue, systemImage: trick.category.icon)
                            Chip(text: trick.difficulty.label, color: trick.difficulty.color)
                        }
                    }
                    Spacer(minLength: 0)
                }
                Text(trick.summary)
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
                HStack(spacing: 16) {
                    Label("~\(trick.estimatedDays) days", systemImage: "calendar")
                    DifficultyDots(difficulty: trick.difficulty)
                }
                .font(Theme.rounded(13, .medium))
                .foregroundStyle(Theme.inkSoft)
            }
        }
    }

    private func statusCard(for dog: Dog) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "\(dog.name)'s status", systemImage: "target")
                HStack(spacing: 8) {
                    ForEach(TrickStatus.allCases) { s in
                        Button {
                            setStatus(s, for: dog)
                        } label: {
                            Text(s.rawValue)
                                .font(Theme.rounded(12, .semibold))
                                .foregroundStyle(s == status ? .white : Theme.inkSoft)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(
                                    Capsule().fill(s == status ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(Theme.surfaceAlt))
                                )
                        }
                        .accessibilityLabel("Set status \(s.rawValue)")
                        .accessibilityAddTraits(s == status ? [.isSelected] : [])
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private var prerequisitesCard: some View {
        if !trick.prerequisites.isEmpty {
            Card {
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Prerequisites", systemImage: "list.bullet.indent")
                    ForEach(trick.prerequisites, id: \.self) { preId in
                        if let pre = TrickCatalog.trick(preId) {
                            HStack(spacing: 10) {
                                Image(systemName: preMet(preId) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(preMet(preId) ? Theme.good : Theme.inkSoft)
                                Text(pre.name)
                                    .font(Theme.rounded(15, .medium))
                                    .foregroundStyle(Theme.ink)
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
    }

    private var stepsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Step by step", systemImage: "figure.walk")
                ForEach(Array(trick.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(Theme.rounded(14, .bold))
                            .foregroundStyle(.white)
                            .frame(width: 26, height: 26)
                            .background(Circle().fill(Theme.accent))
                        Text(step)
                            .font(Theme.rounded(15))
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    private var tipsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Trainer tips", systemImage: "lightbulb.fill")
                ForEach(Array(trick.tips.enumerated()), id: \.offset) { _, tip in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Theme.warn)
                            .padding(.top, 3)
                        Text(tip)
                            .font(Theme.rounded(14))
                            .foregroundStyle(Theme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    private var startButton: some View {
        Button {
            onStartSession()
        } label: {
            Label("Start practice session", systemImage: "play.fill")
        }
        .buttonStyle(PrimaryButtonStyle(enabled: activeDog != nil))
        .disabled(activeDog == nil)
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
        .background(
            LinearGradient(colors: [Theme.bg.opacity(0), Theme.bg], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        )
    }

    private func preMet(_ preId: String) -> Bool {
        guard let dog = activeDog else { return false }
        return ProgressEngine.status(for: dog, trickId: preId).rank >= TrickStatus.practicing.rank
    }

    private func setStatus(_ newStatus: TrickStatus, for dog: Dog) {
        let row = DogManager.progressRow(for: dog, trickId: trick.id, context: context)
        row.status = newStatus
        row.updatedAt = Date()
        try? context.save()
        Haptics.selection(enabled: settings.hapticsEnabled)
    }
}
