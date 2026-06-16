import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Theme.heroGradient)
                            .frame(width: 92, height: 92)
                        Image(systemName: "square.stack.3d.up.fill")
                            .font(.system(size: 42, weight: .semibold))
                            .foregroundStyle(.white)
                            .accessibilityHidden(true)
                    }
                    .padding(.top, 16)

                    VStack(spacing: 6) {
                        Text("Lane")
                            .font(Theme.rounded(28, .bold))
                            .foregroundStyle(Theme.ink)
                        Text("A fast, private kanban board for iPhone.")
                            .font(.body)
                            .foregroundStyle(Theme.inkSoft)
                            .multilineTextAlignment(.center)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        aboutRow("bolt.fill", "Native & instant", "Built with SwiftUI and SwiftData. No web views, no spinners.")
                        aboutRow("lock.shield.fill", "Private by default", "Your boards live on this device. No account, no cloud, no tracking.")
                        aboutRow("dollarsign.circle.fill", "Own it once", "A single one-time unlock — never a subscription.")
                    }
                    .padding(16)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))

                    Text("Made by Orbioom")
                        .font(.footnote)
                        .foregroundStyle(Theme.inkSoft)
                        .padding(.top, 4)
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func aboutRow(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(Theme.accent)
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
