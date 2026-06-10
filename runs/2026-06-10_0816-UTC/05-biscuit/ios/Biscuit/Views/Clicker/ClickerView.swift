import SwiftUI
import SwiftData

/// A standalone clicker for free-form training, plus a tiny guide to using a
/// marker well. Counts clicks in the current burst.
struct ClickerView: View {
    @AppStorage("clickerHaptics") private var clickerHaptics = true
    @AppStorage("clickerSound") private var clickerSound = true
    @State private var clicks = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                VStack(spacing: 22) {
                    Spacer()
                    Text(clicks == 0 ? "Tap to mark the moment" : "\(clicks) clicks")
                        .font(Brand.mono(18, weight: .medium))
                        .foregroundStyle(Brand.text2)
                        .contentTransition(.numericText())

                    Button {
                        clicks += 1
                        if clickerSound { Clicker.shared.click() }
                        if clickerHaptics { Haptics.tap() }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Brand.inkGradient)
                                .frame(width: 230, height: 230)
                                .shadow(color: Brand.cardShadow, radius: 20, x: 0, y: 12)
                            VStack(spacing: 8) {
                                Image(systemName: "hand.tap.fill")
                                    .font(.system(size: 56))
                                    .foregroundStyle(.white)
                                Text("CLICK")
                                    .font(Brand.mono(17, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.85))
                            }
                        }
                    }
                    .buttonStyle(ClickerButtonStyle())
                    .accessibilityLabel("Clicker")
                    .accessibilityHint("Plays a marker click")

                    if clicks > 0 {
                        Button("Reset count") {
                            clicks = 0
                            Haptics.tap()
                        }
                        .font(.subheadline)
                        .foregroundStyle(Brand.text3)
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 8) {
                        Eyebrow(text: "Using the marker")
                        guideRow("Click the instant the behavior happens — the click is a camera shutter.")
                        guideRow("Always follow a click with a treat, even an accidental one.")
                        guideRow("One click per behavior. Treat delivery can be slow; the click can't.")
                    }
                    .glassCard()
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
            .navigationTitle("Clicker")
        }
        .onDisappear { Clicker.shared.stop() }
    }

    private func guideRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Brand.live)
                .frame(width: 5, height: 5)
                .padding(.top, 6)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
        }
    }
}
