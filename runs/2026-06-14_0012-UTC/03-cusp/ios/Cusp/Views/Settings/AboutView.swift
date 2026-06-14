import SwiftUI

/// A small About sheet describing Cusp's philosophy.
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(CardTheme.coral.gradient)
                            .frame(width: 110, height: 110)
                        Image(systemName: "hourglass")
                            .font(.system(size: 52, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .accessibilityHidden(true)
                    .padding(.top, 12)

                    VStack(spacing: 6) {
                        Text("Cusp")
                            .font(Theme.rounded(28, .bold))
                            .foregroundStyle(Theme.ink)
                        Text("Days until & days since")
                            .font(Theme.rounded(15))
                            .foregroundStyle(Theme.inkSoft)
                    }

                    Text("A calm, ad-free countdown app. Track the days until your most-anticipated moments and the days since your fondest memories — with live tickers and gorgeous gradient cards. No paywalled widgets, no dark patterns: a single honest one-time unlock when you want more.")
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 4)

                    VStack(spacing: 0) {
                        infoRow("Made by", "Orbioom")
                        Divider().overlay(Theme.hairline)
                        infoRow("Built with", "SwiftUI · SwiftData")
                        Divider().overlay(Theme.hairline)
                        infoRow("Privacy", "All data stays on device")
                    }
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Theme.hairline, lineWidth: 1)
                    )
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

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(Theme.rounded(15)).foregroundStyle(Theme.inkSoft)
            Spacer()
            Text(value).font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .accessibilityElement(children: .combine)
    }
}
