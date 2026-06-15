import SwiftUI
import SwiftData

struct JourneysView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings

    @Query private var companions: [Companion]
    @Query(sort: \Journey.sortOrder) private var journeys: [Journey]
    @Query(sort: \Postcard.earnedAt, order: .reverse) private var postcards: [Postcard]

    @State private var showPaywall = false
    @State private var paywallReason: PaywallReason = .proJourney
    @State private var errorMessage: String?
    @State private var detailJourney: Journey?

    private var companion: Companion? { companions.first }
    private var active: Journey? { journeys.first { $0.isActive && !$0.isCompleted } }
    private var available: [Journey] { journeys.filter { !$0.isActive && !$0.isCompleted } }

    private var currentEnergy: Int {
        guard let c = companion else { return 0 }
        return CareEngine.decayedEnergy(current: c.energy, lastTendedAt: c.lastTendedAt)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        energyHeader
                        activeSection
                        availableSection
                        collectionSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Journeys")
            .sheet(isPresented: $showPaywall) { PaywallView(reason: paywallReason) }
            .sheet(item: $detailJourney) { journey in
                JourneyDetailView(journey: journey, currentEnergy: currentEnergy) {
                    start(journey)
                }
            }
            .alert("Couldn't start", isPresented: Binding(
                get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
        }
    }

    private var energyHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "bolt.fill").foregroundStyle(Theme.good)
            Text("Energy: \(currentEnergy)/100")
                .font(Theme.rounded(14, .semibold))
                .foregroundStyle(Theme.ink)
            Spacer()
            Text("Starting a journey spends energy")
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(12)
        .card(Theme.surfaceAlt)
        .accessibilityElement(children: .combine)
    }

    // MARK: Active

    @ViewBuilder
    private var activeSection: some View {
        SectionHeader("On a journey")
        if let active {
            ActiveJourneyCard(journey: active, onCancel: { cancel(active) })
        } else {
            HStack(spacing: 12) {
                Image(systemName: "map")
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.inkFaint)
                Text("No active journey. Pick one below — each completed goal carries your Wren a little further.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .card(Theme.surface)
        }
    }

    // MARK: Available

    @ViewBuilder
    private var availableSection: some View {
        SectionHeader("Set off on", subtitle: active == nil ? "One journey at a time." : "Finish your current journey first.")
        ForEach(available) { journey in
            JourneyRow(
                journey: journey,
                currentEnergy: currentEnergy,
                isPro: settings.isPro,
                disabledByActive: active != nil
            ) {
                tapJourney(journey)
            }
        }
        if available.isEmpty {
            EmptyStateView(systemImage: "map.fill",
                           title: "Every journey explored",
                           message: "You've started or finished all available journeys. New paths arrive with future updates.")
            .card(Theme.surface)
        }
    }

    // MARK: Collection

    @ViewBuilder
    private var collectionSection: some View {
        SectionHeader("Collection", subtitle: "Postcards and keepsakes from your journeys.")
        if postcards.isEmpty {
            EmptyStateView(systemImage: "photo.on.rectangle.angled",
                           title: "Your gallery is empty",
                           message: "Finish a journey to earn your first postcard.")
            .card(Theme.surface)
        } else {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(postcards) { postcard in
                    PostcardCell(postcard: postcard)
                }
            }
        }
    }

    // MARK: Actions

    private func tapJourney(_ journey: Journey) {
        if journey.isPro && !settings.isPro {
            paywallReason = journey.rewardKind == .cosmetic ? .proCosmetic : .proJourney
            settings.haptic(.warning)
            showPaywall = true
            return
        }
        detailJourney = journey
    }

    private func start(_ journey: Journey) {
        guard let companion else { return }
        do {
            try CareStore(context: modelContext).startJourney(journey, companion: companion)
            settings.haptic(.success)
            detailJourney = nil
        } catch let e as CareStore.StoreError {
            errorMessage = e.errorDescription
            settings.haptic(.warning)
        } catch {
            errorMessage = "Couldn't start the journey."
        }
    }

    private func cancel(_ journey: Journey) {
        do {
            try CareStore(context: modelContext).cancelJourney(journey)
            settings.haptic(.soft)
        } catch {
            errorMessage = "Couldn't cancel the journey."
        }
    }
}

