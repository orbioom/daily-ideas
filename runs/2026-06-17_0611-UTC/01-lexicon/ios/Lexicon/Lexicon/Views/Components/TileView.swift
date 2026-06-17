import SwiftUI

/// A single rounded letter tile.
///
/// When its state settles (after a guess is submitted) it performs a tactile
/// flip reveal: the tile rotates on the X axis to 90° (edge-on), swaps from the
/// "typed" face to the settled colored face at the midpoint, then rotates back.
/// With Reduce Motion on, it simply shows the settled face immediately.
struct TileView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let letter: Character?
    /// The settled state (.absent/.present/.correct) once submitted, else .empty/.tbd.
    let state: TileState
    let highContrast: Bool
    /// Reveal delay (seconds) so a row flips left-to-right.
    var revealDelay: Double = 0

    @State private var angle: Double = 0
    @State private var showSettledFace = false
    @State private var pop = false

    private var isSettled: Bool {
        state == .absent || state == .present || state == .correct
    }

    /// The face currently drawn: settled color once revealed, else the typed look.
    private var faceState: TileState {
        if isSettled { return showSettledFace ? state : .tbd }
        return state
    }

    var body: some View {
        let displayState = faceState
        let hasLetter = letter != nil
        let borderColor: Color = {
            switch displayState {
            case .empty: return LexTheme.tileEmptyBorder(scheme)
            case .tbd: return hasLetter ? LexTheme.tileFilledBorder(scheme) : LexTheme.tileEmptyBorder(scheme)
            default: return .clear
            }
        }()

        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(displayState.fill(scheme: scheme, highContrast: highContrast))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 2)
            )
            .overlay(
                Text(letter.map { String($0) } ?? "")
                    .font(LexTheme.display(28, weight: .heavy))
                    .foregroundStyle(displayState.textColor(scheme: scheme))
                    .minimumScaleFactor(0.5)
                    .padding(2)
            )
            .aspectRatio(1, contentMode: .fit)
            .scaleEffect(pop ? 1.06 : 1.0)
            .rotation3DEffect(.degrees(angle), axis: (x: 1, y: 0, z: 0))
            .onAppear {
                if isSettled { showSettledFace = true }
            }
            .onChange(of: isSettled) { _, nowSettled in
                if nowSettled {
                    revealFlip()
                } else {
                    showSettledFace = false
                    angle = 0
                }
            }
            .onChange(of: hasLetter) { wasEmpty, nowHas in
                guard !reduceMotion, nowHas, wasEmpty == false, !isSettled else { return }
                pop = true
                withAnimation(.spring(response: 0.18, dampingFraction: 0.5)) { pop = false }
            }
            .accessibilityElement()
            .accessibilityLabel(accessibilityLabel)
    }

    private func revealFlip() {
        guard !reduceMotion else {
            showSettledFace = true
            angle = 0
            return
        }
        // Rotate to edge-on, swap the face at the midpoint, rotate back.
        withAnimation(.easeIn(duration: 0.14).delay(revealDelay)) {
            angle = 90
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + revealDelay + 0.14) {
            showSettledFace = true
            withAnimation(.easeOut(duration: 0.14)) {
                angle = 0
            }
        }
    }

    private var accessibilityLabel: String {
        let l = letter.map { String($0).uppercased() } ?? "blank"
        return "\(l), \(faceState.accessibilityPhrase)"
    }
}
