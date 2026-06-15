import SwiftUI

/// About sheet: what Reveille is, the honest reliability note, and credits.
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 14) {
                        Image(systemName: "sunrise.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Theme.accent)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reveille")
                                .font(Theme.rounded(26, .bold)).foregroundStyle(Theme.ink)
                            Text("A calmer way to actually wake up")
                                .font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
                        }
                    }

                    paragraph("Reveille is an alarm clock for heavy sleepers and snooze addicts. Pick a dismiss mission — math, memory, tap targets, shake, or steady-typing — and the alarm only stops when you finish it. A bedside clock and wake-up stats round it out.")

                    section("How it rings")
                    paragraph("Tones are synthesized live on your device with AVAudioEngine — no audio files ship with the app. The volume ramps up gently so you wake without a jolt.")

                    section("An honest note on reliability")
                    paragraph("Reveille rings reliably while it's open or running in the background, using the audio background mode. iOS does not let any third-party app guarantee a custom ringing alarm after the app has been force-quit. To cover that case, Reveille also schedules a local notification at each alarm time as a backstop. For the most reliable wake-up, leave Reveille running in the background overnight.")

                    section("No dark patterns")
                    paragraph("Reveille Pro is a one-time unlock. There's no subscription, no ads, and we will never nag you to rate or pay after you've already unlocked.")

                    Text("Version 1.0")
                        .font(Theme.rounded(13)).foregroundStyle(Theme.inkFaint)
                        .padding(.top, 4)
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
        }
    }

    private func section(_ text: String) -> some View {
        Text(text)
            .font(Theme.rounded(17, .bold))
            .foregroundStyle(Theme.ink)
            .padding(.top, 4)
    }

    private func paragraph(_ text: String) -> some View {
        Text(text)
            .font(Theme.rounded(15))
            .foregroundStyle(Theme.inkSoft)
            .fixedSize(horizontal: false, vertical: true)
    }
}
