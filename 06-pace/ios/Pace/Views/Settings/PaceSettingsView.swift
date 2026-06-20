import SwiftUI

struct PaceSettingsView: View {
    @AppStorage("pace_use_km") private var useKm = true
    @AppStorage("pace_default_activity") private var defaultActivityRaw = "Run"
    @AppStorage("pace_weekly_goal_km") private var weeklyGoalKm = 20.0
    @AppStorage("pace_auto_pause") private var autoPause = false
    @AppStorage("pace_high_gps") private var highGPS = true
    @AppStorage("pace_pro_unlocked") private var proUnlocked = false
    @State private var showProSheet = false

    private var defaultActivity: ActivityType {
        ActivityType(rawValue: defaultActivityRaw) ?? .run
    }

    var body: some View {
        NavigationStack {
            List {
                // Units
                Section("Units & Measurements") {
                    Toggle(isOn: $useKm) {
                        Label("Use Kilometers", systemImage: "ruler")
                    }
                    .tint(PaceTheme.accent)
                }

                // Activity
                Section("Activity Preferences") {
                    Picker(selection: $defaultActivityRaw) {
                        ForEach(ActivityType.allCases, id: \.rawValue) { type in
                            Label(type.rawValue, systemImage: type.systemImage)
                                .tag(type.rawValue)
                        }
                    } label: {
                        Label("Default Activity", systemImage: "figure.run")
                    }
                }

                // Goals
                Section("Weekly Goal") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Distance Goal", systemImage: "target")
                            Spacer()
                            Text(useKm
                                 ? String(format: "%.0f km", weeklyGoalKm)
                                 : String(format: "%.0f mi", weeklyGoalKm * 0.621371))
                                .foregroundStyle(PaceTheme.accent)
                                .fontWeight(.semibold)
                        }
                        Slider(value: $weeklyGoalKm, in: 0...100, step: 5)
                            .tint(PaceTheme.accent)
                    }
                    .padding(.vertical, 4)
                }

                // GPS
                Section("Tracking") {
                    Toggle(isOn: $highGPS) {
                        Label("High GPS Accuracy", systemImage: "location.fill")
                    }
                    .tint(PaceTheme.accent)

                    Toggle(isOn: $autoPause) {
                        Label("Auto-Pause When Stopped", systemImage: "pause.circle")
                    }
                    .tint(PaceTheme.accent)
                }

                // Privacy
                Section("Privacy") {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundStyle(PaceTheme.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("All Data On Device Only")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("No account, no cloud sync, no data harvesting.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Pro
                Section("Pace Pro") {
                    if proUnlocked {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.yellow)
                            Text("Pro Unlocked")
                                .fontWeight(.medium)
                            Spacer()
                            Text("Thank you!")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    } else {
                        Button(action: { showProSheet = true }) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Unlock Pace Pro")
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                    Text("Advanced stats, GPX export, custom intervals")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("$3.99")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(PaceTheme.accent)
                            }
                        }
                    }
                }

                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    Link(destination: URL(string: "https://orbioom.com/pace/privacy")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showProSheet) {
                ProUpgradeSheet(isPresented: $showProSheet, proUnlocked: $proUnlocked)
            }
        }
    }
}

private struct ProUpgradeSheet: View {
    @Binding var isPresented: Bool
    @Binding var proUnlocked: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.yellow)

                    Text("Pace Pro")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("One-time purchase, no subscription")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 16) {
                    ProFeatureRow(icon: "chart.bar.fill", text: "Advanced statistics & analytics")
                    ProFeatureRow(icon: "square.and.arrow.up", text: "GPX route export")
                    ProFeatureRow(icon: "timer", text: "Custom interval training")
                    ProFeatureRow(icon: "target", text: "Training plans & goals")
                    ProFeatureRow(icon: "bell.fill", text: "Pace alerts during runs")
                }
                .padding(.horizontal, 32)

                Spacer()

                VStack(spacing: 12) {
                    Button(action: {
                        // In production: StoreKit purchase flow
                        proUnlocked = true
                        isPresented = false
                    }) {
                        Text("Unlock for $3.99")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(PaceTheme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 24)

                    Button(action: { isPresented = false }) {
                        Text("Restore Purchase")
                            .font(.subheadline)
                            .foregroundStyle(PaceTheme.accent)
                    }
                }
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { isPresented = false }
                }
            }
        }
    }
}

private struct ProFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(PaceTheme.accent)
                .frame(width: 28)
            Text(text)
                .font(.callout)
        }
    }
}
