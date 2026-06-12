import SwiftUI
import SwiftData

struct SwipeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var decisions: [Decision]

    @AppStorage("partnerAName") private var partnerAName = "Partner A"
    @AppStorage("partnerBName") private var partnerBName = "Partner B"
    @AppStorage("currentPartner") private var currentPartnerRaw = Partner.a.rawValue
    @AppStorage("genderFilter") private var genderFilterRaw = "all"
    @AppStorage("showMeanings") private var showMeanings = true
    @AppStorage("deckSeed") private var deckSeed = 0

    @State private var dragOffset: CGSize = .zero
    @State private var showingHandoff = false
    @State private var matchedName: NameEntry?

    private var currentPartner: Partner { Partner(rawValue: currentPartnerRaw) ?? .a }
    private var partnerName: String { currentPartner == .a ? partnerAName : partnerBName }
    private var otherName: String { currentPartner == .a ? partnerBName : partnerAName }

    private var genderFilter: NameGender? { NameGender(rawValue: genderFilterRaw) }

    private var deck: [NameEntry] {
        MatchEngine.deck(
            gender: genderFilter,
            styles: [],
            excluding: MatchEngine.decidedIDs(for: currentPartner, in: decisions),
            seed: UInt64(bitPattern: Int64(deckSeed == 0 ? 20260612 : deckSeed))
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                header
                cardStack
                controls
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Moniker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("Names for", selection: $genderFilterRaw) {
                        Text("All names").tag("all")
                        ForEach(NameGender.allCases) { g in
                            Text("\(g.displayName) names").tag(g.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .fullScreenCover(isPresented: $showingHandoff) {
                HandoffView(toName: otherName) {
                    currentPartnerRaw = (currentPartner == .a ? Partner.b : Partner.a).rawValue
                    showingHandoff = false
                }
            }
            .overlay {
                if let matched = matchedName {
                    matchOverlay(matched)
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Swiping as")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(partnerName)
                    .font(.headline)
                    .foregroundStyle(MonikerTheme.roseDeep)
            }
            Spacer()
            Button {
                Haptics.tap()
                showingHandoff = true
            } label: {
                Label("Hand to \(otherName)", systemImage: "arrow.left.arrow.right")
                    .font(.subheadline.weight(.medium))
            }
            .buttonStyle(.bordered)
            .accessibilityHint("Switches swiping to the other partner")
        }
    }

    // MARK: - Cards

    @ViewBuilder
    private var cardStack: some View {
        ZStack {
            if deck.isEmpty {
                emptyDeck
            } else {
                if deck.count > 1 {
                    NameCard(entry: deck[1], showMeaning: showMeanings)
                        .scaleEffect(0.94)
                        .offset(y: 14)
                        .opacity(0.6)
                        .accessibilityHidden(true)
                }
                NameCard(entry: deck[0], showMeaning: showMeanings)
                    .offset(dragOffset)
                    .rotationEffect(.degrees(Double(dragOffset.width / 18)))
                    .overlay(alignment: .topLeading) {
                        stamp("LOVE", color: .green)
                            .opacity(dragOffset.width > 40 ? min(1, Double(dragOffset.width - 40) / 60) : 0)
                            .rotationEffect(.degrees(-12))
                            .padding(22)
                    }
                    .overlay(alignment: .topTrailing) {
                        stamp("PASS", color: .red)
                            .opacity(dragOffset.width < -40 ? min(1, Double(-dragOffset.width - 40) / 60) : 0)
                            .rotationEffect(.degrees(12))
                            .padding(22)
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation
                            }
                            .onEnded { value in
                                if value.translation.width > 100 {
                                    decide(deck[0], liked: true)
                                } else if value.translation.width < -100 {
                                    decide(deck[0], liked: false)
                                } else {
                                    withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.7)) {
                                        dragOffset = .zero
                                    }
                                }
                            }
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(cardAccessibilityLabel(deck[0]))
                    .accessibilityHint("Use the Love and Pass buttons below to decide")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(reduceMotion ? nil : .snappy(duration: 0.25), value: deck.first?.id)
    }

    private func cardAccessibilityLabel(_ entry: NameEntry) -> String {
        "\(entry.name), \(entry.gender.displayName) name, \(entry.origin) origin, meaning: \(entry.meaning)"
    }

    private func stamp(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.title2.weight(.heavy))
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(color, lineWidth: 3))
    }

    private var emptyDeck: some View {
        ContentUnavailableView {
            Label("Deck Complete", systemImage: "checkmark.seal.fill")
        } description: {
            Text("\(partnerName) has seen every name in this filter. Hand the phone to \(otherName), broaden the filter above, or browse the full catalog.")
        } actions: {
            Button("Hand to \(otherName)") {
                Haptics.tap()
                showingHandoff = true
            }
            .buttonStyle(.borderedProminent)
            .tint(MonikerTheme.roseDeep)
        }
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: 22) {
            Button {
                if let top = deck.first { decide(top, liked: false) }
            } label: {
                Image(systemName: "xmark")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.red)
                    .frame(width: 64, height: 64)
                    .background(Circle().fill(Color(.secondarySystemGroupedBackground)))
                    .overlay(Circle().strokeBorder(Color.red.opacity(0.3), lineWidth: 1.5))
            }
            .disabled(deck.isEmpty)
            .accessibilityLabel("Pass on \(deck.first?.name ?? "this name")")

            Button {
                undoLast()
            } label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .frame(width: 46, height: 46)
                    .background(Circle().fill(Color(.secondarySystemGroupedBackground)))
            }
            .disabled(MatchEngine.decisions(for: currentPartner, in: decisions).isEmpty)
            .accessibilityLabel("Undo last decision")

            Button {
                if let top = deck.first { decide(top, liked: true) }
            } label: {
                Image(systemName: "heart.fill")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(MonikerTheme.roseDeep)
                    .frame(width: 64, height: 64)
                    .background(Circle().fill(Color(.secondarySystemGroupedBackground)))
                    .overlay(Circle().strokeBorder(MonikerTheme.rose.opacity(0.5), lineWidth: 1.5))
            }
            .disabled(deck.isEmpty)
            .accessibilityLabel("Love \(deck.first?.name ?? "this name")")
        }
        .padding(.bottom, 6)
    }

    // MARK: - Actions

    private func decide(_ entry: NameEntry, liked: Bool) {
        if liked { Haptics.like() } else { Haptics.tap() }
        withAnimation(reduceMotion ? nil : .easeIn(duration: 0.18)) {
            dragOffset = CGSize(width: liked ? 600 : -600, height: -40)
        }
        let partner = currentPartner
        // Replace any prior decision for this name+partner.
        for old in decisions where old.nameID == entry.id && old.partnerRaw == partner.rawValue {
            modelContext.delete(old)
        }
        modelContext.insert(Decision(nameID: entry.id, partner: partner, liked: liked))

        if liked {
            let other: Partner = partner == .a ? .b : .a
            if MatchEngine.likedIDs(for: other, in: decisions).contains(entry.id) {
                Haptics.match()
                matchedName = entry
            }
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 200_000_000)
            dragOffset = .zero
        }
    }

    private func undoLast() {
        Haptics.tap()
        let mine = MatchEngine.decisions(for: currentPartner, in: decisions)
            .sorted { $0.date > $1.date }
        if let last = mine.first {
            modelContext.delete(last)
        }
    }

    // MARK: - Match overlay

    private func matchOverlay(_ entry: NameEntry) -> some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 14) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 58))
                    .foregroundStyle(MonikerTheme.roseDeep)
                Text("It's a Match!")
                    .font(.largeTitle.weight(.bold))
                    .fontDesign(.rounded)
                Text("You both love the name")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Text(entry.name)
                    .font(.system(size: 42, weight: .semibold, design: .serif))
                    .foregroundStyle(MonikerTheme.genderColor(entry.gender))
                Button {
                    Haptics.tap()
                    matchedName = nil
                } label: {
                    Text("Keep Swiping")
                        .font(.headline)
                        .frame(maxWidth: 220)
                }
                .buttonStyle(.borderedProminent)
                .tint(MonikerTheme.roseDeep)
            }
            .padding(30)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(36)
            .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("It's a match! You both love the name \(entry.name).")
    }
}

