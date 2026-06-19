import SwiftUI

struct ColorPickerBarView: View {
    let colorCount: Int
    let codeLength: Int
    @Binding var currentGuess: [Int]
    let onSubmit: () -> Void

    @State private var selected: Int? = nil

    var canSubmit: Bool { currentGuess.count == codeLength }

    var body: some View {
        VStack(spacing: 16) {
            // Active guess pegs
            HStack(spacing: 10) {
                ForEach(0..<codeLength, id: \.self) { i in
                    PegView(
                        colorIndex: i < currentGuess.count ? currentGuess[i] : nil,
                        size: 42
                    )
                    .onTapGesture {
                        if i < currentGuess.count {
                            currentGuess.removeLast(currentGuess.count - i)
                        }
                    }
                }
            }

            // Color palette
            HStack(spacing: 10) {
                ForEach(0..<colorCount, id: \.self) { i in
                    PegView(colorIndex: i, size: 36)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: selected == i ? 2.5 : 0)
                        )
                        .scaleEffect(selected == i ? 1.1 : 1.0)
                        .onTapGesture {
                            if currentGuess.count < codeLength {
                                currentGuess.append(i)
                                selected = i
                                let generator = UISelectionFeedbackGenerator()
                                generator.selectionChanged()
                            }
                        }
                        .animation(.spring(response: 0.2), value: selected)
                }
            }

            HStack(spacing: 12) {
                Button(action: {
                    if !currentGuess.isEmpty {
                        currentGuess.removeLast()
                        selected = nil
                    }
                }) {
                    Image(systemName: "delete.backward")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 52, height: 44)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(currentGuess.isEmpty)

                Button(action: onSubmit) {
                    Text("Submit")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(canSubmit ? Color.purple : Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(!canSubmit)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.04))
    }
}
