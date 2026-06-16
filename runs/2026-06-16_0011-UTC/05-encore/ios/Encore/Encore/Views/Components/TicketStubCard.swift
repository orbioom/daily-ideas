import SwiftUI

/// A rounded-rectangle ticket silhouette with two perforation notches cut into the leading and
/// trailing edges at `notchY` (a fraction of the height). Filled with even-odd so the notches
/// read as cutouts, giving cards their torn-ticket shape.
struct TicketShape: Shape {
    var cornerRadius: CGFloat = Theme.corner
    var notchRadius: CGFloat = 9
    var notchY: CGFloat = 0.66

    func path(in rect: CGRect) -> Path {
        var path = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).path(in: rect)
        let y = rect.minY + rect.height * notchY
        let left = CGRect(x: rect.minX - notchRadius, y: y - notchRadius,
                          width: notchRadius * 2, height: notchRadius * 2)
        let right = CGRect(x: rect.maxX - notchRadius, y: y - notchRadius,
                           width: notchRadius * 2, height: notchRadius * 2)
        path.addEllipse(in: left)
        path.addEllipse(in: right)
        return path
    }
}

/// The headline ticket-stub card used on the Timeline and Shows screens.
struct TicketStubCard: View {
    let concert: Concert

    private var colors: (Color, Color) { Theme.ticketColors(seed: concert.colorSeed) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top: gradient stage portion (≈ upper two-thirds, above the perforation).
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(concert.headliner)
                            .font(Theme.rounded(20, .bold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                        if !concert.tourName.trimmingCharacters(in: .whitespaces).isEmpty {
                            Text(concert.tourName)
                                .font(Theme.rounded(13, .medium))
                                .foregroundStyle(.white.opacity(0.85))
                                .lineLimit(1)
                        }
                    }
                    Spacer(minLength: 8)
                    Image(systemName: concert.type.symbol)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .accessibilityHidden(true)
                    if concert.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(.white)
                            .accessibilityHidden(true)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 76, alignment: .topLeading)
            .background(Theme.ticketGradient(seed: concert.colorSeed))

            // Perforation line.
            DashedDivider()
                .padding(.horizontal, 14)
                .padding(.vertical, 1)
                .background(Theme.surface)

            // Bottom: stub details on surface.
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    if !concert.locationLine.isEmpty {
                        Text(concert.locationLine)
                            .font(Theme.rounded(14, .semibold))
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1)
                    }
                    Text(concert.date.formatted(date: .abbreviated, time: .omitted))
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                if let rating = concert.rating {
                    RatingStarsDisplay(rating: rating, size: 12)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Theme.surface)
        }
        .clipShape(TicketShape(notchY: 0.62), style: FillStyle(eoFill: true))
        .overlay(
            TicketShape(notchY: 0.62)
                .stroke(Theme.hairline, lineWidth: 1)
        )
        .shadow(color: colors.0.opacity(0.18), radius: 8, y: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var parts = [concert.headliner]
        if !concert.locationLine.isEmpty { parts.append(concert.locationLine) }
        parts.append(concert.date.formatted(date: .abbreviated, time: .omitted))
        if let r = concert.rating { parts.append(String(format: "rated %.1f of 5", r)) }
        if concert.isFavorite { parts.append("favorite") }
        return parts.joined(separator: ", ")
    }
}

/// A dashed horizontal perforation line.
struct DashedDivider: View {
    var body: some View {
        Line()
            .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            .foregroundStyle(Theme.hairline)
            .frame(height: 1)
            .accessibilityHidden(true)
    }
}

private struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return p
    }
}
