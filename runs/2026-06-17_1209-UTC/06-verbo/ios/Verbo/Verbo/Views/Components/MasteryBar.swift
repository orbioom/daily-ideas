import SwiftUI

/// A horizontal mastery meter, 0...1.
struct MasteryBar: View {
    let mastery: Double   // 0...1
    var height: CGFloat = 8

    private var clamped: Double { min(1, max(0, mastery)) }

    private var color: Color {
        if clamped >= 0.8 { return Theme.good }
        if clamped >= 0.4 { return Theme.accent }
        return Theme.bad
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.hairline)
                Capsule()
                    .fill(color)
                    .frame(width: max(0, geo.size.width * clamped))
            }
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Mastery")
        .accessibilityValue("\(Int((clamped * 100).rounded())) percent")
    }
}
