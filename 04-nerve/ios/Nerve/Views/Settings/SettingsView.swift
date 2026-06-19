import SwiftUI

struct SettingsView: View {
    @AppStorage("preferredDifficulty") private var preferredDifficulty = "Medium"
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("showTimer") private var showTimer = true
    @AppStorage("colorBlindMode") private var colorBlindMode = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = true

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.05, blue: 0.16).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Text("Settings")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 20)
                        .padding(.horizontal, 20)

                    settingsSection("Gameplay") {
                        pickerRow(title: "Default Difficulty", value: $preferredDifficulty, options: Difficulty.allCases.map(\.rawValue))
                        Divider().background(Color.white.opacity(0.1))
                        toggleRow(title: "Show Timer", subtitle: "Display elapsed time during games", value: $showTimer)
                    }

                    settingsSection("Accessibility") {
                        toggleRow(title: "Haptic Feedback", subtitle: "Vibration on peg placement and results", value: $hapticsEnabled)
                        Divider().background(Color.white.opacity(0.1))
                        toggleRow(title: "Color Blind Mode", subtitle: "Adds shape indicators to peg colors", value: $colorBlindMode)
                    }

                    settingsSection("About") {
                        infoRow(title: "Version", value: "1.0")
                        Divider().background(Color.white.opacity(0.1))
                        Button(action: { hasSeenOnboarding = false }) {
                            HStack {
                                Text("Show Tutorial")
                                    .font(.system(size: 16, design: .rounded))
                                    .foregroundStyle(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.white.opacity(0.4))
                                    .font(.caption)
                            }
                            .padding(16)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            VStack(spacing: 0) {
                content()
            }
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 20)
        }
    }

    private func toggleRow(title: String, subtitle: String, value: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
            }
            Spacer()
            Toggle("", isOn: value)
                .tint(.purple)
        }
        .padding(16)
    }

    private func pickerRow(title: String, value: Binding<String>, options: [String]) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
            Picker("", selection: value) {
                ForEach(options, id: \.self) { o in Text(o).tag(o) }
            }
            .pickerStyle(.menu)
            .tint(.purple)
        }
        .padding(16)
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
            Text(value)
                .font(.system(size: 16, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(16)
    }
}
