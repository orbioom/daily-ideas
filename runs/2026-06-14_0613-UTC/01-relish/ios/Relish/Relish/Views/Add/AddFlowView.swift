import SwiftUI
import SwiftData

/// Stages of the add flow.
private enum AddStage: Equatable {
    case details
    case comparing
    case reveal
}

/// The full add-and-compare flow presented as a sheet.
/// If `existing` is provided, it's a re-rank of an already-saved restaurant.
struct AddFlowView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("isPro") private var isPro = false

    /// All current restaurants (for ranking + limit checks). Passed in to avoid nested @Query timing.
    let allRestaurants: [Restaurant]
    /// When set, we re-rank this existing place instead of creating a new one.
    var existing: Restaurant? = nil
    /// When set, prefill from a wishlist place being marked visited.
    var wishlistSource: Restaurant? = nil

    @State private var stage: AddStage = .details

    // Form fields
    @State private var name = ""
    @State private var cuisine: Cuisine = .italian
    @State private var city = ""
    @State private var priceTier = 2
    @State private var isVisited = true
    @State private var sentiment: Sentiment = .loved
    @State private var notes = ""
    @State private var validationMessage: String?

    // Comparison engine state
    @State private var session: ComparisonSession?
    @State private var currentStep: ComparisonStep?
    @State private var stepNumber = 1
    @State private var workingNewcomer: Restaurant?
    @State private var revealedScore: Double = 0
    @State private var revealedRank: Int = 0
    @State private var paywallReason: PaywallReason?

    private var rankedCount: Int {
        allRestaurants.filter { !$0.isWishlist }.count
    }

    var body: some View {
        NavigationStack {
            Group {
                switch stage {
                case .details: detailsStep
                case .comparing: comparingStep
                case .reveal: revealStep
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(navTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(stage == .reveal ? "Done" : "Cancel") { dismiss() }
                }
            }
        }
        .sheet(item: $paywallReason) { reason in
            PaywallView(reason: reason)
        }
        .onAppear(perform: prefill)
    }

    private var navTitle: String {
        switch stage {
        case .details: return existing == nil ? "Add a Place" : "Re-rank"
        case .comparing: return "Which was better?"
        case .reveal: return "Ranked!"
        }
    }

    // MARK: Prefill (re-rank or wishlist→visited)

    private func prefill() {
        if let existing {
            name = existing.name
            cuisine = existing.cuisine
            city = existing.city
            priceTier = existing.priceTier
            notes = existing.notes
            isVisited = true
            sentiment = existing.sentiment ?? .loved
        } else if let src = wishlistSource {
            name = src.name
            cuisine = src.cuisine
            city = src.city
            priceTier = src.priceTier
            notes = src.notes
            isVisited = true
        }
    }

    // MARK: Step 1 — details

    private var detailsStep: some View {
        Form {
            Section {
                TextField("Restaurant name", text: $name)
                    .font(Theme.rounded(17))
                Picker("Cuisine", selection: $cuisine) {
                    ForEach(Cuisine.allCases) { c in
                        Label(c.rawValue, systemImage: c.symbol).tag(c)
                    }
                }
                TextField("City", text: $city)
                Picker("Price", selection: $priceTier) {
                    ForEach(1...4, id: \.self) { p in
                        Text(String(repeating: "$", count: p)).tag(p)
                    }
                }
            } header: {
                Text("Details")
            }

            if existing == nil {
                Section {
                    Picker("Status", selection: $isVisited) {
                        Text("Been there").tag(true)
                        Text("Want to try").tag(false)
                    }
                    .pickerStyle(.segmented)
                } footer: {
                    Text(isVisited
                         ? "We'll rank it against your other visits."
                         : "Saved to your Want to Try list — no ranking yet.")
                }
            }

            if isVisited {
                Section {
                    ForEach(Sentiment.allCases) { s in
                        Button {
                            sentiment = s
                            Haptics.tap(settings.hapticsEnabled)
                        } label: {
                            HStack {
                                Image(systemName: s.symbol)
                                    .foregroundStyle(s.color)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(s.rawValue)
                                        .font(Theme.rounded(16, .semibold))
                                        .foregroundStyle(Theme.ink)
                                    Text(s.blurb)
                                        .font(Theme.rounded(12))
                                        .foregroundStyle(Theme.inkSoft)
                                }
                                Spacer()
                                if sentiment == s {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Theme.accent)
                                }
                            }
                        }
                        .accessibilityAddTraits(sentiment == s ? .isSelected : [])
                    }
                } header: {
                    Text("How was it?")
                }
            }

            Section {
                TextField("Notes (optional)", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
            }

            if let validationMessage {
                Section {
                    Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.bad)
                }
            }

            Section {
                Button(action: proceed) {
                    Text(continueLabel)
                        .font(Theme.rounded(17, .semibold))
                        .frame(maxWidth: .infinity)
                }
                .listRowBackground(Theme.accent)
                .foregroundStyle(.white)
            }
        }
        .scrollContentBackground(.hidden)
    }

    private var continueLabel: String {
        if !isVisited { return "Save to Want to Try" }
        if rankedCount == 0 { return "Add as #1" }
        return "Start comparing"
    }

    private func proceed() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            validationMessage = "Please give the place a name."
            Haptics.error(settings.hapticsEnabled)
            return
        }
        validationMessage = nil

        if !isVisited {
            saveWishlist(named: trimmed)
            return
        }

        // Pro gate: only when adding a NET-NEW ranked place beyond the free limit.
        let isNetNew = (existing == nil)
        if isNetNew && !Pro.canAddRanked(currentRankedCount: rankedCount, isPro: isPro) {
            paywallReason = .rankLimit
            Haptics.warning(settings.hapticsEnabled)
            return
        }

        beginRanking(named: trimmed)
    }

    private func saveWishlist(named trimmed: String) {
        let r = Restaurant(name: trimmed, cuisine: cuisine, city: city,
                           priceTier: priceTier, sentiment: nil,
                           notes: notes, isWishlist: true)
        context.insert(r)
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }

    private func beginRanking(named trimmed: String) {
        // Prepare the newcomer (existing re-rank pulls the place out of ordering first).
        let ranked = allRestaurants.filter { !$0.isWishlist && $0.sentiment != nil }

        let newcomer: Restaurant
        if let existing {
            existing.name = trimmed
            existing.cuisine = cuisine
            existing.city = city
            existing.priceTier = priceTier
            existing.notes = notes
            existing.sentiment = sentiment
            existing.isWishlist = false
            newcomer = existing
        } else if let src = wishlistSource {
            src.name = trimmed
            src.cuisine = cuisine
            src.city = city
            src.priceTier = priceTier
            src.notes = notes
            src.sentiment = sentiment
            src.isWishlist = false
            newcomer = src
        } else {
            let r = Restaurant(name: trimmed, cuisine: cuisine, city: city,
                               priceTier: priceTier, sentiment: sentiment,
                               notes: notes, isWishlist: false)
            context.insert(r)
            newcomer = r
        }
        workingNewcomer = newcomer

        // Candidates exclude the newcomer itself.
        let pool = ranked.filter { $0.id != newcomer.id }
        let newSession = RankingEngine.makeSession(in: pool, sentiment: sentiment)
        stepNumber = 1

        if newSession.isComplete {
            finalizeInsertion(session: newSession, newcomer: newcomer, pool: pool)
        } else {
            session = newSession
            currentStep = newSession.nextStep(currentStepNumber: 1)
            withAnimation(reduceMotion ? nil : .easeInOut) { stage = .comparing }
        }
    }

    // MARK: Step 2 — comparison cards

    @ViewBuilder
    private var comparingStep: some View {
        if let step = currentStep,
           let newcomer = workingNewcomer,
           let existingRestaurant = restaurant(for: step.existingID) {
            VStack(spacing: 18) {
                ProgressView(value: Double(step.stepNumber),
                             total: Double(max(step.estimatedTotal, step.stepNumber)))
                    .tint(Theme.accent)
                    .padding(.horizontal)

                Text("Comparison \(step.stepNumber) of ~\(max(step.estimatedTotal, step.stepNumber))")
                    .font(Theme.rounded(13, .medium))
                    .foregroundStyle(Theme.inkSoft)

                Text("Which did you like better?")
                    .font(Theme.serif(22, .semibold))
                    .foregroundStyle(Theme.ink)

                HStack(spacing: 14) {
                    comparisonCard(for: newcomer, label: "New", action: { choose(.preferredNew) })
                    comparisonCard(for: existingRestaurant, label: "Ranked", action: { choose(.preferredExisting) })
                }
                .padding(.horizontal)

                Button {
                    choose(.preferredExisting)
                } label: {
                    Text("Too close to call — keep them in current order")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                }
                .padding(.top, 4)

                Spacer()
            }
            .padding(.top, 16)
        } else {
            EmptyStateView(symbol: "exclamationmark.triangle",
                           title: "Something went sideways",
                           message: "We couldn't load the next comparison. Your place was saved at the bottom of its tier.",
                           actionTitle: "Continue") { dismiss() }
        }
    }

    private func comparisonCard(for r: Restaurant, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Text(label.uppercased())
                    .font(Theme.rounded(11, .bold))
                    .foregroundStyle(label == "New" ? Theme.accent : Theme.inkFaint)
                CuisineBadge(cuisine: r.cuisine, size: 54)
                Text(r.name)
                    .font(Theme.rounded(17, .bold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                VStack(spacing: 2) {
                    Text(r.cuisine.rawValue)
                    Text("\(r.priceLabel) · \(r.city)")
                }
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(Theme.hairline, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Choose \(r.name), the \(label.lowercased()) place")
        .accessibilityHint("Marks it as the one you liked better")
    }

    private func choose(_ choice: ComparisonChoice) {
        guard var s = session, let newcomer = workingNewcomer else { return }
        Haptics.tap(settings.hapticsEnabled)
        s.apply(choice)
        stepNumber += 1

        if s.isComplete {
            let pool = allRestaurants.filter { !$0.isWishlist && $0.sentiment != nil && $0.id != newcomer.id }
            finalizeInsertion(session: s, newcomer: newcomer, pool: pool)
        } else {
            session = s
            currentStep = s.nextStep(currentStepNumber: stepNumber)
        }
    }

    private func finalizeInsertion(session: ComparisonSession, newcomer: Restaurant, pool: [Restaurant]) {
        let offset = session.insertionOffset
        let ordered = RankingEngine.insertedOrder(ranked: pool,
                                                  newcomer: newcomer,
                                                  sentiment: sentiment,
                                                  tierOffset: offset)
        RankingEngine.reindex(ordered)
        try? context.save()

        revealedScore = RankingEngine.score(for: newcomer, in: ordered)
        revealedRank = newcomer.rankIndex + 1
        Haptics.success(settings.hapticsEnabled)
        withAnimation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.7)) {
            stage = .reveal
        }
    }

    // MARK: Step 3 — reveal

    @State private var revealScale: CGFloat = 0.6

    private var revealStep: some View {
        VStack(spacing: 22) {
            Spacer()
            Text(name)
                .font(Theme.serif(28, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            ScoreChip(score: revealedScore, sentiment: sentiment, size: 150)
                .scaleEffect(reduceMotion ? 1 : revealScale)

            VStack(spacing: 6) {
                Text("Ranked #\(revealedRank) overall")
                    .font(Theme.rounded(18, .semibold))
                    .foregroundStyle(Theme.ink)
                Text("\(sentiment.rawValue) · \(cuisine.rawValue)")
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
            }

            Spacer()

            PrimaryButton(title: "Done", systemImage: "checkmark") { dismiss() }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
        .onAppear {
            guard !reduceMotion else { revealScale = 1; return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { revealScale = 1 }
        }
    }

    // MARK: Lookup helpers

    private func restaurant(for id: UUID) -> Restaurant? {
        allRestaurants.first { $0.id == id }
    }
}
