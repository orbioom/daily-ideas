import SwiftUI

struct ExploreView: View {
    @AppStorage("isPro") private var isPro = false
    @State private var showSettings = false
    @State private var paywallReason: PaywallReason?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    traitsSection
                    archetypesSection
                    methodologySection
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Explore")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                        .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        }
    }

    private var traitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "The Big Five", systemImage: "chart.bar.doc.horizontal.fill")
            Text("Five broad dimensions psychologists use to describe personality.")
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
            ForEach(Trait.allCases) { trait in
                NavigationLink {
                    TraitDetailView(trait: trait)
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Theme.accentSoft).frame(width: 46, height: 46)
                            Image(systemName: trait.symbolName).foregroundStyle(Theme.accent)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(trait.rawValue).font(Theme.rounded(16, .semibold)).foregroundStyle(Theme.ink)
                            Text("\(trait.lowPole) ↔ \(trait.highPole)")
                                .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.inkFaint).accessibilityHidden(true)
                    }
                    .padding(14)
                    .cardSurface()
                    .accessibilityElement(children: .combine)
                }
                .buttonStyle(PressableScale())
            }
        }
    }

    private var archetypesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "16 Archetypes", systemImage: "square.grid.2x2.fill")
                if !isPro { ProLockChip() }
            }
            Text("Friendly summaries that combine your five traits into a familiar four-letter type.")
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(Archetype.catalog) { archetype in
                    archetypeTile(archetype)
                }
            }
        }
    }

    private func archetypeTile(_ archetype: Archetype) -> some View {
        NavigationLink {
            ArchetypeDetailView(archetype: archetype)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(archetype.code)
                        .font(Theme.mono(14, .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(archetype.color))
                    Spacer()
                    if !isPro {
                        Image(systemName: "lock.fill").font(.system(size: 10))
                            .foregroundStyle(Theme.inkFaint)
                    }
                }
                Text(archetype.name)
                    .font(Theme.rounded(16, .bold)).foregroundStyle(Theme.ink)
                Text(archetype.tagline)
                    .font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
                    .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
            .padding(14)
            .cardSurface()
            .accessibilityElement(children: .combine)
            .accessibilityHint(isPro ? "Opens full archetype detail" : "Opens preview; full detail is a Pro feature")
        }
        .buttonStyle(PressableScale())
    }

    private var methodologySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "About & methodology", systemImage: "info.circle.fill")
            VStack(alignment: .leading, spacing: 10) {
                methodologyLine("Research-based traits", "Facet measures the Big Five (OCEAN) using public-domain items from the International Personality Item Pool (IPIP). Each trait is measured by 8 items on a 1–5 scale.")
                methodologyLine("Transparent scoring", "Reverse-keyed items are recoded, summed per trait, and normalized to 0–100, where 50 is the neutral midpoint. The result is fully deterministic — same answers, same scores.")
                methodologyLine("Type is a friendly summary", "The four-letter type and named archetype are a friendly way to talk about your trait pattern — not a clinical diagnosis. People are continuous blends, not boxes.")
                methodologyLine("Private by design", "Everything is computed and stored on your device. No account, no network, no tracking.")
            }
            .padding(18)
            .cardSurface()
        }
    }

    private func methodologyLine(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.ink)
            Text(body).font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
