import SwiftUI

/// A calm circular progress arc with the percentage in the center.
struct ProgressArc: View {
    let progress: Double
    var size: CGFloat = 64
    var lineWidth: CGFloat = 7

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.orbInk.opacity(0.08), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(colors: [Color.orbLive,
                                             Color(red: 0.36, green: 0.94, blue: 0.69)],
                                    center: .center,
                                    startAngle: .degrees(0), endAngle: .degrees(360)),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: progress)
            Text("\(Int(progress * 100))")
                .font(.system(size: size * 0.30, weight: .bold, design: .rounded))
                .foregroundStyle(Color.orbInk)
        }
        .frame(width: size, height: size)
    }
}
