import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Profile.createdAt, order: .reverse) private var profiles: [Profile]
    @AppStorage("userName") private var userName = "You"
    @AppStorage("isPro") private var isPro = false
    @EnvironmentObject private var settings: AppSettings

    @State private var showTest = false
    @State private var showSettings = false
    @State private var paywallReason: PaywallReason?

    private var primary: Profile? {
        profiles.first { $0.isPrimary } ?? profiles.first { !$0.name.hasSuffix("(sample)") }
    }

    /// Sample/seed profiles shown lower on Home.
    private var others: [Profile] {
        profiles.filter { $0.id != primary?.id }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let primary {
                        primaryCard(primary)
                        retakeRow
                    } else {
                        emptyHero
                    }

                    if !others.isEmpty {
                        savedSection
                    }
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Facet")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showTest) {
                TestRunnerView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(item: $paywallReason) { reason in
                PaywallView(reason: reason)
            }
        }
    }

    // MARK: - Primary result card

    private func primaryCard(_ profile: Profile) -> some View {
        let result = profile.scoredResult
        let archetype = result.archetype
        let identity = TypeMapper.identity(for: result.traitScores)

        return NavigationLink {
            ResultDetailView(profile: profile)
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile.name)
                            .font(Theme.rounded(15, .semibold))
                            .foregroundStyle(.white.opacity(0.85))
                        Text(archetype.name)
                            .font(Theme.rounded(26, .bold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.white.opacity(0.7))
                        .accessibilityHidden(true)
                }
                TypeBadge(code: result.typeCode,
                          identity: settings.emphasizeTurbulent ? identity : nil,
                          size: 40)
                Text(archetype.tagline)
                    .font(Theme.rounded(15))
                    .foregroundStyle(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)

                Divider().overlay(Color.white.opacity(0.25))

                MiniBarsLight(result: result)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Theme.heroGradient)
            )
            .shadow(color: Theme.accent.opacity(0.3), radius: 18, y: 8)
        }
        .buttonStyle(PressableScale())
        .accessibilityHint("Opens your full result")
    }

    private var retakeRow: some View {
        SecondaryButton(title: TestViewModel.hasStoredDraft() ? "Resume your test" : "Retake the test",
                        systemImage: "arrow.clockwise") {
            showTest = true
        }
    }

    // MARK: - Empty hero (no primary profile yet)

    private var emptyHero: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle().fill(Theme.heroGradient)
                    .frame(width: 110, height: 110)
                    .shadow(color: Theme.accent.opacity(0.35), radius: 20, y: 8)
                Image(systemName: "circle.hexagongrid.fill")
                    .font(.system(size: 46, weight: .light))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
            }
            .padding(.top, 12)

            Text("Hi \(userName.isEmpty ? "there" : userName) — discover your facets")
                .font(Theme.rounded(24, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text("Take a short, research-grounded questionnaire to see your Big Five profile and your archetype. About 5 minutes.")
                .font(Theme.rounded(16))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            PrimaryButton(title: TestViewModel.hasStoredDraft() ? "Resume your test" : "Take the test",
                          systemImage: "play.fill") {
                showTest = true
            }
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .cardSurface()
    }

    // MARK: - Saved profiles

    private var savedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Saved profiles", systemImage: "person.2.fill")
            ForEach(others) { profile in
                NavigationLink {
                    ResultDetailView(profile: profile)
                } label: {
                    ProfileRow(profile: profile, showPercentage: settings.showTraitPercentages)
                }
                .buttonStyle(PressableScale())
            }
        }
    }
}

/// White-on-gradient mini bars used inside the primary card.
private struct MiniBarsLight: View {
    let result: ScoredResult
    var body: some View {
        VStack(spacing: 7) {
            ForEach(result.traitScores) { ts in
                HStack(spacing: 8) {
                    Text(ts.trait.shortLabel)
                        .font(Theme.mono(12, .bold))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 14)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.2))
                            Capsule().fill(Color.white)
                                .frame(width: max(4, geo.size.width * (max(0, min(100, ts.score)) / 100)))
                        }
                    }
                    .frame(height: 7)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(ts.trait.rawValue)
                .accessibilityValue("\(Int(ts.score)) percent")
            }
        }
    }
}

/// A compact row for a saved profile.
struct ProfileRow: View {
    let profile: Profile
    var showPercentage: Bool = true

    var body: some View {
        let result = profile.scoredResult
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(result.archetype.color.opacity(0.18))
                    .frame(width: 50, height: 50)
                Text(result.typeCode.prefix(2))
                    .font(Theme.mono(15, .bold))
                    .foregroundStyle(result.archetype.color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                Text("\(result.typeCode) · \(result.archetype.name)")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            if profile.isPrimary {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.accent)
                    .accessibilityLabel("Primary profile")
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.inkFaint)
                .accessibilityHidden(true)
        }
        .padding(14)
        .cardSurface()
        .accessibilityElement(children: .combine)
    }
}
