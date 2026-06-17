import SwiftUI
import SwiftData

struct LessonsView: View {
    let activeProfile: Profile?

    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                WarmBackground()
                content
            }
            .navigationTitle("Lessons")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    @ViewBuilder private var content: some View {
        if let profile = activeProfile {
            ScrollView {
                VStack(spacing: 16) {
                    headerCard(for: profile)

                    if isPro {
                        NavigationLink {
                            WordTracingSetupView(profile: profile)
                        } label: {
                            wordTracingRow
                        }
                        .buttonStyle(.plain)
                    }

                    ForEach(GlyphSetKind.allCases) { set in
                        SetCard(
                            set: set,
                            locked: set.requiresPro && !isPro,
                            profile: profile,
                            onLockedTap: { showPaywall = true }
                        )
                    }
                }
                .padding(20)
            }
        } else {
            EmptyStateView(
                icon: "person.fill.questionmark",
                title: "Pick a kid first",
                message: "Add or choose a kid on the Kids tab to start tracing."
            )
        }
    }

    private func headerCard(for profile: Profile) -> some View {
        HStack(spacing: 14) {
            AvatarBubble(initial: profile.initial, color: profile.avatarColor, size: 52)
            VStack(alignment: .leading, spacing: 2) {
                Text("Tracing for")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                Text(profile.name)
                    .font(Theme.rounded(22, .bold))
                    .foregroundStyle(Theme.ink)
            }
            Spacer()
        }
        .padding(16)
        .card(fill: Theme.surfaceAlt)
    }

    private var wordTracingRow: some View {
        HStack(spacing: 14) {
            Image(systemName: "character.cursor.ibeam")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(Circle().fill(Theme.berry))
            VStack(alignment: .leading, spacing: 2) {
                Text("Trace a word")
                    .font(Theme.rounded(20, .bold))
                    .foregroundStyle(Theme.ink)
                Text("Type a name or short word")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(Theme.inkSoft)
        }
        .padding(16)
        .card()
    }
}

private struct SetCard: View {
    let set: GlyphSetKind
    let locked: Bool
    let profile: Profile
    let onLockedTap: () -> Void

    @Environment(\.modelContext) private var context

    private var glyphs: [Glyph] { GlyphLibrary.glyphs(for: set) }

    private var earnedStars: Int {
        let keys = Set(glyphs.map { $0.key })
        return ProgressService.progress(for: profile.id, context: context)
            .filter { keys.contains($0.glyphKey) }
            .reduce(0) { $0 + $1.bestStars }
    }

    private var maxStars: Int { glyphs.count * 3 }

    var body: some View {
        Group {
            if locked {
                Button(action: onLockedTap) { cardBody }
                    .buttonStyle(.plain)
            } else {
                NavigationLink {
                    GlyphGridView(set: set, profile: profile)
                } label: { cardBody }
                .buttonStyle(.plain)
            }
        }
    }

    private var cardBody: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                Image(systemName: set.icon)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(tint))
                VStack(alignment: .leading, spacing: 3) {
                    Text(set.title)
                        .font(Theme.rounded(20, .bold))
                        .foregroundStyle(Theme.ink)
                    Text("\(glyphs.count) to trace")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                if locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Theme.accent)
                } else {
                    Image(systemName: "chevron.right").foregroundStyle(Theme.inkSoft)
                }
            }

            if !locked {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill").foregroundStyle(Theme.star)
                    Text("\(earnedStars) / \(maxStars) stars")
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                    Spacer()
                    ProgressBar(value: maxStars > 0 ? Double(earnedStars) / Double(maxStars) : 0)
                        .frame(width: 120, height: 10)
                }
            }
        }
        .padding(16)
        .card(fill: locked ? Theme.accentSoft.opacity(0.4) : Theme.surface)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(set.title)\(locked ? ", locked, requires Pro" : ", \(earnedStars) of \(maxStars) stars")")
        .accessibilityHint(locked ? "Opens the upgrade screen" : "Opens the glyph grid")
    }

    private var tint: Color {
        switch set {
        case .uppercase: return Theme.accent
        case .lowercase: return Theme.sky
        case .numbers: return Theme.grass
        case .shapes: return Theme.berry
        }
    }
}

/// A simple rounded progress bar.
struct ProgressBar: View {
    let value: Double // 0...1

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.hairline)
                Capsule().fill(Theme.accent)
                    .frame(width: max(0, min(1, value)) * geo.size.width)
            }
        }
        .accessibilityHidden(true)
    }
}
