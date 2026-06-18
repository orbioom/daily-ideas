import SwiftUI

/// Plain, prominent medical disclaimer.
struct DisclaimerView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ZStack {
                    Circle().fill(Theme.accentSoft).frame(width: 72, height: 72)
                    Image(systemName: "exclamationmark.shield.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }
                .accessibilityHidden(true)

                Text("Not medical advice")
                    .font(Theme.rounded(24, .bold))
                    .foregroundStyle(Theme.ink)

                Group {
                    para("Assay is a personal tool for organizing and visualizing your own lab results. It is for educational and tracking purposes only.")
                    para("Assay does not diagnose, treat, cure, or prevent any disease or condition. The reference and \"optimal\" ranges shown are general adult values drawn from commonly published guidance; your lab's reference ranges, your clinical context, age, medications, and individual factors may differ.")
                    para("A value flagged \"optimal,\" \"in range,\" or \"out of range\" by Assay is not a clinical interpretation. Lab results must be interpreted by a qualified healthcare professional who knows your full history.")
                    para("Never disregard professional medical advice or delay seeking it because of something you saw in this app. If you think you may have a medical emergency, contact your doctor or emergency services immediately.")
                    para("Your data stays on your device. You are responsible for any reports you choose to export and share.")
                }
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Disclaimer")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func para(_ text: String) -> some View {
        Text(text)
            .font(.callout)
            .foregroundStyle(Theme.inkSoft)
            .fixedSize(horizontal: false, vertical: true)
    }
}
