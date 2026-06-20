import SwiftUI

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool

    private let sampleColors: [Color] = [
        Color(red: 0.94, green: 0.44, blue: 0.36),
        Color(red: 0.98, green: 0.73, blue: 0.47),
        Color(red: 0.47, green: 0.72, blue: 0.63),
        Color(red: 0.31, green: 0.44, blue: 0.60),
        Color(red: 0.82, green: 0.82, blue: 0.87),
    ]

    var body: some View {
        ZStack {
            SwatchTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Color strip preview
                HStack(spacing: 0) {
                    ForEach(Array(sampleColors.enumerated()), id: \.offset) { _, color in
                        color
                    }
                }
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 32)
                .shadow(color: SwatchTheme.shadow, radius: 12, y: 6)

                Spacer().frame(height: 48)

                VStack(spacing: 12) {
                    Text("Swatch")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(SwatchTheme.accent)

                    Text("Extract beautiful color palettes\nfrom any photo.")
                        .font(.body)
                        .foregroundStyle(SwatchTheme.subtleText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                Spacer().frame(height: 48)

                VStack(spacing: 16) {
                    FeatureRow(icon: "photo", title: "Pick any photo", subtitle: "From your library or camera")
                    FeatureRow(icon: "wand.and.stars", title: "AI-powered extraction", subtitle: "K-means clustering finds dominant colors")
                    FeatureRow(icon: "square.and.arrow.up", title: "Copy & share", subtitle: "Hex codes, RGB values, full palettes")
                }
                .padding(.horizontal, 32)

                Spacer()

                Button {
                    hasSeenOnboarding = true
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(SwatchTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(SwatchTheme.accent)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SwatchTheme.accent)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(SwatchTheme.subtleText)
            }

            Spacer()
        }
    }
}
