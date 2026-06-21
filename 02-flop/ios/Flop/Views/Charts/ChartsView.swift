import SwiftUI

struct ChartsView: View {
    @State private var selectedPosition: PokerPosition = .btn
    @State private var selectedGroup = 0

    var body: some View {
        ZStack {
            FlopTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                positionPicker
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                groupLegend
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                ScrollView {
                    VStack(spacing: 16) {
                        handGroupsSection
                        chartGridSection
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle("Pre-flop Charts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(FlopTheme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    var positionPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PokerPosition.allCases, id: \.self) { pos in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedPosition = pos }
                    } label: {
                        VStack(spacing: 2) {
                            Text(pos.rawValue)
                                .font(.system(size: 14, weight: .bold))
                            Text(positionSubtitle(pos))
                                .font(.system(size: 10))
                        }
                        .foregroundStyle(selectedPosition == pos ? .black : (FlopTheme.positionColors[pos] ?? FlopTheme.textSecondary))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            selectedPosition == pos
                                ? (FlopTheme.positionColors[pos] ?? FlopTheme.accent)
                                : (FlopTheme.positionColors[pos] ?? FlopTheme.textSecondary).opacity(0.18),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                    }
                    .accessibilityLabel("Position: \(pos.fullName)")
                }
            }
        }
    }

    func positionSubtitle(_ pos: PokerPosition) -> String {
        switch pos {
        case .utg: return "tightest"
        case .mp: return "tight"
        case .co: return "looser"
        case .btn: return "widest"
        case .sb: return "OOP"
        case .bb: return "defend"
        }
    }

    var groupLegend: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(PokerEngine.handGroups, id: \.group) { g in
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color(hex: g.color))
                            .frame(width: 10, height: 10)
                        Text(g.group)
                            .font(.system(size: 12))
                            .foregroundStyle(FlopTheme.textSecondary)
                    }
                }
            }
        }
    }

    var handGroupsSection: some View {
        VStack(spacing: 10) {
            ForEach(PokerEngine.handGroups, id: \.group) { g in
                HandGroupRow(group: g, position: selectedPosition)
            }
        }
    }

    var chartGridSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Range Overview — \(selectedPosition.fullName)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(FlopTheme.textPrimary)
            Text("13×13 grid: suited above diagonal (top-right), offsuit below (bottom-left), pairs on diagonal.")
                .font(.system(size: 12))
                .foregroundStyle(FlopTheme.textSecondary)
            HandRangeGrid(position: selectedPosition)
        }
        .padding(14)
        .background(FlopTheme.felt, in: RoundedRectangle(cornerRadius: 14))
    }
}

struct HandGroupRow: View {
    let group: (group: String, color: String, hands: [String])
    let position: PokerPosition

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle().fill(Color(hex: group.color)).frame(width: 10, height: 10)
                Text(group.group)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(FlopTheme.textPrimary)
            }
            FlexWrap(items: group.hands) { hand in
                Text(hand)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(FlopTheme.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: group.color).opacity(0.25), in: RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(12)
        .background(FlopTheme.felt, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct FlexWrap<Item: Hashable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content

    @State private var totalHeight: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            generateContent(in: geo)
        }
        .frame(height: totalHeight)
    }

    func generateContent(in geo: GeometryProxy) -> some View {
        var width: CGFloat = 0
        var height: CGFloat = 0
        var lastHeight: CGFloat = 0
        let itemSpacing: CGFloat = 6

        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                content(item)
                    .fixedSize()
                    .alignmentGuide(.leading) { d in
                        if abs(width - d.width) > geo.size.width {
                            width = 0
                            height -= lastHeight + itemSpacing
                        }
                        let result = width
                        if item == items.last { width = 0 }
                        else { width -= d.width + itemSpacing }
                        lastHeight = d.height
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if item == items.last { height = 0 }
                        return result
                    }
            }
        }
        .background(
            GeometryReader { g in
                Color.clear.preference(key: HeightPreferenceKey.self, value: g.size.height)
            }
        )
        .onPreferenceChange(HeightPreferenceKey.self) { totalHeight = $0 }
    }
}

struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct HandRangeGrid: View {
    let position: PokerPosition
    private let ranks: [Rank] = [.ace, .king, .queen, .jack, .ten, .nine, .eight, .seven, .six, .five, .four, .three, .two]

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 2) {
                Color.clear.frame(width: 22, height: 22)
                ForEach(ranks, id: \.self) { r in
                    Text(r.shortName)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(FlopTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            ForEach(Array(ranks.enumerated()), id: \.offset) { i, r1 in
                HStack(spacing: 2) {
                    Text(r1.shortName)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(FlopTheme.textSecondary)
                        .frame(width: 22)
                    ForEach(Array(ranks.enumerated()), id: \.offset) { j, r2 in
                        gridCell(r1: r1, r2: r2, i: i, j: j)
                    }
                }
            }
        }
    }

    func gridCell(r1: Rank, r2: Rank, i: Int, j: Int) -> some View {
        let hand = makeHand(r1: r1, r2: r2, suited: i < j)
        let action = hand.map { PokerEngine.correctAction(hand: $0) }
        let color = actionFillColor(action: action, isPair: i == j)
        return Rectangle()
            .fill(color)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .cornerRadius(2)
            .accessibilityHidden(true)
    }

    func makeHand(r1: Rank, r2: Rank, suited: Bool) -> HandQuiz? {
        let suit1 = Suit.spades
        let suit2 = suited ? Suit.spades : Suit.hearts
        let c1 = PlayingCard(rank: r1, suit: suit1)
        let c2 = PlayingCard(rank: r2, suit: suit2)
        return HandQuiz(card1: c1, card2: c2, position: position, correctAction: .fold, explanation: "")
    }

    func actionFillColor(action: PreFlopAction?, isPair: Bool) -> Color {
        guard let a = action else { return FlopTheme.card }
        switch a {
        case .raise: return FlopTheme.accentGold.opacity(0.85)
        case .call: return FlopTheme.accent.opacity(0.6)
        case .fold: return FlopTheme.card.opacity(0.5)
        }
    }
}

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
