import SwiftUI

struct CipherSettingsView: View {
    @AppStorage("showAuthorOnLoad") private var showAuthor = false
    @AppStorage("showThemeOnLoad") private var showTheme = true
    @AppStorage("hapticsEnabled") private var haptics = true
    @AppStorage("timerVisible") private var timerVisible = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Puzzle") {
                    Toggle("Show theme on load", isOn: $showTheme)
                        .tint(CipherTheme.accent)
                        .accessibilityLabel("Show puzzle theme when opening a puzzle")
                    Toggle("Show author on load", isOn: $showAuthor)
                        .tint(CipherTheme.accent)
                        .accessibilityLabel("Reveal author name before solving")
                    Toggle("Show timer", isOn: $timerVisible)
                        .tint(CipherTheme.accent)
                        .accessibilityLabel("Show elapsed time while solving")
                }
                Section("Feedback") {
                    Toggle("Haptics", isOn: $haptics)
                        .tint(CipherTheme.accent)
                        .accessibilityLabel("Haptic feedback on solve and letter assign")
                }
                Section("About") {
                    HStack { Text("Version"); Spacer(); Text("1.0").foregroundStyle(CipherTheme.subtle) }
                    HStack { Text("Puzzles"); Spacer(); Text("40 quotes, grows over time").font(.caption).foregroundStyle(CipherTheme.subtle) }
                    HStack { Text("Data"); Spacer(); Text("On-device only").font(.caption).foregroundStyle(CipherTheme.subtle) }
                }
            }
            .scrollContentBackground(.hidden)
            .background(CipherTheme.bg)
            .navigationTitle("Settings")
        }
    }
}
