import SwiftUI

struct LearnView: View {
    @State private var selectedCategory: BrainwaveCategory? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                HaloTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: HaloTheme.spacingL) {
                        // Header
                        VStack(alignment: .leading, spacing: HaloTheme.spacingS) {
                            Text("Science of Sound")
                                .font(HaloTheme.displayFont)
                                .foregroundStyle(HaloTheme.textPrimary)
                            Text("How binaural beats interact with your brain")
                                .font(HaloTheme.bodyFont)
                                .foregroundStyle(HaloTheme.textSecondary)
                        }
                        .padding(.horizontal, HaloTheme.spacingL)

                        // Brainwave categories
                        Text("Brainwave Categories")
                            .font(HaloTheme.headlineFont)
                            .foregroundStyle(HaloTheme.textPrimary)
                            .padding(.horizontal, HaloTheme.spacingL)

                        ForEach(BrainwaveCategory.allCases) { category in
                            BrainwaveCategoryCard(category: category, isExpanded: selectedCategory == category) {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    selectedCategory = selectedCategory == category ? nil : category
                                }
                            }
                            .padding(.horizontal, HaloTheme.spacingL)
                        }

                        // How it works section
                        VStack(alignment: .leading, spacing: HaloTheme.spacingM) {
                            Text("How It Works")
                                .font(HaloTheme.headlineFont)
                                .foregroundStyle(HaloTheme.textPrimary)

                            InfoCard(
                                icon: "ear.and.waveform",
                                title: "Stereo Perception",
                                body: "Your brain detects the difference between two frequencies — one played in each ear — and perceives a phantom \"beat\" at that difference frequency."
                            )
                            InfoCard(
                                icon: "brain.head.profile",
                                title: "Frequency Following Response",
                                body: "The brain tends to synchronize its electrical activity with external rhythmic stimuli, a phenomenon called entrainment. Binaural beats leverage this mechanism."
                            )
                            InfoCard(
                                icon: "headphones",
                                title: "Headphones Required",
                                body: "Binaural beats only work through stereo headphones. Speakers mix both channels before reaching your ears, eliminating the perceived beat."
                            )
                            InfoCard(
                                icon: "clock",
                                title: "Give It Time",
                                body: "Sessions of 15–30 minutes are recommended. Effects are subtle and cumulative — consistent practice yields the best results."
                            )
                        }
                        .padding(.horizontal, HaloTheme.spacingL)

                        // Research note
                        VStack(alignment: .leading, spacing: HaloTheme.spacingS) {
                            Text("Research Note")
                                .font(HaloTheme.labelFont)
                                .foregroundStyle(HaloTheme.accent)
                            Text("Binaural beats are an active area of scientific study. While many users report benefits for focus, sleep, and relaxation, research is ongoing. Halo is a wellness tool and not a medical device.")
                                .font(HaloTheme.captionFont)
                                .foregroundStyle(HaloTheme.textTertiary)
                                .lineSpacing(3)
                        }
                        .padding(HaloTheme.spacingM)
                        .background(HaloTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: HaloTheme.radiusM))
                        .padding(.horizontal, HaloTheme.spacingL)

                        Spacer(minLength: HaloTheme.spacingXXL)
                    }
                    .padding(.top, HaloTheme.spacingL)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

private struct BrainwaveCategoryCard: View {
    let category: BrainwaveCategory
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: HaloTheme.spacingM) {
                HStack(spacing: HaloTheme.spacingM) {
                    ZStack {
                        Circle()
                            .fill(category.color.opacity(0.2))
                            .frame(width: 44, height: 44)
                        Image(systemName: category.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(category.color)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.rawValue)
                            .font(HaloTheme.headlineFont)
                            .foregroundStyle(HaloTheme.textPrimary)
                        Text(category.frequencyRange)
                            .font(HaloTheme.captionFont)
                            .foregroundStyle(category.color)
                    }
                    Spacer()
                    Text(category.useCase)
                        .font(HaloTheme.captionFont)
                        .foregroundStyle(HaloTheme.textSecondary)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 110)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(HaloTheme.textTertiary)
                }

                if isExpanded {
                    Text(category.description)
                        .font(HaloTheme.bodyFont)
                        .foregroundStyle(HaloTheme.textSecondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(HaloTheme.spacingM)
            .background(HaloTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: HaloTheme.radiusM))
            .overlay(
                RoundedRectangle(cornerRadius: HaloTheme.radiusM)
                    .stroke(isExpanded ? category.color.opacity(0.4) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct InfoCard: View {
    let icon: String
    let title: String
    let body: String

    var body: some View {
        HStack(alignment: .top, spacing: HaloTheme.spacingM) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(HaloTheme.accent)
                .frame(width: 28)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(HaloTheme.labelFont)
                    .foregroundStyle(HaloTheme.textPrimary)
                Text(body)
                    .font(HaloTheme.captionFont)
                    .foregroundStyle(HaloTheme.textSecondary)
                    .lineSpacing(3)
            }
        }
        .padding(HaloTheme.spacingM)
        .background(HaloTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: HaloTheme.radiusM))
    }
}
