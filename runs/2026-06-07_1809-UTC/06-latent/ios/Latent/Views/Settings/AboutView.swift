import SwiftUI

/// A small About sheet explaining what Latent is and how its math works.
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 16) {
                        hero
                        howCard
                        creditCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var hero: some View {
        VStack(spacing: 12) {
            Image(systemName: "film.stack")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(Brand.magic)
                .accessibilityHidden(true)
            Text("Latent")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Brand.text)
            Text("A calm darkroom companion for developing black-and-white film at home.")
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    private var howCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "How it works")
            bullet("Save recipes with a base develop time at 20 °C and box speed.")
            bullet("Each run, enter the real chemistry temperature and any push or pull.")
            bullet("Latent compensates the develop time (about −8 %/°C warmer) and applies push/pull factors.")
            bullet("A relaunch-safe timer guides you through Develop, Stop, Fix and Wash with agitation reminders.")
            bullet("Every finished run is logged with its parameters, rating and notes.")
        }
        .glassCard()
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "circle.fill")
                .font(.system(size: 5))
                .foregroundStyle(Brand.magic)
                .padding(.top, 7)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Brand.text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var creditCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: "Notes")
            Text("Times are guidance, not gospel — always cross-check with your developer's data sheet and your own results. Everything stays on this device.")
                .font(.footnote)
                .foregroundStyle(Brand.text2)
                .fixedSize(horizontal: false, vertical: true)
            Text("Conjured by Orbioom.")
                .font(Brand.mono(12, weight: .medium))
                .foregroundStyle(Brand.text3)
                .padding(.top, 4)
        }
        .glassCard()
    }
}
