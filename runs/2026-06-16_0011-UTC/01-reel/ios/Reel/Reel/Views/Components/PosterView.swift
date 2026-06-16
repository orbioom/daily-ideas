import SwiftUI

/// A generated gradient "poster" for a Title — derived entirely from its colorSeed and name.
/// No bundled images: a cinematic gradient, the title initials, and a faint film-strip motif.
struct PosterView: View {
    let title: Title
    /// When false (Settings toggle), render a flat surface card instead of the gradient.
    var asGradient: Bool = true
    /// Show the small star + status overlay (used in the Library grid).
    var showOverlay: Bool = true
    var cornerRadius: CGFloat = 14

    var body: some View {
        ZStack {
            background
            filmStrip
            VStack {
                Spacer()
                Text(title.initials)
                    .font(Theme.serif(40, .heavy))
                    .foregroundStyle(asGradient ? .white : Theme.ink)
                    .shadow(color: .black.opacity(asGradient ? 0.35 : 0), radius: 6, y: 2)
                Spacer()
            }
            .padding(.horizontal, 6)

            if showOverlay {
                overlay
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Theme.hairline.opacity(0.6), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    @ViewBuilder
    private var background: some View {
        if asGradient {
            Theme.posterGradient(seed: title.colorSeed)
        } else {
            Theme.surfaceAlt
        }
    }

    /// Faint perforated film-strip edges down both sides — a cinematic motif.
    private var filmStrip: some View {
        HStack {
            stripColumn
            Spacer()
            stripColumn
        }
        .opacity(asGradient ? 0.5 : 0.25)
        .accessibilityHidden(true)
    }

    private var stripColumn: some View {
        VStack(spacing: 6) {
            ForEach(0..<8, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(Color.black.opacity(0.28))
                    .frame(width: 5, height: 7)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
    }

    private var overlay: some View {
        VStack {
            HStack {
                Spacer()
                Image(systemName: title.kind.systemImage)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.92))
                    .padding(6)
                    .background(Circle().fill(.black.opacity(0.28)))
                    .padding(6)
            }
            Spacer()
            VStack(spacing: 4) {
                if let rating = title.rating, rating > 0 {
                    StarsView(rating: rating, size: 10, tint: .white)
                }
                StatusChip(status: title.status)
            }
            .padding(.bottom, 8)
        }
    }

    private var accessibilityText: String {
        var parts = ["\(title.name), \(title.year), \(title.kind.displayName)"]
        if let r = title.rating, r > 0 {
            parts.append(String(format: "rated %.1f of 5", r))
        }
        parts.append(title.status.displayName)
        return parts.joined(separator: ", ")
    }
}
