import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var settingsArr: [RectoSettings]
    @Environment(\.modelContext) private var ctx
    @State private var showProSheet: Bool = false

    private var settings: RectoSettings? { settingsArr.first }

    var body: some View {
        NavigationStack {
            ZStack {
                RectoTheme.paperBackground.ignoresSafeArea()

                if let s = settings {
                    List {
                        // MARK: Appearance
                        Section {
                            // Theme picker
                            HStack {
                                Label("Theme", systemImage: "circle.lefthalf.filled")
                                    .foregroundStyle(RectoTheme.inkPrimary)
                                Spacer()
                                Picker("", selection: Binding(
                                    get: { s.theme },
                                    set: { s.theme = $0; try? ctx.save() }
                                )) {
                                    Text("System").tag("system")
                                    Text("Light").tag("light")
                                    Text("Dark").tag("dark")
                                }
                                .pickerStyle(.menu)
                                .foregroundStyle(RectoTheme.inkSecondary)
                            }

                            // Font style picker
                            HStack {
                                Label("Font Style", systemImage: "textformat")
                                    .foregroundStyle(RectoTheme.inkPrimary)
                                Spacer()
                                Picker("", selection: Binding(
                                    get: { s.fontStyle },
                                    set: { s.fontStyle = $0; try? ctx.save() }
                                )) {
                                    Text("Sans-serif").tag("sans")
                                    Text("Serif").tag("serif")
                                }
                                .pickerStyle(.menu)
                                .foregroundStyle(RectoTheme.inkSecondary)
                            }

                            // Font preview
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Preview")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(RectoTheme.inkSecondary)
                                    .textCase(.uppercase)
                                HStack(alignment: .top, spacing: 10) {
                                    Text("•")
                                        .font(.system(size: 18, weight: .semibold, design: .serif))
                                        .foregroundStyle(RectoTheme.taskColor)
                                    Text("Write in your journal daily")
                                        .font(.system(
                                            size: 15,
                                            weight: .regular,
                                            design: s.fontStyle == "serif" ? .serif : .default
                                        ))
                                        .foregroundStyle(RectoTheme.inkPrimary)
                                }
                            }
                            .padding(.vertical, 4)
                        } header: {
                            Text("Appearance")
                        }
                        .listRowBackground(Color.white.opacity(0.55))

                        // MARK: Journaling
                        Section {
                            Toggle(isOn: Binding(
                                get: { s.showDateHeader },
                                set: { s.showDateHeader = $0; try? ctx.save() }
                            )) {
                                Label("Show Date Headers", systemImage: "calendar.badge.clock")
                                    .foregroundStyle(RectoTheme.inkPrimary)
                            }
                            .tint(RectoTheme.taskColor)

                            Toggle(isOn: Binding(
                                get: { s.hapticEnabled },
                                set: { s.hapticEnabled = $0; try? ctx.save() }
                            )) {
                                Label("Haptic Feedback", systemImage: "waveform")
                                    .foregroundStyle(RectoTheme.inkPrimary)
                            }
                            .tint(RectoTheme.taskColor)

                            HStack {
                                Label("Default Bullet", systemImage: "circle.dotted")
                                    .foregroundStyle(RectoTheme.inkPrimary)
                                Spacer()
                                Picker("", selection: Binding(
                                    get: { BulletType(rawValue: s.defaultBulletType) ?? .task },
                                    set: { s.defaultBulletType = $0.rawValue; try? ctx.save() }
                                )) {
                                    ForEach(BulletType.allCases, id: \.self) { type in
                                        Text(type.displayName).tag(type)
                                    }
                                }
                                .pickerStyle(.menu)
                                .foregroundStyle(RectoTheme.inkSecondary)
                            }
                        } header: {
                            Text("Journaling")
                        }
                        .listRowBackground(Color.white.opacity(0.55))

                        // MARK: Pro
                        Section {
                            if s.isPro {
                                HStack {
                                    Label("Recto Pro", systemImage: "star.fill")
                                        .foregroundStyle(RectoTheme.starColor)
                                        .font(.system(size: 16, weight: .semibold))
                                    Spacer()
                                    Text("Active")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(RectoTheme.eventColor)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                        .background(RectoTheme.eventColor.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                            } else {
                                Button {
                                    showProSheet = true
                                } label: {
                                    HStack {
                                        Label("Upgrade to Pro", systemImage: "star")
                                            .foregroundStyle(RectoTheme.inkPrimary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(RectoTheme.inkSecondary.opacity(0.5))
                                    }
                                }
                                .foregroundStyle(RectoTheme.inkPrimary)
                            }
                        } header: {
                            Text("Pro")
                        }
                        .listRowBackground(Color.white.opacity(0.55))

                        // MARK: About
                        Section {
                            HStack {
                                Label("Version", systemImage: "info.circle")
                                    .foregroundStyle(RectoTheme.inkPrimary)
                                Spacer()
                                Text("1.0")
                                    .foregroundStyle(RectoTheme.inkSecondary)
                            }

                            HStack {
                                Label("Made with", systemImage: "heart")
                                    .foregroundStyle(RectoTheme.inkPrimary)
                                Spacer()
                                Text("Swift & SwiftUI")
                                    .foregroundStyle(RectoTheme.inkSecondary)
                            }
                        } header: {
                            Text("About")
                        }
                        .listRowBackground(Color.white.opacity(0.55))
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .preferredColorScheme(colorScheme(for: s.theme))
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showProSheet) {
                if let s = settings {
                    ProUpgradeSheet(settings: s, isPresented: $showProSheet)
                }
            }
        }
    }

    private func colorScheme(for theme: String) -> ColorScheme? {
        switch theme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}

// MARK: - Pro Upgrade Sheet
private struct ProUpgradeSheet: View {
    let settings: RectoSettings
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var ctx

    var body: some View {
        NavigationStack {
            ZStack {
                RectoTheme.paperBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(RectoTheme.starColor.opacity(0.12))
                                .frame(width: 100, height: 100)
                            Image(systemName: "star.fill")
                                .font(.system(size: 44, weight: .light))
                                .foregroundStyle(RectoTheme.starColor)
                        }

                        VStack(spacing: 10) {
                            Text("Recto Pro")
                                .font(.system(size: 30, weight: .bold, design: .serif))
                                .foregroundStyle(RectoTheme.inkPrimary)

                            Text("Unlock the full journaling experience.")
                                .font(.system(size: 16))
                                .foregroundStyle(RectoTheme.inkSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }

                    Spacer().frame(height: 40)

                    VStack(spacing: 0) {
                        ProFeatureRow(icon: "sparkles", text: "Unlimited Collections")
                        Divider().padding(.horizontal, 20).overlay(RectoTheme.ruleLineColor.opacity(0.6))
                        ProFeatureRow(icon: "arrow.triangle.2.circlepath", text: "Weekly & Monthly Migration View")
                        Divider().padding(.horizontal, 20).overlay(RectoTheme.ruleLineColor.opacity(0.6))
                        ProFeatureRow(icon: "chart.bar", text: "Journal Statistics & Streaks")
                        Divider().padding(.horizontal, 20).overlay(RectoTheme.ruleLineColor.opacity(0.6))
                        ProFeatureRow(icon: "icloud", text: "iCloud Sync (coming soon)")
                    }
                    .background(Color.white.opacity(0.55))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 20)

                    Spacer()

                    VStack(spacing: 12) {
                        Button {
                            settings.isPro = true
                            try? ctx.save()
                            isPresented = false
                        } label: {
                            Text("Unlock Pro — $4.99")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(RectoTheme.inkPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        Text("One-time purchase · No subscription")
                            .font(.system(size: 12))
                            .foregroundStyle(RectoTheme.inkSecondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not Now") { isPresented = false }
                        .foregroundStyle(RectoTheme.inkSecondary)
                }
            }
        }
    }
}

private struct ProFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(RectoTheme.starColor)
                .frame(width: 28)

            Text(text)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(RectoTheme.inkPrimary)

            Spacer()

            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(RectoTheme.eventColor)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}
