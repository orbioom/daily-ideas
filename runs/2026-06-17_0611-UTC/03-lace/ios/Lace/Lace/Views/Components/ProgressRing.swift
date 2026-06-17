import SwiftUI

/// A bold circular progress ring. Honors Reduce Motion by avoiding implicit
/// animation; the caller can pass static values for a discrete fallback.
struct ProgressRing: View {
    @Environment(\.colorScheme) private var scheme

    /// 0...1 progress fraction.
    let progress: Double
    var lineWidth: CGFloat = 12
    var color: Color = Theme.coral
    /// Optional center content.
    var centerContent: AnyView? = nil

    private var clamped: Double { min(1.0, max(0.0, progress)) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.track(scheme), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if let centerContent {
                centerContent
            }
        }
    }
}

/// A small linear progress bar used for overall session progress.
struct LaceProgressBar: View {
    @Environment(\.colorScheme) private var scheme
    let progress: Double
    var color: Color = Theme.coral
    var height: CGFloat = 10

    private var clamped: Double { min(1.0, max(0.0, progress)) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.track(scheme))
                Capsule()
                    .fill(color)
                    .frame(width: max(0, geo.size.width * clamped))
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}
