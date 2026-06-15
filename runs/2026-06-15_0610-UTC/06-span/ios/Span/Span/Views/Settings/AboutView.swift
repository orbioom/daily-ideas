import SwiftUI

/// A short, honest about sheet.
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "calendar")
                        .font(.system(size: 58))
                        .foregroundStyle(Theme.accent)
                        .padding(.top, 16)
                        .accessibilityHidden(true)

                    Text("Span")
                        .font(Theme.serif(32, .bold)).foregroundStyle(Theme.ink)
                    Text("Your life in weeks. A calm memento-mori calendar — color your eras, pin your milestones, and see the time you have.")
                        .font(Theme.rounded(16)).foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 12)

                    VStack(alignment: .leading, spacing: 12) {
                        row("calendar", "Every week of your life is one dot.")
                        row("paintpalette", "Color your life into chapters.")
                        row("mappin.and.ellipse", "Pin milestones and count down to goals.")
                        row("lock.shield", "All on-device. No accounts, no ads, no tracking.")
                    }
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous).fill(Theme.surface))
                    .padding(.horizontal, 4)

                    Text("Inspired by the \"Your Life in Weeks\" idea. Version 1.0")
                        .font(Theme.rounded(13)).foregroundStyle(Theme.inkFaint)
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

    private func row(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 24)
                .accessibilityHidden(true)
            Text(text).font(Theme.rounded(15)).foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
    }
}
