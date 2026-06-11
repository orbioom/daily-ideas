import SwiftUI

struct MurmurOnboardingView: View {
    @AppStorage("murmur.onboardingDone") private var done = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(MurmurTheme.accent)
                .accessibilityHidden(true)
                .padding(.bottom, 16)

            Text("Murmur")
                .font(.system(size: 44, weight: .black, design: .serif))
                .padding(.bottom, 8)
            Text("Your private voice journal")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .padding(.bottom, 44)

            VStack(alignment: .leading, spacing: 22) {
                row(icon: "mic.fill", title: "Record anywhere",
                    body: "Tap to record your thoughts, feelings, or ideas. Pause and resume any time.")
                row(icon: "text.bubble", title: "On-device transcription",
                    body: "Speech is transcribed instantly on your device. Your voice never leaves your phone.")
                row(icon: "heart", title: "Track your mood",
                    body: "Tag each entry with a mood and build a picture of how you feel over time.")
                row(icon: "magnifyingglass", title: "Search everything",
                    body: "Full-text search across all transcripts and tags. Find any memory in seconds.")
            }
            .padding(.horizontal, 28)

            Spacer()

            Button("Get Started") { done = true }
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(MurmurTheme.accent)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 28)
                .padding(.bottom, 44)
        }
    }

    private func row(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(MurmurTheme.accent)
                .frame(width: 30)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 15, weight: .bold, design: .rounded))
                Text(body).font(.system(size: 13)).foregroundStyle(.secondary)
            }
        }
    }
}
