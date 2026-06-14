import SwiftUI

/// Simple About sheet explaining what Allot is and its principles.
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private let points: [(String, String, String)] = [
        ("dollarsign.circle.fill", "Zero-based budgeting", "Assign every dollar you have until Ready to Assign hits zero."),
        ("lock.shield.fill", "Private by design", "No bank logins, no accounts, no cloud. Your data never leaves this device."),
        ("creditcard.fill", "One-time price", "Pay once for Pro. No subscription — a fraction of YNAB's yearly cost.")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    Image(systemName: "tray.full.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Theme.accent)
                        .padding(.top, 12)
                        .accessibilityHidden(true)
                    Text("Allot")
                        .font(Theme.rounded(28, .bold))
                        .foregroundStyle(Theme.ink)
                    Text("Give every dollar a job.")
                        .font(Theme.rounded(16))
                        .foregroundStyle(Theme.inkSoft)

                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(points, id: \.1) { point in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: point.0)
                                    .font(.system(size: 18))
                                    .foregroundStyle(Theme.accent)
                                    .frame(width: 28)
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(point.1).font(Theme.rounded(16, .semibold)).foregroundStyle(Theme.ink)
                                    Text(point.2).font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 0)
                            }
                        }
                    }
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface))

                    Text("Version 1.0 · Made for people who want control without the spreadsheet.")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkFaint)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
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
}
