import SwiftUI

/// A self-contained, fixed-size card rendered to an image via `ImageRenderer`
/// for sharing. It does NOT depend on the environment so it renders identically
/// regardless of where it's invoked.
struct ShareCard: View {
    let event: CountdownEvent
    let now: Date
    let engine: CountdownEngine

    private var theme: CardTheme { event.theme }
    private var headline: (value: Int, unit: String, caption: String) {
        engine.headline(for: event, now: now)
    }
    private var span: CountdownEngine.Span { engine.span(for: event, now: now) }

    var body: some View {
        ZStack {
            theme.gradient

            Circle()
                .fill(Color.white.opacity(0.16))
                .frame(width: 360, height: 360)
                .blur(radius: 80)
                .offset(x: 140, y: -160)

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(Color.white.opacity(0.2)).frame(width: 64, height: 64)
                        EventSymbolView(symbol: event.symbol, isEmoji: event.symbolIsEmoji,
                                        size: 34, color: theme.onGradient)
                    }
                    Text(event.title.isEmpty ? "My event" : event.title)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.onGradient)
                        .lineLimit(2)
                    Spacer(minLength: 0)
                }

                Spacer(minLength: 20)

                if span.isToday {
                    Text("Today")
                        .font(.system(size: 96, weight: .heavy, design: .rounded))
                        .foregroundStyle(theme.onGradient)
                } else {
                    Text("\(headline.value)")
                        .font(.system(size: 132, weight: .heavy, design: .rounded))
                        .foregroundStyle(theme.onGradient)
                        .monospacedDigit()
                    Text("\(headline.unit) \(headline.caption)")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.onGradientSoft)
                }

                Spacer(minLength: 20)

                HStack {
                    Text(DateFmt.full.string(from: engine.effectiveDate(for: event, now: now)))
                        .font(.system(size: 22, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.onGradientSoft)
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "hourglass")
                            .font(.system(size: 18, weight: .bold))
                        Text("Cusp")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(theme.onGradient)
                }
            }
            .padding(48)
        }
        .frame(width: 600, height: 600)
        .clipShape(RoundedRectangle(cornerRadius: 48, style: .continuous))
    }
}
