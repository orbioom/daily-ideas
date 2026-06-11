import SwiftUI
import SwiftData

/// The core experience: a pass-the-phone or take-turns swipe deck.
struct SwipeView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("activePartner") private var activePartnerRaw = Partner.a.rawValue
    @AppStorage("genderFilter") private var genderFilterRaw = ""
    @AppStorage("styleFilter") private var styleFilterRaw = ""
    @Query private var verdicts: [Verdict]

    @State private var drag: CGSize = .zero
    @State private var matchToCelebrate: NameCard?
    @State private var showPartnerSwitch = false

    private var activePartner: Partner { Partner(rawValue: activePartnerRaw) ?? .a }

    private var genderFilter: Set<NameGender> {
        Set(genderFilterRaw.split(separator: ",").compactMap { NameGender(rawValue: String($0)) })
    }
    private var styleFilter: Set<NameStyle> {
        Set(styleFilterRaw.split(separator: ",").compactMap { NameStyle(rawValue: String($0)) })
    }

    private var pool: [NameCard] {
        NameCatalog.filtered(genders: genderFilter, styles: styleFilter,
                             initial: nil, maxLength: nil)
    }

    private var deck: [NameCard] {
        MatchEngine.undecided(pool: pool, verdicts: verdicts, partner: activePartner)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                partnerBar
                if deck.isEmpty {
                    emptyDeck
                } else {
                    cardStack
                    actionButtons
                }
            }
            .background(Theme.background(scheme))
            .navigationTitle("Swipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        FilterView()
                    } label: {
                        Image(systemName: genderFilter.isEmpty && styleFilter.isEmpty
                              ? "line.3.horizontal.decrease.circle"
                              : "line.3.horizontal.decrease.circle.fill")
                    }
                    .accessibilityLabel("Filter names")
                }
            }
            .sheet(item: $matchToCelebrate) { card in
                MatchCelebrationView(card: card)
            }
        }
    }

    private var partnerBar: some View {
        HStack(spacing: 10) {
            ForEach(Partner.allCases) { partner in
                Button {
                    Haptics.tap()
                    activePartnerRaw = partner.rawValue
                    drag = .zero
                } label: {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Theme.partnerColor(partner))
                            .frame(width: 10, height: 10)
                        Text(PartnerNames.name(partner))
                            .font(.subheadline.weight(activePartner == partner ? .bold : .regular))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(activePartner == partner
                                ? Theme.partnerColor(partner).opacity(0.18)
                                : Color.clear,
                                in: Capsule())
                    .overlay(Capsule().stroke(
                        activePartner == partner ? Theme.partnerColor(partner) : Theme.inkSoft(scheme).opacity(0.3),
                        lineWidth: 1.5))
                    .foregroundStyle(Theme.ink(scheme))
                }
                .accessibilityAddTraits(activePartner == partner ? .isSelected : [])
                .accessibilityHint("Switch to this partner's turn")
            }
        }
        .padding(.vertical, 12)
    }

    private var cardStack: some View {
        ZStack {
            ForEach(Array(deck.prefix(3).enumerated()).reversed(), id: \.element.id) { index, card in
                if index == 0 {
                    topCard(card)
                } else {
                    backCard(card, index: index)
                }
            }
        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal, 24)
    }

    private func topCard(_ card: NameCard) -> some View {
        NameCardView(card: card, partner: activePartner)
            .offset(drag)
            .rotationEffect(.degrees(Double(drag.width / 22)))
            .overlay(alignment: .topLeading) { stampOverlay(.pass) }
            .overlay(alignment: .topTrailing) { stampOverlay(.like) }
            .gesture(
                DragGesture()
                    .onChanged { drag = $0.translation }
                    .onEnded { value in handleDragEnd(value.translation, card: card) }
            )
            .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.7), value: drag)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(card.name), \(card.gender.label). \(card.origin): \(card.meaning)")
            .accessibilityHint("Swipe right to like, left to pass. Or use the buttons below.")
    }

    private func backCard(_ card: NameCard, index: Int) -> some View {
        NameCardView(card: card, partner: activePartner)
            .scaleEffect(1 - CGFloat(index) * 0.04)
            .offset(y: CGFloat(index) * 12)
            .opacity(index == 2 ? 0.5 : 1)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private func stampOverlay(_ decision: Decision) -> some View {
        let threshold: CGFloat = 40
        let active = decision == .like ? drag.width > threshold : drag.width < -threshold
        let progress = min(abs(drag.width) / 120, 1)
        Text(decision == .like ? "LIKE" : "PASS")
            .font(.system(size: 30, weight: .heavy, design: .rounded))
            .foregroundStyle(decision == .like ? Theme.mint : Theme.blush)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .overlay(RoundedRectangle(cornerRadius: 10)
                .stroke(decision == .like ? Theme.mint : Theme.blush, lineWidth: 4))
            .rotationEffect(.degrees(decision == .like ? -16 : 16))
            .padding(28)
            .opacity(active ? Double(progress) : 0)
            .accessibilityHidden(true)
    }

    private var actionButtons: some View {
        HStack(spacing: 24) {
            circleButton(icon: "xmark", color: Theme.blush, label: "Pass") {
                if let card = deck.first { record(.pass, card: card) }
            }
            circleButton(icon: "star.fill", color: Theme.butter, label: "Love it", size: 56) {
                if let card = deck.first { record(.superlike, card: card) }
            }
            circleButton(icon: "heart.fill", color: Theme.mint, label: "Like") {
                if let card = deck.first { record(.like, card: card) }
            }
        }
        .padding(.vertical, 20)
    }

    private func circleButton(icon: String, color: Color, label: String,
                              size: CGFloat = 64, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.36, weight: .bold))
                .foregroundStyle(color)
                .frame(width: size, height: size)
                .background(Theme.card(scheme), in: Circle())
                .overlay(Circle().stroke(color.opacity(0.4), lineWidth: 2))
                .shadow(color: .black.opacity(scheme == .dark ? 0.3 : 0.08), radius: 5, y: 2)
        }
        .accessibilityLabel(label)
    }

    private func handleDragEnd(_ translation: CGSize, card: NameCard) {
        let threshold: CGFloat = 110
        if translation.width > threshold {
            record(.like, card: card, fling: CGSize(width: 600, height: translation.height))
        } else if translation.width < -threshold {
            record(.pass, card: card, fling: CGSize(width: -600, height: translation.height))
        } else {
            drag = .zero
        }
    }

    private func record(_ decision: Decision, card: NameCard, fling: CGSize? = nil) {
        if let fling, !reduceMotion {
            drag = fling
        }
        // Remove any prior verdict for this name+partner, then insert fresh.
        let nameID = card.id
        let partner = activePartner
        for v in verdicts where v.nameID == nameID && v.partner == partner {
            context.delete(v)
        }
        let verdict = Verdict(nameID: nameID, partner: partner, decision: decision)
        context.insert(verdict)

        // Did this create a new match?
        if decision != .pass,
           let otherVerdict = MatchEngine.latestVerdict(verdicts: verdicts, nameID: nameID, partner: partner.other),
           otherVerdict.decision != .pass {
            Haptics.match()
            matchToCelebrate = card
        } else {
            Haptics.tap()
        }

        // Reset drag for the next card after the fling animation.
        DispatchQueue.main.asyncAfter(deadline: .now() + (fling != nil && !reduceMotion ? 0.28 : 0)) {
            drag = .zero
        }
    }

    private var emptyDeck: some View {
        VStack {
            Spacer()
            EmptyStateView(
                icon: "checkmark.circle.fill",
                title: "\(PartnerNames.name(activePartner)) is all caught up!",
                message: deck.isEmpty && pool.isEmpty
                    ? "No names match your current filter. Loosen it to see more."
                    : "You've swiped every name in this filter. Switch to \(PartnerNames.name(activePartner.other)) above, change the filter, or check your Matches.")
            Spacer()
        }
    }
}
