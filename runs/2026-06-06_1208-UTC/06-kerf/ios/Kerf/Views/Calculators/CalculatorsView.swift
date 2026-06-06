import SwiftUI

/// Hub for the standalone shop calculators.
struct CalculatorsView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 12) {
                        Text("Quick shop math — no project required. Everything runs offline.")
                            .font(.subheadline).foregroundStyle(Brand.text2)
                            .frame(maxWidth: .infinity, alignment: .leading).padding(.bottom, 4)
                        NavigationLink { BoardFootView() } label: {
                            card("ruler.fill", "Board-foot calculator", "Volume and cost of rough lumber")
                        }.buttonStyle(.plain)
                        NavigationLink { QuickPlanView() } label: {
                            card("square.stack.3d.up", "Quick cut planner", "Optimize cuts without saving a project")
                        }.buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16).padding(.bottom, 28)
                }
            }
            .navigationTitle("Calculators")
        }
    }

    private func card(_ icon: String, _ title: String, _ subtitle: String) -> some View {
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
