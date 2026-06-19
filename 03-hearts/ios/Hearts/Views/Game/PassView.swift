import SwiftUI

struct PassView: View {
    @Bindable var engine: HeartsEngine
    @AppStorage("heartsHaptics") private var hapticsEnabled = true

    var body: some View {
        VStack(spacing: 0) {
            header
            Spacer()
            handArea
            Spacer(minLength: 8)
            passButton
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("Pass 3 Cards")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text("Passing \(engine.passDirection.label)")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
            Text("\(engine.selectedToPass.count)/3 selected")
                .font(.caption.bold())
                .foregroundStyle(engine.selectedToPass.count == 3 ? .green : .yellow)
        }
        .padding(.top, 24)
        .padding(.bottom, 16)
    }

    private var handArea: some View {
        let hand = engine.hands[0]
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: -20) {
                ForEach(hand) { card in
                    CardView(card: card, isSelected: engine.selectedToPass.contains(card), size: .normal)
                        .onTapGesture {
                            engine.togglePass(card)
                            if hapticsEnabled { UISelectionFeedbackGenerator().selectionChanged() }
                        }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
    }

    private var passButton: some View {
        Button {
            engine.confirmPass()
            if hapticsEnabled { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
        } label: {
            Text("Pass Selected Cards")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(engine.selectedToPass.count == 3 ? Color(red: 0.85, green: 0.1, blue: 0.2) : Color.white.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(engine.selectedToPass.count != 3)
        .animation(.easeInOut(duration: 0.2), value: engine.selectedToPass.count)
    }
}