// MARK: - Active card

private struct ActiveJourneyCard: View {
    let journey: Journey
    let onCancel: () -> Void
    @State private var confirmCancel = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(journey.title, systemImage: "figure.walk.motion")
                    .font(Theme.rounded(18, .bold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Button {
                    confirmCancel = true
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.inkFaint)
                }
                .accessibilityLabel("Cancel journey")
            }
            Text(journey.detail)
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)

            ProgressView(value: journey.fractionComplete)
                .tint(Theme.accent)
            HStack {
                Text("\(journey.progressCount) of \(journey.requiredCompletions) acts of care")
                    .font(Theme.rounded(13, .medium))
                    .foregroundStyle(Theme.inkSoft)
                Spacer()
                Label(journey.rewardName, systemImage: journey.rewardKind.systemImage)
                    .font(Theme.rounded(12, .semibold))
                    .foregroundStyle(Theme.accent)
            }
        }
        .padding(16)
        .card(Theme.surface)
        .alert("Cancel this journey?", isPresented: $confirmCancel) {
            Button("Cancel journey", role: .destructive, action: onCancel)
            Button("Keep going", role: .cancel) {}
        } message: {
            Text("Progress will reset, but the energy you spent stays spent.")
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Available row

private struct JourneyRow: View {
    let journey: Journey
    let currentEnergy: Int
    let isPro: Bool
    let disabledByActive: Bool
    let onTap: () -> Void

    private var locked: Bool { journey.isPro && !isPro }
    private var notEnoughEnergy: Bool { currentEnergy < journey.energyCost }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(journey.title)
                            .font(Theme.rounded(16, .semibold))
                            .foregroundStyle(Theme.ink)
                        if journey.isPro {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.warn)
                        }
                    }
                    Text(journey.detail)
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                        .lineLimit(2)
                    HStack(spacing: 12) {
                        Label("\(journey.energyCost) energy", systemImage: "bolt.fill")
                            .foregroundStyle(notEnoughEnergy ? Theme.bad : Theme.good)
                        Label("\(journey.requiredCompletions) acts", systemImage: "checkmark.seal")
                            .foregroundStyle(Theme.inkSoft)
                        Label(journey.rewardName, systemImage: journey.rewardKind.systemImage)
                            .foregroundStyle(Theme.accent)
                    }
                    .font(Theme.rounded(11, .semibold))
                }
                Spacer()
                Image(systemName: locked ? "lock.fill" : "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(locked ? Theme.warn : Theme.inkFaint)
            }
            .padding(14)
            .opacity(disabledByActive ? 0.5 : 1)
            .card(Theme.surface)
        }
        .buttonStyle(.plain)
        .disabled(disabledByActive)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(journey.title + (journey.isPro ? ", Pro" : ""))
        .accessibilityValue("Costs \(journey.energyCost) energy, \(journey.requiredCompletions) acts of care, reward \(journey.rewardName)")
        .accessibilityHint(disabledByActive ? "Finish your active journey first" : "Double-tap for details")
    }
}

// MARK: - Postcard cell

private struct PostcardCell: View {
    let postcard: Postcard
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SceneArtView(scene: postcard.scene)
                .frame(height: 100)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(postcard.title)
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text(DateUtils.fullFormatter.string(from: postcard.earnedAt))
                    .font(Theme.rounded(11))
                    .foregroundStyle(Theme.inkSoft)
            }
            .padding(10)
        }
        .card(Theme.surface)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Postcard: \(postcard.title), earned \(DateUtils.fullFormatter.string(from: postcard.earnedAt))")
    }
}
