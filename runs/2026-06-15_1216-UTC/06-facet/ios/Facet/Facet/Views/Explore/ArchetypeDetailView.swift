import SwiftUI

struct ArchetypeDetailView: View {
    let archetype: Archetype
    @AppStorage("isPro") private var isPro = false
    @State private var paywallReason: PaywallReason?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hero
                Text(archetype.description)
                    .font(Theme.rounded(16))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(18)
                    .cardSurface()

                if isPro {
                    list("Strengths", "bolt.fill", archetype.strengths, Theme.good)
                    list("Growth areas", "leaf.fill", archetype.growthAreas, Theme.warn)
                    list("Careers that fit", "briefcase.fill", archetype.careers, Theme.accent)
                    relationship
                } else {
                    lockedTeaser
                }
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(archetype.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $paywallReason) { PaywallView(reason: $0) }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(archetype.code)
                .font(Theme.mono(18, .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12).padding(.vertical, 5)
                .background(Capsule().fill(Color.white.opacity(0.22)))
            Text(archetype.name)
                .font(Theme.rounded(30, .bold)).foregroundStyle(.white)
            Text(archetype.tagline)
                .font(Theme.rounded(16)).foregroundStyle(.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LinearGradient(colors: [archetype.color.opacity(0.95), Theme.accent],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
        )
    }

    private func list(_ title: String, _ symbol: String, _ items: [String], _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: title, systemImage: symbol)
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 10) {
                    Circle().fill(color).frame(width: 7, height: 7).padding(.top, 7)
                        .accessibilityHidden(true)
                    Text(item).font(Theme.rounded(15)).foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
            }
        }
        .padding(18)
        .cardSurface()
    }

    private var relationship: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "In relationships", systemImage: "heart.fill")
            Text(archetype.relationshipNotes)
                .font(Theme.rounded(15)).foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .cardSurface()
    }

    private var lockedTeaser: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SectionHeader(title: "Full profile")
                ProLockChip()
            }
            Text("Unlock the complete profile for every archetype — strengths, growth areas, careers, and relationship style.")
                .font(Theme.rounded(15)).foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(title: "Unlock with Pro", systemImage: "lock.open.fill") {
                paywallReason = .archetypeLibrary
            }
        }
        .padding(18)
        .cardSurface()
    }
}
