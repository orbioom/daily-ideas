import SwiftUI

struct WaterRing: View {
    let fraction: Double          // 0…(can exceed 1)
    let centerTop: String
    let centerBottom: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle().stroke(Brand.hairline, lineWidth: 18)
            Circle()
                .trim(from: 0, to: min(1, fraction))
                .stroke(
                    LinearGradient(colors: [Color.accentColor.opacity(0.7), Color.accentColor],
                                   startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            if fraction >= 1 {
                Circle()
                    .trim(from: 0, to: min(1, fraction - 1))
                    .stroke(Brand.live, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            VStack(spacing: 4) {
                Text(centerTop)
                    .font(.system(size: 34, design: .rounded).weight(.bold))
                    .foregroundStyle(Brand.text)
                    .minimumScaleFactor(0.6).lineLimit(1)
                Text(centerBottom)
                    .font(.caption).foregroundStyle(Brand.text3)
            }
            .padding(.horizontal, 30)
        }
        .frame(width: 220, height: 220)
        .animation(reduceMotion ? nil : Brand.ease(0.5), value: fraction)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(centerTop) of \(centerBottom)")
    }
}
