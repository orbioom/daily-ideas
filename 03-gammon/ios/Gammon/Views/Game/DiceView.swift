import SwiftUI

// MARK: - Dice View
// Shows two dice with pip dots in classic die layout.

struct DiceView: View {
    let die1: Int
    let die2: Int
    let usedDice: [Int]   // dice values still remaining in movesLeft

    private func isUsed(_ value: Int, die: Int) -> Bool {
        // A die face is "used" (greyed out) if it's no longer in movesLeft
        // For doubles, we compare how many are left
        let total = (die1 == die2) ? 4 : 1
        let remaining = usedDice.filter { $0 == value }.count
        if die1 == die2 {
            // die parameter 1..4 for the four copies
            return die > remaining
        } else {
            return remaining == 0
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            if die1 == die2 {
                // Doubles: show 4 dice
                ForEach(1...4, id: \.self) { i in
                    SingleDieView(value: die1, isUsed: isUsed(die1, die: i))
                }
            } else {
                SingleDieView(value: die1, isUsed: usedDice.filter({ $0 == die1 }).isEmpty)
                SingleDieView(value: die2, isUsed: usedDice.filter({ $0 == die2 }).isEmpty)
            }
        }
    }
}

// MARK: - Single Die

struct SingleDieView: View {
    let value: Int
    let isUsed: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(isUsed ? Color.gray.opacity(0.25) : Color(red: 0.95, green: 0.92, blue: 0.84))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isUsed ? Color.gray.opacity(0.3) : GammonTheme.accent.opacity(0.6), lineWidth: 1.5)
                )
                .frame(width: 44, height: 44)
                .shadow(color: Color.black.opacity(0.4), radius: 4, y: 2)

            PipLayout(value: value, isUsed: isUsed)
                .frame(width: 34, height: 34)
        }
        .opacity(isUsed ? 0.45 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isUsed)
    }
}

// MARK: - Pip Layout

struct PipLayout: View {
    let value: Int
    let isUsed: Bool

    private var pipColor: Color {
        isUsed ? Color.gray : Color(red: 0.15, green: 0.08, blue: 0.03)
    }

    // 9 possible positions (3x3 grid)
    // Position layout:
    // TL  TC  TR
    // ML  MC  MR
    // BL  BC  BR
    private var pipPositions: [Bool] {
        // returns [TL, TC, TR, ML, MC, MR, BL, BC, BR]
        switch value {
        case 1: return [false, false, false,  false, true, false,  false, false, false]
        case 2: return [true, false, false,   false, false, false,  false, false, true]
        case 3: return [true, false, false,   false, true, false,  false, false, true]
        case 4: return [true, false, true,    false, false, false,  true, false, true]
        case 5: return [true, false, true,    false, true, false,  true, false, true]
        case 6: return [true, false, true,    true, false, true,   true, false, true]
        default: return Array(repeating: false, count: 9)
        }
    }

    var body: some View {
        let positions = pipPositions
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let cols: [CGFloat] = [w * 0.15, w * 0.5, w * 0.85]
            let rows: [CGFloat] = [h * 0.15, h * 0.5, h * 0.85]
            let pipSize: CGFloat = w * 0.22

            ZStack {
                ForEach(0..<9, id: \.self) { i in
                    if positions[i] {
                        let col = i % 3
                        let row = i / 3
                        Circle()
                            .fill(pipColor)
                            .frame(width: pipSize, height: pipSize)
                            .position(x: cols[col], y: rows[row])
                    }
                }
            }
        }
    }
}

// MARK: - Roll Dice Button

struct RollDiceButton: View {
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isPressed = false
                action()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "die.face.5.fill")
                    .font(.title3)
                Text("Roll Dice")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .foregroundStyle(GammonTheme.background)
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            .background(GammonTheme.accent)
            .cornerRadius(14)
            .shadow(color: GammonTheme.accent.opacity(0.5), radius: 10, y: 4)
            .scaleEffect(isPressed ? 0.93 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 20) {
        DiceView(die1: 3, die2: 5, usedDice: [3, 5])
        DiceView(die1: 4, die2: 4, usedDice: [4, 4])
        DiceView(die1: 6, die2: 2, usedDice: [])
        RollDiceButton { }
    }
    .padding()
    .background(GammonTheme.background)
}
