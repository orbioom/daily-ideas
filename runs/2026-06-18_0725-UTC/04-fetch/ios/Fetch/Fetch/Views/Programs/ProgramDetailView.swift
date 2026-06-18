import SwiftUI
import SwiftData

struct ProgramDetailView: View {
    let program: TrainingProgram

    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \Dog.createdAt) private var dogs: [Dog]
    @State private var sessionTrickId: String?

    private var activeDog: Dog? { DogManager.activeDog(from: dogs) }
    private var fraction: Double {
        guard let dog = activeDog else { return 0 }
        return ProgressEngine.programProgress(program, for: dog)
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    lessonsSection
                    Color.clear.frame(height: 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .navigationTitle(program.title)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: Binding(
            get: { sessionTrickId.map { ProgramSessionTarget(trickId: $0) } },
            set: { sessionTrickId = $0?.trickId }
        )) { target in
            if let dog = activeDog {
                SessionPlayerView(dog: dog, trickId: target.trickId)
            } else {
                NoDogSheet()
            }
        }
    }

    private var header: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Theme.accent.opacity(0.15))
                            .frame(width: 56, height: 56)
                        Image(systemName: program.icon)
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                            .accessibilityHidden(true)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(program.title)
                            .font(Theme.rounded(20, .bold))
                            .foregroundStyle(Theme.ink)
                        Text(program.subtitle)
                            .font(Theme.rounded(14))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    Spacer(minLength: 0)
                }
                Text(program.detail)
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)

                if let dog = activeDog {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("\(dog.name)'s progress")
                                .font(Theme.rounded(13, .semibold))
                                .foregroundStyle(Theme.inkSoft)
                            Spacer()
                            Text("\(Int(fraction * 100))%")
                                .font(Theme.rounded(15, .bold))
                                .foregroundStyle(Theme.accent)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Theme.hairline)
                                Capsule().fill(Theme.heroGradient)
                                    .frame(width: max(6, geo.size.width * fraction))
                            }
                        }
                        .frame(height: 10)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(dog.name) progress \(Int(fraction * 100)) percent")
                }
            }
        }
    }

    private var lessonsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Lessons", systemImage: "list.number")
            ForEach(Array(program.tricks.enumerated()), id: \.element.id) { index, trick in
                lessonRow(index: index, trick: trick)
            }
        }
    }

    private func lessonRow(index: Int, trick: Trick) -> some View {
        let status = activeDog.map { ProgressEngine.status(for: $0, trickId: trick.id) } ?? .notStarted
        return Card(padding: 14) {
            HStack(spacing: 12) {
                Text("\(index + 1)")
                    .font(Theme.rounded(14, .bold))
                    .foregroundStyle(status == .mastered ? .white : Theme.accent)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle().fill(status == .mastered ? AnyShapeStyle(Theme.good) : AnyShapeStyle(Theme.accent.opacity(0.12)))
                    )
                NavigationLink {
                    TrickDetailView(trick: trick) { startSession(trick.id) }
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(trick.name)
                            .font(Theme.rounded(16, .semibold))
                            .foregroundStyle(Theme.ink)
                        StatusBadge(status: status, compact: false)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.inkSoft)
                }
                .buttonStyle(.plain)

                Button {
                    startSession(trick.id)
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(9)
                        .background(Circle().fill(Theme.accent))
                }
                .accessibilityLabel("Practice \(trick.name)")
            }
        }
    }

    private func startSession(_ trickId: String) {
        guard activeDog != nil else { return }
        Haptics.impact(.medium, enabled: settings.hapticsEnabled)
        sessionTrickId = trickId
    }
}

private struct ProgramSessionTarget: Identifiable {
    let trickId: String
    var id: String { trickId }
}
