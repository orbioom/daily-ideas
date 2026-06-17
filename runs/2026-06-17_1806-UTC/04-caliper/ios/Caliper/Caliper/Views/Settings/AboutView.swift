import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    aboutCard(title: "Private by design",
                              text: "Everything you log stays on your device with SwiftData. There are no accounts, no servers and no analytics.")

                    aboutCard(title: "Honest metrics",
                              text: "Caliper uses the US Navy circumference method for body-fat, plus BMI, waist-to-hip ratio and FFMI. Estimates are guides, not medical advice.")

                    aboutCard(title: "One-time, no ads",
                              text: "The core tracker is free forever. A single Pro purchase unlocks the extras — no subscription, no ads, ever.")

                    Text("Made for people who just want to see their progress clearly.")
                        .font(.footnote)
                        .foregroundStyle(Theme.inkSoft)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Theme.heroGradient)
                    .frame(width: 88, height: 88)
                Image(systemName: "ruler.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)
            Text("Caliper")
                .font(Theme.rounded(26, .bold))
                .foregroundStyle(Theme.ink)
            Text("Body-measurement & physique tracker")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func aboutCard(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(Theme.rounded(16, .bold))
                .foregroundStyle(Theme.ink)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardSurface()
        .accessibilityElement(children: .combine)
    }
}
