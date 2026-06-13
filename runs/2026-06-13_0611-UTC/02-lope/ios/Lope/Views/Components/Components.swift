import SwiftUI

struct ProgressRing: View {
    let progress: Double      // 0...1
    var lineWidth: CGFloat = 12
    var color: Color = Theme.accent
    var track: Color = Theme.surfaceAlt

    var body: some View {
        ZStack {
            Circle().stroke(track, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 20).fill(Theme.surface))
    }
}

struct EmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 46, weight: .light))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(title).font(Theme.display(22)).foregroundStyle(Theme.ink)
            Text(message)
                .font(.system(size: 15)).foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center).padding(.horizontal, 36)
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle).font(.system(size: 15, weight: .semibold))
                        .padding(.horizontal, 22).padding(.vertical, 11)
                        .background(Capsule().fill(Theme.accent))
                        .foregroundStyle(Theme.accentInk)
                }.padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 50)
    }
}

struct Pill: View {
    let kind: SegmentKind
    let seconds: Int
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: kind.icon).font(.system(size: 11, weight: .bold))
            Text(Format.clock(seconds)).font(.system(size: 13, weight: .semibold, design: .rounded))
                .monospacedDigit()
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 9).padding(.vertical, 5)
        .background(Capsule().fill(Theme.segmentColor(kind)))
    }
}

struct StatTile: View {
    let value: String
    let label: String
    var color: Color = Theme.ink
    var body: some View {
        VStack(spacing: 3) {
            Text(value).font(Theme.display(24)).foregroundStyle(color).monospacedDigit()
            Text(label.uppercased()).font(.system(size: 11, weight: .semibold))
                .tracking(0.5).foregroundStyle(Theme.inkFaint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.surface))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }
}
