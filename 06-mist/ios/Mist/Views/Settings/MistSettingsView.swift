import SwiftUI

struct MistSettingsView: View {
    @AppStorage("mistUseFahrenheit") private var useFahrenheit = false
    @AppStorage("mistHapticsEnabled") private var hapticsEnabled = true
    @AppStorage("mistDefaultType") private var defaultType = "Sauna"
    @AppStorage("mistAutoSave") private var autoSave = true
    @AppStorage("mistHasSeenOnboarding") private var hasSeenOnboarding = true

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.05, green: 0.18, blue: 0.22), Color(red: 0.02, green: 0.08, blue: 0.12)],
                          startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Text("Settings")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 20)
                        .padding(.horizontal, 20)

                    settingsSection("Units & Display") {
                        toggleRow("Fahrenheit", subtitle: "Show temperatures in °F instead of °C", value: $useFahrenheit)
                        Divider().background(Color.white.opacity(0.1))
                        pickerRow("Default Session Type", value: $defaultType, options: TherapyType.allCases.map(\.rawValue))
                    }

                    settingsSection("Session") {
                        toggleRow("Auto-Save Sessions", subtitle: "Save session data automatically on completion", value: $autoSave)
                        Divider().background(Color.white.opacity(0.1))
                        toggleRow("Haptic Feedback", subtitle: "Vibration cues during sessions", value: $hapticsEnabled)
                    }

                    settingsSection("About") {
                        infoRow("Version", value: "1.0")
                        Divider().background(Color.white.opacity(0.1))
                        Button(action: { hasSeenOnboarding = false }) {
                            HStack {
                                Text("Show Introduction")
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

    private func toggleRow(_ title: String, subtitle: String, value: Binding<Bool>) -> some View {
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
                .tint(Color(red: 0.15, green: 0.7, blue: 0.7))
        }
        .padding(16)
    }

    private func pickerRow(_ title: String, value: Binding<String>, options: [String]) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
            Picker("", selection: value) {
                ForEach(options, id: \.self) { o in Text(o).tag(o) }
            }
            .pickerStyle(.menu)
            .tint(Color(red: 0.15, green: 0.7, blue: 0.7))
        }
        .padding(16)
    }

    private func infoRow(_ title: String, value: String) -> some View {
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
