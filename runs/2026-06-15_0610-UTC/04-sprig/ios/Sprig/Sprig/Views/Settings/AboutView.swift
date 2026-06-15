import SwiftUI

/// About sheet: what Sprig is, how percentiles work, and the medical disclaimer.
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    CardView {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "What Sprig does", systemImage: "leaf.fill")
                            Text("Sprig plots your child's weight, height, and head circumference on real WHO growth curves, tracks developmental milestones, and follows the routine immunization schedule. Focused, accurate, and entirely on your device.")
                                .font(Theme.rounded(14))
                                .foregroundStyle(Theme.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    CardView {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "How percentiles work", systemImage: "function")
                            Text("Percentiles use the WHO LMS method. For a measurement X at an age, with the reference's L (power), M (median), and S (variation):")
                                .font(Theme.rounded(14))
                                .foregroundStyle(Theme.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("z = ((X / M)^L − 1) / (L · S)")
                                .font(Theme.mono(13))
                                .foregroundStyle(Theme.ink)
                            Text("The percentile is the standard-normal probability of that z-score. The curves you see are the same math run in reverse at fixed percentiles.")
                                .font(Theme.rounded(14))
                                .foregroundStyle(Theme.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    CardView {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Medical disclaimer", systemImage: "stethoscope")
                            Text("Sprig is for informational and educational purposes only. It is not medical advice, diagnosis, or treatment, and is not a substitute for the judgment of your pediatrician or other qualified health professional. Always seek their guidance with any questions about your child's growth, development, or immunizations.")
                                .font(Theme.rounded(14))
                                .foregroundStyle(Theme.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Text("Made with care for parents. Version 1.0")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkFaint)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 44))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("Sprig")
                .font(Theme.rounded(28, .bold))
                .foregroundStyle(Theme.ink)
            Text("Grow with confidence.")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
}
