import SwiftUI

struct SymbolPicker: View {
    @Binding var selected: String
    @Environment(\.dismiss) private var dismiss

    private let symbols: [String] = [
        "figure.run", "figure.walk", "figure.hiking", "figure.cycling", "figure.swimming",
        "dumbbell.fill", "sportscourt.fill", "bicycle", "skateboard",
        "book.fill", "book.closed.fill", "pencil.and.scribble", "pencil", "doc.text.fill",
        "brain.head.profile", "brain", "lightbulb.fill", "graduationcap.fill",
        "drop.fill", "cup.and.saucer.fill", "fork.knife", "leaf.fill", "carrot.fill",
        "moon.fill", "bed.double.fill", "alarm.fill", "sunrise.fill",
        "heart.fill", "heart.text.square.fill", "lungs.fill", "stethoscope",
        "music.note", "guitars.fill", "piano", "headphones",
        "camera.fill", "paintbrush.fill", "paintpalette.fill", "photo",
        "house.fill", "sparkles", "star.fill", "bolt.fill",
        "phone.fill", "envelope.fill", "message.fill",
        "banknote.fill", "creditcard.fill", "chart.line.uptrend.xyaxis",
        "tree.fill", "pawprint.fill", "tortoise.fill",
        "cross.fill", "pill.fill", "syringe.fill",
        "wineglass", "cigarette", "gamecontroller.fill",
        "airplane", "car.fill", "bus.fill",
        "hammer.fill", "wrench.fill", "scissors",
        "waveform.path.ecg", "timer", "stopwatch.fill"
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(symbols, id: \.self) { symbol in
                            Button {
                                selected = symbol
                                Haptics.selection()
                                dismiss()
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(selected == symbol
                                              ? Brand.live.opacity(0.2)
                                              : Color.clear)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .strokeBorder(
                                                    selected == symbol ? Brand.live : Brand.hairline,
                                                    lineWidth: selected == symbol ? 2 : 1
                                                )
                                        )
                                        .frame(width: 56, height: 56)

                                    Image(systemName: symbol)
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundStyle(selected == symbol ? Brand.live : Brand.text2)
                                        .accessibilityHidden(true)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(symbol.replacingOccurrences(of: ".", with: " ").replacingOccurrences(of: "fill", with: ""))
                            .accessibilityValue(selected == symbol ? "selected" : "not selected")
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Brand.text)
                }
            }
        }
    }
}
