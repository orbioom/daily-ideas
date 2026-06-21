import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var settingsArr: [AlleySettings]
    @Environment(\.modelContext) private var ctx
    @State private var showProSheet = false

    var settings: AlleySettings? { settingsArr.first }

    var body: some View {
        NavigationStack {
            ZStack {
                AlleyTheme.darkBackground.ignoresSafeArea()

                if let s = settings {
                    List {
                        // GAMEPLAY section
                        Section {
                            SettingsToggleRow(
                                icon: "number.square.fill",
                                iconColor: AlleyTheme.accent,
                                title: "Show Running Total",
                                subtitle: "Display cumulative score under each frame",
                                isOn: Binding(
                                    get: { s.showRunningTotal },
                                    set: { s.showRunningTotal = $0 }
                                )
                            )

                            SettingsToggleRow(
                                icon: "dot.radiowaves.left.and.right",
                                iconColor: Color.orange,
                                title: "Haptic Feedback",
                                subtitle: "Feel a tap when recording each ball",
                                isOn: Binding(
                                    get: { s.hapticEnabled },
                                    set: { s.hapticEnabled = $0 }
                                )
                            )

                            SettingsToggleRow(
                                icon: "speaker.wave.2.fill",
                                iconColor: Color(red: 0.3, green: 0.6, blue: 1.0),
                                title: "Sound Effects",
                                subtitle: "Play sounds on strike and spare",
                                isOn: Binding(
                                    get: { s.soundEnabled },
                                    set: { s.soundEnabled = $0 }
                                )
                            )
                        } header: {
                            Text("Gameplay")
                                .foregroundStyle(AlleyTheme.laneColor.opacity(0.8))
                        }
                        .listRowBackground(AlleyTheme.frameBackground)

                        // DISPLAY section
                        Section {
                            SettingsToggleRow(
                                icon: "circle.grid.3x3.fill",
                                iconColor: AlleyTheme.spareColor,
                                title: "Show Pin Diagram",
                                subtitle: "Visual pin layout during ball entry",
                                isOn: Binding(
                                    get: { s.showPinDiagram },
                                    set: { s.showPinDiagram = $0 }
                                )
                            )

                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.purple.opacity(0.25))
                                        .frame(width: 34, height: 34)
                                    Image(systemName: "person.fill.badge.plus")
                                        .font(.system(size: 16))
                                        .foregroundStyle(Color.purple)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Default Player Count")
                                        .font(.system(size: 15))
                                        .foregroundStyle(.white)
                                    Text("Auto-fill players when starting a game")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.5))
                                }

                                Spacer()

                                Picker("Players", selection: Binding(
                                    get: { s.defaultPlayerCount },
                                    set: { s.defaultPlayerCount = $0 }
                                )) {
                                    ForEach(1...6, id: \.self) { count in
                                        Text("\(count)").tag(count)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(AlleyTheme.accent)
                            }
                            .padding(.vertical, 4)
                        } header: {
                            Text("Display")
                                .foregroundStyle(AlleyTheme.laneColor.opacity(0.8))
                        }
                        .listRowBackground(AlleyTheme.frameBackground)

                        // PRO section
                        Section {
                            if s.isPro {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(AlleyTheme.strikeColor.opacity(0.2))
                                            .frame(width: 34, height: 34)
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(AlleyTheme.strikeColor)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Alley Pro")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(.white)
                                        Text("All features unlocked. Thank you!")
                                            .font(.caption)
                                            .foregroundStyle(AlleyTheme.strikeColor.opacity(0.8))
                                    }
                                }
                                .padding(.vertical, 4)
                            } else {
                                Button {
                                    showProSheet = true
                                } label: {
                                    HStack(spacing: 14) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(AlleyTheme.accent.opacity(0.25))
                                                .frame(width: 34, height: 34)
                                            Image(systemName: "crown.fill")
                                                .font(.system(size: 16))
                                                .foregroundStyle(AlleyTheme.accent)
                                        }

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Upgrade to Pro")
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundStyle(.white)
                                            Text("Unlock unlimited history and cloud sync")
                                                .font(.caption)
                                                .foregroundStyle(.white.opacity(0.5))
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.white.opacity(0.3))
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        } header: {
                            Text("Pro")
                                .foregroundStyle(AlleyTheme.laneColor.opacity(0.8))
                        }
                        .listRowBackground(AlleyTheme.frameBackground)

                        // ABOUT section
                        Section {
                            HStack {
                                Text("Version")
                                    .foregroundStyle(.white.opacity(0.8))
                                Spacer()
                                Text("1.0")
                                    .foregroundStyle(.white.opacity(0.4))
                            }

                            HStack {
                                Text("Bundle ID")
                                    .foregroundStyle(.white.opacity(0.8))
                                Spacer()
                                Text("com.orbioom.alley")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                        } header: {
                            Text("About")
                                .foregroundStyle(AlleyTheme.laneColor.opacity(0.8))
                        }
                        .listRowBackground(AlleyTheme.frameBackground)
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .listSectionSpacing(12)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showProSheet) {
                if let s = settings {
                    ProUpgradeView(settings: s)
                }
            }
        }
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(AlleyTheme.accent)
                .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

struct ProUpgradeView: View {
    let settings: AlleySettings
    @Environment(\.dismiss) private var dismiss

    private let features = [
        ("infinity", Color.blue, "Unlimited Game History", "Keep every game you've ever played"),
        ("icloud.fill", Color.cyan, "iCloud Sync", "Access your scores on all devices"),
        ("chart.xyaxis.line", Color.green, "Advanced Analytics", "Detailed trends and performance charts"),
        ("square.and.arrow.up", Color.orange, "Export Scores", "Share your scorecard as an image or PDF"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [AlleyTheme.darkBackground, Color(red: 0.20, green: 0.05, blue: 0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Crown icon
                    ZStack {
                        Circle()
                            .fill(AlleyTheme.accent.opacity(0.15))
                            .frame(width: 90, height: 90)
                        Image(systemName: "crown.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(AlleyTheme.strikeColor)
                    }
                    .padding(.top, 32)

                    Text("Alley Pro")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.top, 12)

                    Text("One-time purchase — no subscriptions")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.top, 4)

                    // Features
                    VStack(spacing: 12) {
                        ForEach(features, id: \.0) { icon, color, title, desc in
                            HStack(spacing: 14) {
                                Image(systemName: icon)
                                    .font(.system(size: 20))
                                    .foregroundStyle(color)
                                    .frame(width: 28)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(title)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(.white)
                                    Text(desc)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                                Spacer()
                            }
                        }
                    }
                    .padding(20)
                    .background(AlleyTheme.frameBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 24)
                    .padding(.top, 28)

                    Spacer()

                    VStack(spacing: 12) {
                        Button {
                            settings.isPro = true
                            dismiss()
                        } label: {
                            Text("Unlock Pro — $2.99")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(AlleyTheme.accent)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(color: AlleyTheme.accent.opacity(0.4), radius: 8, y: 4)
                        }

                        Button {
                            dismiss()
                        } label: {
                            Text("Restore Purchase")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.5))
                            .font(.title3)
                    }
                }
            }
        }
    }
}
