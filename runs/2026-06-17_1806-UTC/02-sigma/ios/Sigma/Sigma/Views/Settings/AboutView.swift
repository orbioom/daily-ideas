import SwiftUI

/// A short About screen describing Sigma.
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .fill(Theme.accent)
                                .frame(width: 96, height: 96)
                                .shadow(color: Theme.keyShadow.opacity(0.4), radius: 12, y: 6)
                            Text("Σ")
                                .font(.system(size: 52, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.accentInk)
                                .accessibilityHidden(true)
                        }
                        .padding(.top, 24)

                        Text("Sigma")
                            .font(Theme.rounded(28, .bold))
                            .foregroundStyle(Theme.ink)
                        Text("A precise scientific & programmer calculator with a searchable history tape and unit converter — beautiful, one-time, no ads.")
                            .font(Theme.rounded(16))
                            .foregroundStyle(Theme.inkSoft)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        VStack(alignment: .leading, spacing: 14) {
                            aboutRow("function", "Real expression evaluation", "Tokenizer, shunting-yard and RPN — proper order of operations.")
                            aboutRow("list.bullet.rectangle", "History tape", "Every result saved, searchable, reusable.")
                            aboutRow("arrow.left.arrow.right", "Unit converter", "Nine categories with a live all-units breakdown.")
                            aboutRow("number.square", "Programmer mode", "DEC, HEX, BIN, OCT and bitwise operations.")
                        }
                        .padding(18)
                        .background(RoundedRectangle(cornerRadius: Theme.cornerCard, style: .continuous).fill(Theme.surface))
                        .padding(.horizontal, 16)

                        Text("Made for people who do real math on their phone.")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkFaint)
                            .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }

    private func aboutRow(_ icon: String, _ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Theme.accent)
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                Text(body)
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
