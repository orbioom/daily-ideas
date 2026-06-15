import SwiftUI

/// A self-contained, branded card rendered to an image for sharing.
/// Uses no environment colors (so it renders identically off-screen).
struct ShareCardView: View {
    let profile: Profile

    private var result: ScoredResult { profile.scoredResult }
    private var archetype: Archetype { result.archetype }
    private var identity: Identity { TypeMapper.identity(for: result.traitScores) }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Image(systemName: "circle.hexagongrid.fill")
                Text("Facet")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Spacer()
            }
            .foregroundStyle(.white.opacity(0.9))

            Spacer()

            Text(profile.name)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
            Text(archetype.name)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)
                .lineLimit(2)

            HStack(spacing: 6) {
                ForEach(Array((result.typeCode + identity.letter).enumerated()), id: \.offset) { _, ch in
                    Text(String(ch))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .fill(Color.white.opacity(0.18))
                        )
                }
            }

            Text(archetype.tagline)
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))

            Spacer()

            VStack(spacing: 8) {
                ForEach(result.traitScores) { ts in
                    HStack(spacing: 8) {
                        Text(ts.trait.shortLabel)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(width: 16)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.2))
                                Capsule().fill(Color.white)
                                    .frame(width: max(4, geo.size.width * (max(0, min(100, ts.score)) / 100)))
                            }
                        }
                        .frame(height: 8)
                        Text("\(Int(ts.score))")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.85))
                            .frame(width: 24, alignment: .trailing)
                    }
                }
            }

            Text("Take the test on Facet")
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(24)
        .frame(width: 340, height: 480)
        .background(
            LinearGradient(
                colors: [Color(hex: 0x6E63E0), Color(hex: 0x5A52C8), Color(hex: 0x3F8FD6)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
    }
}