// MARK: - Card

struct NameCard: View {
    let entry: NameEntry
    let showMeaning: Bool

    var body: some View {
        VStack(spacing: 14) {
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: entry.gender.symbol)
                    .font(.caption2)
                Text(entry.gender.displayName.uppercased())
                    .font(.caption.weight(.semibold))
                    .tracking(1.5)
            }
            .foregroundStyle(MonikerTheme.genderColor(entry.gender))

            Text(entry.name)
                .font(.system(size: 48, weight: .semibold, design: .serif))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .padding(.horizontal, 18)

            if showMeaning {
                VStack(spacing: 5) {
                    Text(entry.origin.uppercased())
                        .font(.caption2.weight(.semibold))
                        .tracking(1.2)
                        .foregroundStyle(.secondary)
                    Text("“\(entry.meaning)”")
                        .font(.body)
                        .fontDesign(.serif)
                        .italic()
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary.opacity(0.8))
                        .padding(.horizontal, 24)
                }
            }

            HStack(spacing: 6) {
                ForEach(entry.styles.prefix(3)) { style in
                    StyleChip(style: style)
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(MonikerTheme.genderColor(entry.gender).opacity(0.25), lineWidth: 1.5)
        )
    }
}

// MARK: - Handoff

struct HandoffView: View {
    let toName: String
    var onReady: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [MonikerTheme.roseDeep, MonikerTheme.rose.opacity(0.7)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
            VStack(spacing: 22) {
                Spacer()
                Image(systemName: "hand.point.right.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
                Text("Pass the phone to")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.85))
                Text(toName)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Their swipes stay secret until you match — no peeking at each other's lists.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 36)
                Spacer()
                Button {
                    Haptics.tap()
                    onReady()
                } label: {
                    Text("I'm \(toName) — Start Swiping")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(MonikerTheme.roseDeep)
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
            }
        }
    }
}
