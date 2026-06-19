import SwiftUI

struct MemoirSettingsView: View {
    @State private var wordGoal: Int = MemoirSettings.wordGoal
    @State private var defaultEra: LifeEra = MemoirSettings.defaultEra
    @State private var hapticFeedback: Bool = MemoirSettings.hapticFeedback
    @State private var autoSave: Bool = MemoirSettings.autoSave
    @State private var showOnboarding = false

    private let appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let buildNumber: String = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    var body: some View {
        NavigationStack {
            Form {
                // Writing preferences
                Section {
                    // Word goal stepper
                    HStack {
                        Label("Word Goal", systemImage: "target")
                            .foregroundColor(MemoirTheme.inkBrown)
                        Spacer()
                        HStack(spacing: 16) {
                            Button {
                                if wordGoal > 50 {
                                    wordGoal -= 50
                                    MemoirSettings.wordGoal = wordGoal
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(wordGoal <= 50 ? .secondary : MemoirTheme.warmAmber)
                                    .font(.title3)
                            }
                            .buttonStyle(.plain)
                            .disabled(wordGoal <= 50)

                            Text("\(wordGoal)")
                                .font(.system(.body, design: .rounded).weight(.semibold))
                                .foregroundColor(MemoirTheme.inkBrown)
                                .frame(minWidth: 40, alignment: .center)

                            Button {
                                if wordGoal < 1000 {
                                    wordGoal += 50
                                    MemoirSettings.wordGoal = wordGoal
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(wordGoal >= 1000 ? .secondary : MemoirTheme.warmAmber)
                                    .font(.title3)
                            }
                            .buttonStyle(.plain)
                            .disabled(wordGoal >= 1000)
                        }
                    }

                    // Default era
                    HStack {
                        Label("Default Era", systemImage: "clock.arrow.circlepath")
                            .foregroundColor(MemoirTheme.inkBrown)
                        Spacer()
                        Picker("", selection: $defaultEra) {
                            ForEach(LifeEra.allCases, id: \.self) { era in
                                Text(era.displayName).tag(era)
                            }
                        }
                        .pickerStyle(.menu)
                        .accentColor(MemoirTheme.warmAmber)
                        .onChange(of: defaultEra) { _, newValue in
                            MemoirSettings.defaultEra = newValue
                        }
                    }
                } header: {
                    Text("Writing")
                }

                // Behaviour
                Section {
                    Toggle(isOn: $hapticFeedback) {
                        Label("Haptic Feedback", systemImage: "iphone.radiowaves.left.and.right")
                            .foregroundColor(MemoirTheme.inkBrown)
                    }
                    .tint(MemoirTheme.warmAmber)
                    .onChange(of: hapticFeedback) { _, newValue in
                        MemoirSettings.hapticFeedback = newValue
                    }

                    Toggle(isOn: $autoSave) {
                        Label("Auto-Save Draft", systemImage: "clock.arrow.2.circlepath")
                            .foregroundColor(MemoirTheme.inkBrown)
                    }
                    .tint(MemoirTheme.warmAmber)
                    .onChange(of: autoSave) { _, newValue in
                        MemoirSettings.autoSave = newValue
                    }

                    if autoSave {
                        Text("Your writing is automatically saved every 30 seconds of inactivity.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Behaviour")
                }

                // Privacy
                Section {
                    HStack {
                        Label("Storage", systemImage: "lock.shield.fill")
                            .foregroundColor(MemoirTheme.inkBrown)
                        Spacer()
                        Text("On-device only")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Label("Cloud Sync", systemImage: "icloud.slash.fill")
                            .foregroundColor(MemoirTheme.inkBrown)
                        Spacer()
                        Text("Disabled")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Privacy")
                } footer: {
                    Text("Memoir stores your stories exclusively on this device. Nothing is shared or uploaded.")
                }

                // About
                Section {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                            .foregroundColor(MemoirTheme.inkBrown)
                        Spacer()
                        Text("\(appVersion) (\(buildNumber))")
                            .foregroundColor(.secondary)
                    }

                    Button {
                        showOnboarding = true
                    } label: {
                        Label("Replay Introduction", systemImage: "arrow.counterclockwise")
                            .foregroundColor(MemoirTheme.warmAmber)
                    }
                } header: {
                    Text("About Memoir")
                }
            }
            .scrollContentBackground(.hidden)
            .background(MemoirTheme.parchment.opacity(0.3).ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showOnboarding) {
                MemoirOnboardingView {
                    showOnboarding = false
                }
            }
            .onAppear {
                // Refresh values from UserDefaults in case they changed elsewhere
                wordGoal = MemoirSettings.wordGoal
                defaultEra = MemoirSettings.defaultEra
                hapticFeedback = MemoirSettings.hapticFeedback
                autoSave = MemoirSettings.autoSave
            }
        }
    }
}
