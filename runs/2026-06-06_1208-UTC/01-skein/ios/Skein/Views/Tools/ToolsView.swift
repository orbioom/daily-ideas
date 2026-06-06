import SwiftUI

/// Hub for the calculators. Each pushes its own full screen.
struct ToolsView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 12) {
                        Text("Turn a swatch into numbers. Everything works offline and never leaves your phone.")
                            .font(.subheadline).foregroundStyle(Brand.text2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 4)
                        NavigationLink { GaugeCalcView() } label: {
                            ToolCard(icon: "ruler", title: "Gauge calculator",
                                     subtitle: "Cast-on stitches & rows for a target size")
                        }.buttonStyle(.plain)
                        NavigationLink { YardageEstimatorView() } label: {
                            ToolCard(icon: "scalemass", title: "Yardage estimator",
                                     subtitle: "How much yarn a piece needs — and if you have it")
                        }.buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16).padding(.bottom, 28)
                }
            }
            .navigationTitle("Tools")
        }
    }
}

private struct ToolCard: View {
    let icon: String, title: String, subtitle: String
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.title2).foregroundStyle(Brand.text)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline).foregroundStyle(Brand.text)
                Text(subtitle).font(.subheadline).foregroundStyle(Brand.text2)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.footnote).foregroundStyle(Brand.text3)
        }
        .glassCard()
    }
}
