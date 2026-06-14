import SwiftUI

/// A rich gradient card for the home timeline. Shows a live count, the title,
/// symbol and date. The count refreshes via the enclosing `TimelineView` (the
/// `now` is injected so the whole list ticks together cheaply).
struct EventCard: View {
    let event: CountdownEvent
    let now: Date
    let engine: CountdownEngine
    let showSeconds: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var theme: CardTheme { event.theme }
    private var headline: (value: Int, unit: String, caption: String) {
        engine.headline(for: event, now: now)
    }
    private var span: CountdownEngine.Span { engine.span(for: event, now: now) }

    var body: some View {
        ZStack(alignment: .topLeading) {
            theme.gradient

            // Soft luminous corner glow for depth.
            Circle()
                .fill(Color.white.opacity(0.16))
                .frame(width: 160, height: 160)
                .blur(radius: 40)
                .offset(x: 120, y: -80)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 0) {
                header
                Spacer(minLength: 12)
                countBlock
            }
            .padding(18)
        }
        .frame(height: 168)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: theme.dot.opacity(0.28), radius: 14, x: 0, y: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle().fill(Color.white.opacity(0.18))
                    .frame(width: 38, height: 38)
                EventSymbolView(symbol: event.symbol, isEmoji: event.symbolIsEmoji,
                                size: 20, color: theme.onGradient)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title.isEmpty ? "Untitled" : event.title)
                    .font(Theme.rounded(18, .semibold))
                    .foregroundStyle(theme.onGradient)
                    .lineLimit(1)
                Text(DateFmt.line(for: event, date: engine.effectiveDate(for: event, now: now)))
                    .font(Theme.rounded(13))
                    .foregroundStyle(theme.onGradientSoft)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            VStack(spacing: 4) {
                if event.pinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(theme.onGradientSoft)
                        .accessibilityHidden(true)
                }
                if event.repeatRule.repeats {
                    Image(systemName: "repeat")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(theme.onGradientSoft)
                        .accessibilityHidden(true)
                }
            }
        }
    }

    private var countBlock: some View {
        HStack(alignment: .lastTextBaseline, spacing: 8) {
            if span.isToday {
                Text("Today")
                    .font(Theme.rounded(40, .bold))
                    .foregroundStyle(theme.onGradient)
            } else {
                Text("\(headline.value)")
                    .font(Theme.rounded(46, .bold))
                    .foregroundStyle(theme.onGradient)
                    .contentTransition(reduceMotion ? .identity : .numericText())
                    .monospacedDigit()
                VStack(alignment: .leading, spacing: 0) {
                    Text(headline.unit)
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(theme.onGradient)
                    Text(headline.caption)
                        .font(Theme.rounded(12))
                        .foregroundStyle(theme.onGradientSoft)
                }
            }
            Spacer(minLength: 0)
            if showSeconds && event.includeTime && !span.isToday {
                Text(tickerText)
                    .font(Theme.rounded(13, .medium).monospacedDigit())
                    .foregroundStyle(theme.onGradientSoft)
                    .accessibilityHidden(true)
            }
        }
    }

    private var tickerText: String {
        String(format: "%02d:%02d:%02d", span.hours, span.minutes, span.seconds)
    }

    private var accessibilityText: String {
        let title = event.title.isEmpty ? "Untitled" : event.title
        if span.isToday { return "\(title), today" }
        let unit = headline.value == 1 ? "day" : "days"
        return "\(title), \(headline.value) \(unit) \(headline.caption)"
    }
}
