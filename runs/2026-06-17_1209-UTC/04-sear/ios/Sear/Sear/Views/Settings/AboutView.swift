import SwiftUI

/// About screen — what Sear is, plus the food-safety disclaimer.
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        Image(systemName: "flame.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(Theme.accent)
                            .padding(.top, 12)
                            .accessibilityHidden(true)
                        Text("Sear")
                            .font(Theme.rounded(28, .bold))
                            .foregroundStyle(Theme.ink)
                        Text("Your live-fire BBQ & smoking companion. A real doneness guide, a live cook timer with a phase timeline, a rub keeper and a cook log — offline, no account.")
                            .font(Theme.rounded(15))
                            .foregroundStyle(Theme.inkSoft)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)

                        VStack(alignment: .leading, spacing: 8) {
                            Label("Food safety", systemImage: "checkmark.shield")
                                .font(Theme.rounded(15, .bold))
                                .foregroundStyle(Theme.ink)
                            Text("Temperatures here are general guidance, including USDA-safe minimums for live-fire cooking. Always cook to a safe internal temperature and use a calibrated thermometer. Sear is not a substitute for food-safety judgment.")
                                .font(Theme.rounded(13))
                                .foregroundStyle(Theme.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .searCard()

                        Text("Version 1.0")
                            .font(Theme.rounded(12))
                            .foregroundStyle(Theme.inkFaint)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
